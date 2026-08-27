//
//  FavoriteStoryListViewController.swift
//  NovelSpeaker
//
//  「お気に入りの話」だけを、小説をまたいで一箇所に集めた一覧画面。
//  本文の読み上げ画面(SpeechViewController/WebSpeechViewController)の
//  右上ボタン(星アイコン、toggleFavoriteStoryButtonClicked)で登録した話がここに並ぶ。
//
//  Created by 飯村卓司 on 2026/08/27.
//  Copyright © 2026 IIMURA Takuji. All rights reserved.
//

import UIKit
import RealmSwift

class FavoriteStoryListViewController: UITableViewController {
    static let cellID = "FavoriteStoryListViewControllerCell"

    private struct Item {
        let storyID: String
        let novelTitle: String
        let subtitle: String
    }
    private var items: [Item] = []
    private var observerToken: NotificationToken? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("FavoriteStoryListViewController_Title", comment: "お気に入りの話")
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 60
        reloadItems()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addNotificationReceiver()
        reloadItems()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        observerToken = nil
    }

    func addNotificationReceiver() {
        RealmUtil.RealmBlock { (realm) -> Void in
            self.observerToken = RealmBookmark.GetAllFavoriteStories(realm: realm)?.observe { [weak self] _ in
                DispatchQueue.main.async {
                    self?.reloadItems()
                }
            }
        }
    }

    func reloadItems() {
        RealmUtil.RealmBlock { (realm) -> Void in
            var result: [Item] = []
            if let favorites = RealmBookmark.GetAllFavoriteStories(realm: realm) {
                for bookmark in favorites {
                    // idの文字列をパースするのではなく、保存済みのnovelID/chapterNumberから
                    // storyIDを組み立て直す(RealmBookmarkの通常の使い方に沿う)。
                    let storyID = RealmStoryBulk.CreateUniqueID(novelID: bookmark.novelID, chapterNumber: bookmark.chapterNumber)
                    let novelTitle = RealmNovel.SearchNovelWith(realm: realm, novelID: bookmark.novelID)?.title ?? bookmark.novelID
                    let subtitle = RealmStoryBulk.SearchStoryWith(realm: realm, storyID: storyID)?.subtitle ?? "-"
                    result.append(Item(storyID: storyID, novelTitle: novelTitle, subtitle: subtitle))
                }
            }
            DispatchQueue.main.async {
                self.items = result
                self.tableView.reloadData()
                self.updateEmptyBackgroundIfNeeded()
            }
        }
    }

    func updateEmptyBackgroundIfNeeded() {
        if items.isEmpty {
            let label = UILabel()
            label.text = NSLocalizedString("FavoriteStoryListViewController_EmptyMessage", comment: "お気に入りの話がまだありません。\n本文の読み上げ画面にある星ボタンで登録できます。")
            label.numberOfLines = 0
            label.textAlignment = .center
            label.textColor = .secondaryLabel
            label.font = .preferredFont(forTextStyle: .body)
            let container = UIView()
            container.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
                label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])
            self.tableView.backgroundView = container
        }else{
            self.tableView.backgroundView = nil
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FavoriteStoryListViewController.cellID) ?? UITableViewCell(style: .subtitle, reuseIdentifier: FavoriteStoryListViewController.cellID)
        guard indexPath.row < items.count else { return cell }
        let item = items[indexPath.row]
        cell.textLabel?.text = item.subtitle
        cell.textLabel?.numberOfLines = 2
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.detailTextLabel?.text = item.novelTitle
        cell.detailTextLabel?.numberOfLines = 1
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        cell.detailTextLabel?.font = .preferredFont(forTextStyle: .caption1)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return NSLocalizedString("FavoriteStoryListViewController_RemoveFavorite", comment: "お気に入りから外す")
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete, indexPath.row < items.count else { return }
        let storyID = items[indexPath.row].storyID
        RealmUtil.Write { (realm) in
            RealmBookmark.SetFavoriteStory(realm: realm, storyID: storyID, isFavorite: false)
        }
        items.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
        updateEmptyBackgroundIfNeeded()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < items.count else { return }
        let storyID = items[indexPath.row].storyID
        RealmUtil.RealmBlock { (realm) -> Void in
            let viewType = RealmGlobalState.GetInstanceWith(realm: realm)?.defaultDisplaySettingWith(realm: realm)?.viewType ?? RealmDisplaySetting.ViewType.normal
            DispatchQueue.main.async {
                let storyboard = self.storyboard ?? UIStoryboard(name: "Main", bundle: nil)
                switch viewType {
                case .normal:
                    guard let nextViewController = storyboard.instantiateViewController(withIdentifier: "SpeechViewController") as? SpeechViewController else { return }
                    nextViewController.storyID = storyID
                    self.navigationController?.pushViewController(nextViewController, animated: true)
                case .webViewVertical, .webViewHorizontal, .webViewOriginal, .webViewVertical2Column:
                    guard let nextViewController = storyboard.instantiateViewController(withIdentifier: "WebSpeechViewController") as? WebSpeechViewController else { return }
                    nextViewController.targetStoryID = storyID
                    self.navigationController?.pushViewController(nextViewController, animated: true)
                }
            }
        }
    }
}
