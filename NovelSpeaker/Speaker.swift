//
//  SpeakerSwift.swift
//  NovelSpeaker
//
//  Created by 飯村卓司 on 2020/01/10.
//  Copyright © 2020 IIMURA Takuji. All rights reserved.
//

import Foundation
import AVFoundation

protocol SpeakRangeDelegate {
    func willSpeakRange(range:NSRange)
    func finishSpeak(isCancel:Bool, speechString:String)
}

// Speaker が「発話直前にオーディオセッションを整える」ために使う最小の抽象。
// 具体的なセッション管理(アクティブ化や deactivate のライフサイクル)は上位レイヤが実装し、
// Speaker 自身は上位の具象クラス(StorySpeaker 等)に依存しないようにするためのもの。
// 未登録(coordinator=nil)なら Speaker は何もしないので、単体・他プラットフォームでもそのまま動く。
protocol SpeakerAudioSessionCoordinator: AnyObject {
    // speak 直前に呼ばれる。セッションが落ちていたら同期的に立て直す等の準備を行う。
    func prepareAudioSessionForSpeechSynchronously()
    // オーディオセッションを deactivate する度に増える世代番号。
    // synth がこの世代をまたいでいたら内部オーディオエンジンが切れて固着しうるので、作り直す判定に使う。
    var audioSessionGeneration: Int { get }
}

#if false // AVSpeechSynthesizer を開放するとメモリ解放できそうなので必要なくなりました
class Speaker {
    var speaker_Original:Speaker_Original? = nil
    var speaker_WithoutWillSpeakRange:Speaker_WithoutWillSpeakRange? = nil
    
    init() {
        AssignSpeaker()
    }
    
    func AssignSpeaker() {
        if NovelSpeakerUtility.GetIsDisableWillSpeakRange() {
            if speaker_Original == nil && speaker_WithoutWillSpeakRange != nil {
                return
            }
            speaker_Original = nil
            speaker_WithoutWillSpeakRange = Speaker_WithoutWillSpeakRange()
        }else{
            if speaker_Original != nil && speaker_WithoutWillSpeakRange == nil {
                return
            }
            speaker_Original = Speaker_Original()
            speaker_WithoutWillSpeakRange = nil
        }
    }
    
    func Speech(text:String) {
        speaker_Original?.Speech(text: text)
        speaker_WithoutWillSpeakRange?.Speech(text: text)
    }
    
    func Stop() {
        speaker_Original?.Stop()
        speaker_WithoutWillSpeakRange?.Stop()
    }
    
    func Pause() {
        speaker_Original?.Pause()
        speaker_WithoutWillSpeakRange?.Pause()
    }
    
    func Resume() {
        speaker_Original?.Resume()
        speaker_WithoutWillSpeakRange?.Resume()
    }
    
    var voice:AVSpeechSynthesisVoice {
        get {
            if let speaker = speaker_Original {
                return speaker.voice
            }
            if let speaker = speaker_WithoutWillSpeakRange {
                return speaker.voice
            }
            return AVSpeechSynthesisVoice()
        }
        set(value) {
            speaker_Original?.voice = value
            speaker_WithoutWillSpeakRange?.voice = value
        }
    }
    func SetVoiceWith(identifier:String, language:String) {
        speaker_Original?.SetVoiceWith(identifier: identifier, language: language)
        speaker_WithoutWillSpeakRange?.SetVoiceWith(identifier: identifier, language: language)
    }
    func SetVoiceWith(language:String) {
        speaker_Original?.SetVoiceWith(language: language)
        speaker_WithoutWillSpeakRange?.SetVoiceWith(language: language)
    }
    var pitch:Float {
        get {
            if let speaker = speaker_Original {
                return speaker.pitch
            }
            if let speaker = speaker_WithoutWillSpeakRange {
                return speaker.pitch
            }
            return 1.0
        }
        set(value) {
            speaker_Original?.pitch = value
            speaker_WithoutWillSpeakRange?.pitch = value
        }
    }
    var rate:Float {
        get {
            if let speaker = speaker_Original {
                return speaker.rate
            }
            if let speaker = speaker_WithoutWillSpeakRange {
                return speaker.rate
            }
            return 1.0
        }
        set(value) {
            speaker_Original?.rate = value
            speaker_WithoutWillSpeakRange?.rate = value
        }
    }
    var volume:Float {
        get {
            if let speaker = speaker_Original {
                return speaker.volume
            }
            if let speaker = speaker_WithoutWillSpeakRange {
                return speaker.volume
            }
            return 1.0
        }
        set(value) {
            speaker_Original?.volume = value
            speaker_WithoutWillSpeakRange?.volume = value
        }
    }
    var delay:TimeInterval {
        get {
            if let speaker = speaker_Original {
                return speaker.delay
            }
            if let speaker = speaker_WithoutWillSpeakRange {
                return speaker.delay
            }
            return 1.0
        }
        set(value) {
            speaker_Original?.delay = value
            speaker_WithoutWillSpeakRange?.delay = value
        }
    }
    var delegate:SpeakRangeDelegate? {
        get {
            if let speaker = speaker_Original {
                return speaker.delegate
            }
            if let speaker = speaker_WithoutWillSpeakRange {
                return speaker.delegate
            }
            return nil
        }
        set(value) {
            speaker_Original?.delegate = value
            speaker_WithoutWillSpeakRange?.delegate = value
        }
    }

