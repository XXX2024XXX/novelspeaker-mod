//
//  ExistingChapterRedownloader.swift
//  NovelSpeaker
//

import Foundation
import RealmSwift

// 既にダウンロードされて保存されている章を、現在の取込設定
// (RealmNovelImportSetting や RealmGlobalState.isSkipForewordAfterwordOnNewImport など)
// を反映させた状態でネット経由で再取得し直し、保存済みの内容を上書きします。
//
// 従来、既にダウンロード済みの章を再取得する仕組みが存在しなかった(ReleaseMemo.md 参照)ため新設しました。
// 注意点:
// ・ネットワーク経由で元のページに再度アクセスするため、ページが既に存在しない/構造が変わっている場合は
//   その章の取得に失敗したり、意図しない内容になる可能性があります。
// ・保存済みの内容を直接上書きするため、元に戻すことはできません。
class ExistingChapterRedownloader {
    struct Result {
        let successCount: Int
        let failedCount: Int
        let totalCount: Int
    }

    // 相手サイトへ連続アクセスし過ぎないようにするための、章毎の待ち時間。
    static var delayTimeInSecBetweenChapters: TimeInterval = 1.2

    // novelID の保存済み全章を、chapterNumber の若い順に1章ずつ再取得して上書きします。
    // progress は (処理し終えた数, 全体数) を都度返します。(メインスレッドで呼ばれるとは限りません)
    // completion は最終結果を返します。(メインスレッドで呼ばれるとは限りません)
    static func redownloadAllChapters(novelID: String, progress: @escaping (_ done: Int, _ total: Int) -> Void, completion: @escaping (Result) -> Void) {
        let chapterNumbers: [Int] = RealmUtil.RealmBlock { realm -> [Int] in
            guard let novel = RealmNovel.SearchNovelWith(realm: realm, novelID: novelID), let lastChapterNumber = novel.lastChapterNumber, lastChapterNumber >= 1 else { return [] }
            return Array(1...lastChapterNumber)
        }
        redownloadChapters(novelID: novelID, chapterNumbers: chapterNumbers, progress: progress, completion: completion)
    }

    // 指定した chapterNumber の一覧だけを再取得したい場合に使います。
    static func redownloadChapters(novelID: String, chapterNumbers: [Int], progress: @escaping (_ done: Int, _ total: Int) -> Void, completion: @escaping (Result) -> Void) {
        let total = chapterNumbers.count
        guard total > 0 else {
            completion(Result(successCount: 0, failedCount: 0, totalCount: 0))
            return
        }
        let fetcher = StoryFetcher()
        // 取込設定(RealmNovelImportSetting)の novel スコープ解決に使われます。
        fetcher.novelIDForImportSetting = novelID
        var successCount = 0
        var failedCount = 0

        func processIndex(_ index: Int) {
            if index >= chapterNumbers.count {
                completion(Result(successCount: successCount, failedCount: failedCount, totalCount: total))
                return
            }
            func advanceToNext() {
                progress(index + 1, total)
                DispatchQueue.main.asyncAfter(deadline: .now() + delayTimeInSecBetweenChapters) {
                    processIndex(index + 1)
                }
            }
            let chapterNumber = chapterNumbers[index]
            let existingStory = RealmUtil.RealmBlock { realm -> Story? in
                RealmStoryBulk.SearchStoryWith(realm: realm, novelID: novelID, chapterNumber: chapterNumber)
            }
            guard let existingStory = existingStory, let url = URL(string: existingStory.url) else {
                failedCount += 1
                advanceToNext()
                return
            }
            fetcher.InspectFetchSinglePage(url: url, cookieString: "", successAction: { state in
                guard let content = state.content, content.count > 0 else {
                    failedCount += 1
                    advanceToNext()
                    return
                }
                var updatedStory = existingStory
                updatedStory.content = content.replacingOccurrences(of: "\u{00}", with: "")
                if let subtitle = state.subtitle, subtitle.count > 0 {
                    updatedStory.subtitle = subtitle
                }
                RealmUtil.Write { realm in
                    RealmStoryBulk.SetStoryWith(realm: realm, story: updatedStory)
                }
                successCount += 1
                advanceToNext()
            }, failedAction: { _, _ in
                failedCount += 1
                advanceToNext()
            })
        }
        processIndex(0)
    }
}
