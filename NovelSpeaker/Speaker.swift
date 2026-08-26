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
    static let maximumTotalSpeechRate: Float = 5.0
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
        if extraSpeed <= 1.0 {
            // 従来通りの経路。rateを1.0超から1.0以下に戻した直後は、前回使っていた加速再生用の
            // AVAudioEngineがまだ残っている(=extraSpeedEngine != nil)ことがあり、これが残ったままだと
            // (1) 古いエンジンが鳴り続けて通常再生の音と衝突する、(2) didFinish等のデリゲートが
            // 「加速再生中だから」という理由で無視され続けて通常再生が正しく完了扱いにならない、
            // という2つの不具合を引き起こす。1.0以下の経路に入る際は必ず先に片付けておく。
            StopExtraSpeedEngine()
            let utt = AVSpeechUtterance(string: text)
            utt.voice = m_Voice
            utt.pitchMultiplier = m_Pitch
            utt.rate = m_Rate
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
        let timePitch = AVAudioUnitTimePitch()
        timePitch.rate = extraSpeed
        engine.attach(playerNode)
        engine.attach(timePitch)
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

        NSLog("Speaker: SpeechWithExtraSpeed start. extraSpeed=\(extraSpeed) textLength=\((text as NSString).length)")

        synthesizer.write(utt) { [weak self] buffer in
            guard let self = self, let pcmBuffer = buffer as? AVAudioPCMBuffer else { return }
            if pcmBuffer.frameLength == 0 {
                // 空バッファは合成完了の合図。ここで初めてファイルを閉じて再生を開始する。
                DispatchQueue.main.async {
                    guard self.extraSpeedEngine === engine, !self.isExtraSpeedStopRequested else { return }
                    self.isExtraSpeedSynthesisFinished = true
                    NSLog("Speaker: synthesis finished. buffers=\(receivedBufferCount) totalFrames=\(totalFrameLength) writeError=\(String(describing: writeError))")
                    audioFile = nil // ファイルをclose(参照を切る事でAVAudioFileが書き込みを確定させる)
                    guard writeError == nil, totalFrameLength > 0 else {
                        try? FileManager.default.removeItem(at: tmpURL)
                        self.FinishExtraSpeedSpeechIfNeeded()
                        return
                    }
                    do {
                        let playbackFile = try AVAudioFile(forReading: tmpURL)
                        NSLog("Speaker: playback file opened. length=\(playbackFile.length) format=\(playbackFile.processingFormat)")
                        engine.connect(playerNode, to: timePitch, format: playbackFile.processingFormat)
                        engine.connect(timePitch, to: engine.mainMixerNode, format: playbackFile.processingFormat)
                        try engine.start()
                        self.extraSpeedPendingBufferCount = 1
                        self.m_Delegate?.willSpeakRange(range: NSRange(location: 0, length: (text as NSString).length))
                        playerNode.scheduleFile(playbackFile, at: nil, completionCallbackType: .dataPlayedBack) { _ in
                            DispatchQueue.main.async {
                                self.extraSpeedPendingBufferCount -= 1
                                self.FinishExtraSpeedSpeechIfNeeded()
                                try? FileManager.default.removeItem(at: tmpURL)
                            }
                        }
                        playerNode.play()
                    } catch {
                        NSLog("Speaker: extra speed file playback setup failed: \(error)")
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
                NSLog("Speaker: extra speed audio file write failed: \(error)")
            }
        }
    }

    private func FinishExtraSpeedSpeechIfNeeded() {
        guard isExtraSpeedSynthesisFinished, extraSpeedPendingBufferCount <= 0, !isExtraSpeedStopRequested, extraSpeedEngine != nil else { return }
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