    func isSpeaking() -> Bool {
        if let speaker = speaker_Original {
            return speaker.isSpeaking()
        }
        if let speaker = speaker_WithoutWillSpeakRange {
            return speaker.isSpeaking()
        }
        return false
    }
    
    func reloadSynthesizer() {
        speaker_Original?.reloadSynthesizer()
        speaker_WithoutWillSpeakRange?.reloadSynthesizer()
    }
    
    func ChangeSpeakerWillSpeakRangeType() {
        let prevSpeakerOriginal = speaker_Original
        let prevSpeakerWithoutWillSpeakRange = speaker_WithoutWillSpeakRange
        AssignSpeaker()
        if let speaker = speaker_Original, let prev = prevSpeakerWithoutWillSpeakRange {
            speaker.delegate = prev.delegate
            speaker.voice = prev.voice
            speaker.delay = prev.delay
            speaker.volume = prev.volume
            speaker.rate = prev.rate
            speaker.pitch = prev.pitch
        }
        if let speaker = speaker_WithoutWillSpeakRange, let prev = prevSpeakerOriginal {
            speaker.delegate = prev.delegate
            speaker.voice = prev.voice
            speaker.delay = prev.delay
            speaker.volume = prev.volume
            speaker.rate = prev.rate
            speaker.pitch = prev.pitch
        }
    }
    
    func isPaused() -> Bool {
        if let speaker = speaker_Original {
            return speaker.isPaused()
        }
        if let speaker = speaker_WithoutWillSpeakRange {
            return speaker.isPaused()
        }
        return false
    }

    var isSpeechKicked:Bool {
        get {
            if let speaker = speaker_Original {
                return speaker.isSpeechKicked
            }
            if let speaker = speaker_WithoutWillSpeakRange {
                return speaker.isSpeechKicked
            }
            return false
        }
    }
}
class Speaker_Original: NSObject, AVSpeechSynthesizerDelegate {
}
#endif // AVSpeechSynthesizer を開放するとメモリ解放できそうなので必要なくなりました

class Speaker: NSObject, AVSpeechSynthesizerDelegate {
    var synthesizer = AVSpeechSynthesizer()
    var m_Voice:AVSpeechSynthesisVoice = AVSpeechSynthesisVoice(language: "ja-JP") ?? AVSpeechSynthesisVoice()
    var m_Pitch:Float = 1.0
    var m_Rate:Float = AVSpeechUtteranceDefaultSpeechRate
    var m_Volume:Float = 1.0
    var m_Delay:TimeInterval = 0.0
    var m_Delegate:SpeakRangeDelegate? = nil
    var isSpeechKicked:Bool = false
    // 発話直前にオーディオセッションを整えるための上位レイヤ(任意)。
    // 未登録(nil)なら何もしないので、Speaker 自体は上位の具象クラスに依存せず単体で動く。
    static weak var audioSessionCoordinator: SpeakerAudioSessionCoordinator?
    // この synth が作られた時点のオーディオセッション世代。coordinator の世代と食い違っていれば、
    // この synth は deactivate をまたいで生き残っており内部エンジンが切れて固着しうるので作り直す。
    private var bornAudioSessionGeneration:Int = Speaker.audioSessionCoordinator?.audioSessionGeneration ?? 0

    // AVSpeechUtterance.rate はAppleのAPI仕様上 AVSpeechUtteranceMaximumSpeechRate(1.0)が絶対的な上限であり、
    // OSの音声合成エンジン自身にそれ以上の速さで喋らせる事は出来ない。1.0を超える分については、
    // 音声合成自体は等倍(1.0)のまま行い、出てきた音声波形を AVAudioUnitTimePitch で再生時に追加で
    // 高速化する事で実現する(TimePitchはピッチを維持したまま速度だけ変えられるので声が高くならない)。
    static let maximumTotalSpeechRate: Float = 2.0
    private var extraSpeedEngine: AVAudioEngine? = nil
    private var extraSpeedPlayerNode: AVAudioPlayerNode? = nil
    private var extraSpeedPendingBufferCount: Int = 0
    private var isExtraSpeedSynthesisFinished: Bool = false
    private var isExtraSpeedStopRequested: Bool = false
    private var extraSpeedSpeechString: String = ""
    // m_Rate(0.0〜maximumTotalSpeechRate)のうち、AVSpeechUtteranceMaximumSpeechRateを超える分の倍率。
    // 1.0以下ならAVAudioEngineを介さない従来経路を使うので、既存の挙動には一切影響しない。
    private var extraSpeedMultiplier: Float {
        if m_Rate <= AVSpeechUtteranceMaximumSpeechRate { return 1.0 }
        return m_Rate / AVSpeechUtteranceMaximumSpeechRate
    }

    override init() {
        super.init()
        synthesizer.delegate = self
        SetNotificationHandler()
    }

    deinit {
        RemoveNotificationHandler()
        synthesizer.delegate = nil
    }

    func Speech(text:String) {
        if NiftyUtility.isTesting() {
            return
        }
        isSpeechKicked = true
        // アプリ全体の不変条件:「オーディオセッションが deactivate された状態/それをまたいだ synth への
        // speak」が固着(synth wedge)の根本原因。全 speak はこの Speech() を通るので、ここで是正する。
        // 具体的なセッション操作は上位レイヤ(coordinator)に委譲し、Speaker は上位の具象クラスに依存しない。
        // coordinator 未登録なら何もしない(従来どおりの素の挙動・他プラットフォームでもそのまま動く)。
        if let coordinator = Speaker.audioSessionCoordinator {
            // (1) セッションが落ちていたら同期的に立て直す。
            coordinator.prepareAudioSessionForSpeechSynchronously()
            // (2) deactivate をまたいで生き残った synth は作り直す(世代が変わらない通常時は何もしない)。
            if bornAudioSessionGeneration != coordinator.audioSessionGeneration {
                synthesizer = AVSpeechSynthesizer()
                synthesizer.delegate = self
                bornAudioSessionGeneration = coordinator.audioSessionGeneration
            }
        }
        let extraSpeed = self.extraSpeedMultiplier
        // NSLogは実機のidevicesyslog経由では最新iOSのプライバシー保護によりアプリ自身のログが
        // 一切表示されない事が判明したため、アプリ内蔵の「アプリ内エラーのお知らせ」機構
        // (AppInformationLogger、設定画面からJSONで取り出せる)経由でログを残す事にした。
        // rateが実際にいくつとして評価されているか(1.0超の経路に入るかどうか)を必ず記録する。
        // [根本原因] SetVoiceSettings() 等が声変更直後に発話エンジンを温めるため空白1文字(" ")だけの
        // "ウォームアップ発話"を送ってくる事がある。この空白だけのutteranceをwrite(_:toBufferCallback:)
        // に渡すと、実機で検証した結果コールバックが一切呼ばれずに永久に無音のまま固まる
        // (「synthesis finished」のログすら出ない)事が判明した。これがrateを1.0超にすると
        // 一度も音が出なくなっていた真の原因だった。空白/空文字はそもそも高速化しても意味が無いので、
        // 1.0超の経路を通さず、常に従来の直接speak()の経路で処理するようにする。
        let isBlankOnlyText = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        SpeakerDebugLog(message: "Speech() called. m_Rate=\(m_Rate) extraSpeedMultiplier=\(extraSpeed) willUseExtraSpeedPath=\(extraSpeed > 1.0 && !isBlankOnlyText) textLength=\((text as NSString).length)")
        if extraSpeed <= 1.0 || isBlankOnlyText {
            // 従来通りの経路。rateを1.0超から1.0以下に戻した直後は、前回使っていた加速再生用の
            // AVAudioEngineがまだ残っている(=extraSpeedEngine != nil)ことがあり、これが残ったままだと
            // (1) 古いエンジンが鳴り続けて通常再生の音と衝突する、(2) didFinish等のデリゲートが
            // 「加速再生中だから」という理由で無視され続けて通常再生が正しく完了扱いにならない、
            // という2つの不具合を引き起こす。1.0以下の経路に入る際は必ず先に片付けておく。
            StopExtraSpeedEngine()
            let utt = AVSpeechUtterance(string: text)
            utt.voice = m_Voice
            utt.pitchMultiplier = m_Pitch
            // m_Rateが1.0超の場合(空白ウォームアップ発話でこの経路に来た場合)、AVSpeechUtterance.rateの
            // 許容範囲を超えないようクランプする。空白なのでどのみち聞こえないため速度は問題にならない。
            utt.rate = min(m_Rate, AVSpeechUtteranceMaximumSpeechRate)
            utt.postUtteranceDelay = m_Delay
            utt.volume = max(0.0, min(1.0, m_Volume))
            synthesizer.speak(utt)
            return
        }
        SpeechWithExtraSpeed(text: text, extraSpeed: extraSpeed)
    }

    // rateが1.0(AVSpeechUtteranceMaximumSpeechRate)を超えている場合の再生経路。
    // 合成自体は等倍(1.0)で行い、write(_:toBufferCallback:)で音声波形をバッファとして受け取る。
    //
    // 実機検証の結果、届いたバッファを AVAudioPCMBuffer.floatChannelData 経由で生のポインタ操作
    // していた過去の実装(バッファを1本ずつ再生 / 1本に結合)は、実機のログに
    // 「AVAudioBuffer.mm: mBuffers[0].mDataByteSize (0) should be non-zero」という警告が
    // 発話の度に必ず出ており、中身が空のバッファを再生しようとして無音になっていた事が判明した。
    // write()が渡してくるPCMバッファの内部形式(Float32とは限らない)を決め打ちしていたのが原因と
    // 考えられる。生のポインタ操作をやめ、フォーマットの違いを自動で吸収してくれる標準APIである
    // AVAudioFile への書き込み/読み込みを経由する事で、中身の欠落を避ける。
    //
    // 具体的には、届いたバッファを逐次一時ファイルへ書き込んでいき(AVAudioFile.write(from:)は
    // 入力フォーマットの違いを自身で処理してくれる)、合成完了(空バッファ)の合図を受け取ったら、
    // 出来上がったファイルを AVAudioPlayerNode.scheduleFile() で読み込んで
    // (AVAudioPlayerNode -> AVAudioUnitTimePitch -> mainMixerNode) 再生する。
    //
    // 注意点: write() 経由だと willSpeakRange 等の細かい単語単位の通知タイミングは実際の(加速後の)
    // 再生タイミングとズレる(合成は先に等倍速度でどんどん進んでしまうため)。単語単位のハイライト追従は
    // 諦め、再生を開始した瞬間に発話文字列全体を1回だけ通知するだけに留める。
    private func SpeechWithExtraSpeed(text: String, extraSpeed: Float) {
        StopExtraSpeedEngine() // 直前の発話がまだ残っていれば先に片付ける
        extraSpeedSpeechString = text
        isExtraSpeedSynthesisFinished = false
        isExtraSpeedStopRequested = false
        extraSpeedPendingBufferCount = 0

        let engine = AVAudioEngine()
        let playerNode = AVAudioPlayerNode()
        // 1個のAVAudioUnitTimePitchに大きな倍率(2倍・5倍等)を一度に負わせると、
        // 「何を言っているか分からない」レベルまでアルゴリズムの粒子(グレイン)が
        // 崩壊し、聞き取れなくなる事が実機テストで判明した。1段あたりの変化量を
        // 抑えるため、倍率の平方根ずつ2段に分けて直列に処理する
        // (例: 5倍なら約2.236倍を2回)。各段の負担が減る分、音質が改善する。
        let timePitchStageRate = sqrt(extraSpeed)
        let timePitchStage1 = AVAudioUnitTimePitch()
        let timePitchStage2 = AVAudioUnitTimePitch()
        timePitchStage1.rate = timePitchStageRate
        timePitchStage2.rate = timePitchStageRate
        timePitchStage1.overlap = 32.0
        timePitchStage2.overlap = 32.0
        engine.attach(playerNode)
        engine.attach(timePitchStage1)
        engine.attach(timePitchStage2)
        extraSpeedEngine = engine
        extraSpeedPlayerNode = playerNode

        let utt = AVSpeechUtterance(string: text)
        utt.voice = m_Voice
        utt.pitchMultiplier = m_Pitch
        utt.rate = AVSpeechUtteranceMaximumSpeechRate
        utt.postUtteranceDelay = m_Delay
        utt.volume = max(0.0, min(1.0, m_Volume))

        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("novelspeaker_extraspeed_\(UUID().uuidString).caf")
        var audioFile: AVAudioFile? = nil
        var writeError: Error? = nil
        var receivedBufferCount = 0
        var totalFrameLength: Int64 = 0
        var hasHandledCompletion = false // write()の空バッファ完了通知が同一セッションで複数回来た場合に二重再生を防ぐ

        SpeakerDebugLog(message: "SpeechWithExtraSpeed start. extraSpeed=\(extraSpeed) textLength=\((text as NSString).length)")

        synthesizer.write(utt) { [weak self] buffer in
            guard let self = self, let pcmBuffer = buffer as? AVAudioPCMBuffer else { return }
            if pcmBuffer.frameLength == 0 {
                // 空バッファは合成完了の合図。ここで初めてファイルを閉じて再生を開始する。
                DispatchQueue.main.async {
                    guard self.extraSpeedEngine === engine, !self.isExtraSpeedStopRequested else { return }
                    guard !hasHandledCompletion else {
                        self.SpeakerDebugLog(message: "duplicate empty-buffer completion signal ignored")
                        return
                    }
                    hasHandledCompletion = true
                    self.isExtraSpeedSynthesisFinished = true
                    self.SpeakerDebugLog(message: "synthesis finished. buffers=\(receivedBufferCount) totalFrames=\(totalFrameLength) writeError=\(String(describing: writeError))")
                    audioFile = nil // ファイルをclose(参照を切る事でAVAudioFileが書き込みを確定させる)
                    guard writeError == nil, totalFrameLength > 0 else {
                        try? FileManager.default.removeItem(at: tmpURL)
                        self.FinishExtraSpeedSpeechIfNeeded()
                        return
                    }
                    do {
                        let playbackFile = try AVAudioFile(forReading: tmpURL)
                        self.SpeakerDebugLog(message: "playback file opened. length=\(playbackFile.length) format=\(playbackFile.processingFormat)")
                        // 実機ログ上はengine.isRunning/playerNode.isPlaying/scheduleFileの完了通知まで
                        // 全て正常に完走しているのに、実際には全く音が聞こえないという報告があった。
                        // これは短い音声clipで、ハードウェア出力(スピーカー)が実際に鳴り始める前に
                        // completionCallbackType: .dataPlayedBackが(レンダリングスレッド上の消費完了を
                        // もって)発火し、その直後にengine.stop()で強制停止してしまい、出力バッファに
                        // 残っていた分の音声(ハードウェア側の出力遅延分)が捨てられてしまうという、
                        // AVAudioEngineでよく知られる問題だと考えられる。
                        // また、この自前のAVAudioEngineが暗黙に使うAVAudioSessionが、通常の
                        // synthesizer.speak()経路が使っているものと本当に同じ状態(category=.playback、
                        // マナースイッチを無視して鳴らせる状態)になっているかを保証するため、
                        // ここでも明示的に設定/アクティブ化しておく。
                        do {
                            try AVAudioSession.sharedInstance().setCategory(.playback, options: [])
                            try AVAudioSession.sharedInstance().setActive(true, options: [])
                        } catch {
                            self.SpeakerDebugLog(message: "explicit AVAudioSession activation failed: \(error)")
                        }
                        engine.connect(playerNode, to: timePitchStage1, format: playbackFile.processingFormat)
                        engine.connect(timePitchStage1, to: timePitchStage2, format: playbackFile.processingFormat)
                        engine.connect(timePitchStage2, to: engine.mainMixerNode, format: playbackFile.processingFormat)
                        engine.mainMixerNode.outputVolume = 1.0
                        try engine.start()
                        self.SpeakerDebugLog(message: "engine started. engine.isRunning=\(engine.isRunning) outputVolume=\(engine.mainMixerNode.outputVolume)")
                        self.extraSpeedPendingBufferCount = 1
                        self.m_Delegate?.willSpeakRange(range: NSRange(location: 0, length: (text as NSString).length))
                        playerNode.scheduleFile(playbackFile, at: nil, completionCallbackType: .dataPlayedBack) { _ in
                            DispatchQueue.main.async {
                                self.SpeakerDebugLog(message: "scheduleFile completion fired")
                                // 以前はここで0.3秒待ってからengineを止めていたが、これは塊(発話単位)
                                // ごとに固定の無音区間を生む原因になっていた。.dataPlayedBackは本来
                                // ハードウェア出力が完了してから発火するはずのcompletionCallbackTypeであり、
                                // 追加の待ち時間無しでも(二重再生バグ修正後の実機テストで)音切れは
                                // 発生しなかったため、待ち時間を廃止して即座に次の発話へ進めるようにする。
                                try? FileManager.default.removeItem(at: tmpURL)
                                guard self.extraSpeedEngine === engine else { return }
                                self.extraSpeedPendingBufferCount -= 1
                                self.FinishExtraSpeedSpeechIfNeeded()
                            }
                        }
                        playerNode.play()
                        self.SpeakerDebugLog(message: "playerNode.play() called. isPlaying=\(playerNode.isPlaying)")
                    } catch {
                        self.SpeakerDebugLog(message: "extra speed file playback setup failed: \(error)")
                        try? FileManager.default.removeItem(at: tmpURL)
                        self.FinishExtraSpeedSpeechIfNeeded()
                    }
                }
                return
            }
            receivedBufferCount += 1
            totalFrameLength += Int64(pcmBuffer.frameLength)
            do {
                if audioFile == nil {
                    audioFile = try AVAudioFile(forWriting: tmpURL, settings: pcmBuffer.format.settings)
                }
                try audioFile?.write(from: pcmBuffer)
            } catch {
                writeError = error
                self.SpeakerDebugLog(message: "extra speed audio file write failed: \(error)")
            }
        }
    }

    // NSLogがidevicesyslog等の外部ログ経由では見えない実機環境があったため、代わりに
    // アプリ内蔵の「アプリ内エラーのお知らせ」(AppInformationLogger)に記録する。
    // isForDebug: trueなので通常のお知らせ一覧には出ず、設定画面の
    // 「アプリ内エラーのお知らせをJSONで取り出す」からのみ確認できる。
    private func SpeakerDebugLog(message: String) {
        AppInformationLogger.AddLog(message: "Speaker: " + message, isForDebug: true)
    }

    private func FinishExtraSpeedSpeechIfNeeded() {
        guard isExtraSpeedSynthesisFinished, extraSpeedPendingBufferCount <= 0, !isExtraSpeedStopRequested, extraSpeedEngine != nil else { return }
        SpeakerDebugLog(message: "finishSpeak fired for extra speed speech")
        let speechString = extraSpeedSpeechString
        StopExtraSpeedEngine()
        m_Delegate?.finishSpeak(isCancel: false, speechString: speechString)
    }

    private func StopExtraSpeedEngine() {
        extraSpeedPlayerNode?.stop()
        extraSpeedEngine?.stop()
        extraSpeedPlayerNode = nil
        extraSpeedEngine = nil
    }

    func Stop() {
        if extraSpeedEngine != nil {
            isExtraSpeedStopRequested = true
            synthesizer.stopSpeaking(at: .immediate)
            StopExtraSpeedEngine()
            return
        }
        synthesizer.stopSpeaking(at: .immediate)
    }

    func Pause() {
        if let playerNode = extraSpeedPlayerNode {
            playerNode.pause()
            return
        }
        synthesizer.pauseSpeaking(at: .immediate)
    }

    func Resume() {
        if let playerNode = extraSpeedPlayerNode {
            playerNode.play()
            return
        }
        synthesizer.continueSpeaking()
    }

    var voice:AVSpeechSynthesisVoice {
        get { return m_Voice }
        set(value) { m_Voice = value }
    }
    func SetVoiceWith(identifier:String, language:String) {
        if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            m_Voice = voice
            return
        }
        if let voice = AVSpeechSynthesisVoice(language: language) {
            m_Voice = voice
            return
        }
    }
    func SetVoiceWith(language:String) {
        if let voice = AVSpeechSynthesisVoice(language: language) {
            m_Voice = voice
        }
    }
    var pitch:Float {
        get { return m_Pitch }
        set(value) { m_Pitch = value }
    }
    var rate:Float {
        get { return m_Rate }
        set(value) {
            if value > Speaker.maximumTotalSpeechRate {
                m_Rate = Speaker.maximumTotalSpeechRate
                return
            }
            if value < AVSpeechUtteranceMinimumSpeechRate {
                m_Rate = AVSpeechUtteranceMinimumSpeechRate
                return
            }
            m_Rate = value
        }
    }
    var volume:Float {
        get { return m_Volume }
        set(value) {
            m_Volume = max(0.0, min(1.0, value))
        }
    }
    var delay:TimeInterval {
        get { return m_Delay }
        set(value) { m_Delay = value }
    }
    var delegate:SpeakRangeDelegate? {
        get { return m_Delegate }
        set(value) { m_Delegate = value }
    }
    
    func SetNotificationHandler() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(sessionDidInterrupt(notification:)), name: AVAudioSession.interruptionNotification, object: nil)
    }
    func RemoveNotificationHandler() {
        let center = NotificationCenter.default
        center.removeObserver(self)
    }
    
    @objc func sessionDidInterrupt(notification:Notification) {
        guard let interruptType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber, let type = AVAudioSession.InterruptionType(rawValue: interruptType.uintValue) else { return }
        switch type {
        case AVAudioSession.InterruptionType.began:
            Pause()
        case AVAudioSession.InterruptionType.ended:
            Resume()
        default:
            break
        }
    }
    
    @objc func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // 加速再生中(write()経由)は FinishExtraSpeedSpeechIfNeeded() 側から手動で finishSpeak を呼ぶので、
        // OS側のこのコールバックが発生したとしても二重に呼んでしまわないようここで無視する。
        guard extraSpeedEngine == nil else { return }
        delegate?.finishSpeak(isCancel: false, speechString: utterance.speechString)
    }
    @objc func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        guard extraSpeedEngine == nil else { return }
        delegate?.finishSpeak(isCancel: true, speechString: utterance.speechString)
    }

    #if !os(watchOS)
    @objc func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        // 加速再生中は SpeechWithExtraSpeed() 側で文章全体を1回だけ通知しているので、ここは無視する。
        guard extraSpeedEngine == nil else { return }
        if let delegate = self.m_Delegate {
            delegate.willSpeakRange(range: characterRange)
        }
    }
    #endif

    func isSpeaking() -> Bool {
        if extraSpeedPlayerNode != nil {
            return !isExtraSpeedStopRequested && (!isExtraSpeedSynthesisFinished || extraSpeedPendingBufferCount > 0)
        }
        return self.synthesizer.isSpeaking
    }

    func reloadSynthesizer() {
        StopExtraSpeedEngine()
        synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
    }
    
    func isPaused() -> Bool {
        if let playerNode = extraSpeedPlayerNode {
            return !playerNode.isPlaying
        }
        return self.synthesizer.isPaused
    }
}
#if false // AVSpeechSynthesizer を開放するとメモリ解放できそうなので必要なくなりました
class Speaker_WithoutWillSpeakRange: NSObject, AVSpeechSynthesizerDelegate {
    var synthesizer = AVSpeechSynthesizer()
    var m_Voice:AVSpeechSynthesisVoice = AVSpeechSynthesisVoice(language: "ja-JP") ?? AVSpeechSynthesisVoice()
    var m_Pitch:Float = 1.0
    var m_Rate:Float = AVSpeechUtteranceDefaultSpeechRate
    var m_Volume:Float = 1.0
    var m_Delay:TimeInterval = 0.0
    var m_Delegate:SpeakRangeDelegate? = nil
    var isSpeechKicked:Bool = false
    
    override init() {
        super.init()
        synthesizer.delegate = self
        SetNotificationHandler()
    }
    
    deinit {
        RemoveNotificationHandler()
        synthesizer.delegate = nil
    }
    
    func Speech(text:String) {
        if NiftyUtility.isTesting() {
            return
        }
        isSpeechKicked = true
        let utt = AVSpeechUtterance(string: text)
        utt.voice = m_Voice
        utt.pitchMultiplier = m_Pitch
        utt.rate = m_Rate
        utt.postUtteranceDelay = m_Delay
        utt.volume = max(0.0, min(1.0, m_Volume))
        synthesizer.speak(utt)
    }
    
    func Stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    func Pause() {
        synthesizer.pauseSpeaking(at: .immediate)
    }
    
    func Resume() {
        synthesizer.continueSpeaking()
    }
    
    var voice:AVSpeechSynthesisVoice {
        get { return m_Voice }
        set(value) { m_Voice = value }
    }
    func SetVoiceWith(identifier:String, language:String) {
        if let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            m_Voice = voice
            return
        }
        if let voice = AVSpeechSynthesisVoice(language: language) {
            m_Voice = voice
            return
        }
    }
    func SetVoiceWith(language:String) {
        if let voice = AVSpeechSynthesisVoice(language: language) {
            m_Voice = voice
        }
    }
    var pitch:Float {
        get { return m_Pitch }
        set(value) { m_Pitch = value }
    }
    var rate:Float {
        get { return m_Rate }
        set(value) {
            if value > AVSpeechUtteranceMaximumSpeechRate {
                m_Rate = AVSpeechUtteranceMaximumSpeechRate
                return
            }
            if value < AVSpeechUtteranceMinimumSpeechRate {
                m_Rate = AVSpeechUtteranceMinimumSpeechRate
                return
            }
            m_Rate = value
        }
    }
    var volume:Float {
        get { return m_Volume }
        set(value) {
            m_Volume = max(0.0, min(1.0, value))
        }
    }
    var delay:TimeInterval {
        get { return m_Delay }
        set(value) { m_Delay = value }
    }
    var delegate:SpeakRangeDelegate? {
        get { return m_Delegate }
        set(value) { m_Delegate = value }
    }
    
    func SetNotificationHandler() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(sessionDidInterrupt(notification:)), name: AVAudioSession.interruptionNotification, object: nil)
    }
    func RemoveNotificationHandler() {
        let center = NotificationCenter.default
        center.removeObserver(self)
    }
    
    @objc func sessionDidInterrupt(notification:Notification) {
        guard let interruptType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber, let type = AVAudioSession.InterruptionType(rawValue: interruptType.uintValue) else { return }
        switch type {
        case AVAudioSession.InterruptionType.began:
            Pause()
        case AVAudioSession.InterruptionType.ended:
            Resume()
        default:
            break
        }
    }
    
    @objc func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        delegate?.finishSpeak(isCancel: false, speechString: utterance.speechString)
    }
    @objc func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        delegate?.finishSpeak(isCancel: true, speechString: utterance.speechString)
    }

    /*
    #if !os(watchOS)
    @objc func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        if let delegate = self.m_Delegate {
            delegate.willSpeakRange(range: characterRange)
        }
    }
    #endif
     */
    
    func isSpeaking() -> Bool {
        return self.synthesizer.isSpeaking
    }
    
    func reloadSynthesizer() {
        synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
    }
    
    func isPaused() -> Bool {
        return self.synthesizer.isPaused
    }
}
#endif // AVSpeechSynthesizer を開放するとメモリ解放できそうなので必要なくなりました
