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
    // 合成自体は等倍(1.0)で行い、write(_:toBufferCallback:)で音声波形をバッファとして受け取って、
    // 自前のAVAudioEngine(AVAudioPlayerNode -> AVAudioUnitTimePitch -> mainMixerNode)へ流し込み、
    // TimePitchのrateで追加の倍率をかけて再生する(TimePitchはピッチを維持したまま速度だけ変えられる)。
    //
    // 注意点1: write() 経由だと willSpeakRange 等の細かい単語単位の通知タイミングは実際の(加速後の)
    // 再生タイミングとズレる(合成は先に等倍速度でどんどん進んでしまうため)。単語単位のハイライト追従は
    // 諦め、再生を開始した瞬間に発話文字列全体を1回だけ通知するだけに留める。
    //
    // 注意点2(重要): 届いたバッファを片っ端からscheduleして即座に再生を始める実装だと、
    // 再生側は倍率分(最大5倍)速く音声データを消費するのに対し、write()側の生成はほぼ等倍速度でしか
    // 進まないため、再生がすぐに生成に追いついてバッファが枯渇し、その度に音切れ/ノイズ
    // (ユーザ報告の「ハウリング」のような壊れた音)が発生していた。
    // これを避けるため、1回のSpeech()呼び出し分(だいたい数百文字程度に分割済み)の合成が
    // 完全に終わるまで一旦全バッファを溜め込み、揃ってから一括で再生を開始する。
    // 合成自体はほぼ等倍速度で進むとはいえ、1呼び出し分の文章量は数百文字程度に分割済み
    // (StorySpeaker側でだいたい200文字程度に区切られる)なので、再生開始までの待ち時間は
    // 数秒程度に収まる。
    // [案E] ライブのAVAudioEngine上でTimePitch処理をしながら実機ハードウェアへリアルタイム出力する
    // 従来の方式ではなく、TimePitchによる高速化処理そのものを先にオフラインレンダリング(ハードウェア/
    // オーディオセッションと一切関係の無い、メモリ上だけの計算)で完了させてしまい、
    // 出来上がった「既に加速済みの音声」を、TimePitch等を一切挟まない単純なplayerNode再生だけで
    // 鳴らす。ライブのオーディオセッション上でTimePitch処理をする事自体が問題の原因になっている
    // 可能性を検証するための版。
    private func SpeechWithExtraSpeed(text: String, extraSpeed: Float) {
        StopExtraSpeedEngine() // 直前の発話がまだ残っていれば先に片付ける
        extraSpeedSpeechString = text
        isExtraSpeedSynthesisFinished = false
        isExtraSpeedStopRequested = false
        extraSpeedPendingBufferCount = 0

        let liveEngine = AVAudioEngine()
        let livePlayerNode = AVAudioPlayerNode()
        liveEngine.attach(livePlayerNode)
        extraSpeedEngine = liveEngine
        extraSpeedPlayerNode = livePlayerNode

        let utt = AVSpeechUtterance(string: text)
        utt.voice = m_Voice
        utt.pitchMultiplier = m_Pitch
        utt.rate = AVSpeechUtteranceMaximumSpeechRate
        utt.postUtteranceDelay = m_Delay
        utt.volume = max(0.0, min(1.0, m_Volume))

        var collectedBuffers: [AVAudioPCMBuffer] = []
        var collectedFormat: AVAudioFormat? = nil

        synthesizer.write(utt) { [weak self] buffer in
            guard let self = self, let pcmBuffer = buffer as? AVAudioPCMBuffer else { return }
            if pcmBuffer.frameLength == 0 {
                // 空バッファは合成完了の合図。ここからオフラインで高速化レンダリングを行う
                // (ハードウェア/オーディオセッションと無関係なので別キューで処理して構わない)。
                DispatchQueue.global(qos: .userInitiated).async {
                    guard let format = collectedFormat, !collectedBuffers.isEmpty else {
                        DispatchQueue.main.async {
                            guard self.extraSpeedEngine === liveEngine, !self.isExtraSpeedStopRequested else { return }
                            self.isExtraSpeedSynthesisFinished = true
                            self.FinishExtraSpeedSpeechIfNeeded()
                        }
                        return
                    }
                    // 全バッファを1本の連続したソースへ結合する。
                    let totalFrames = collectedBuffers.reduce(AVAudioFrameCount(0)) { $0 + $1.frameLength }
                    guard let sourceBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else { return }
                    for buf in collectedBuffers {
                        guard let src = buf.floatChannelData, let dst = sourceBuffer.floatChannelData else { continue }
                        let channelCount = Int(format.channelCount)
                        let offset = Int(sourceBuffer.frameLength)
                        for ch in 0..<channelCount {
                            (dst[ch] + offset).update(from: src[ch], count: Int(buf.frameLength))
                        }
                        sourceBuffer.frameLength += buf.frameLength
                    }

                    // オフライン(ハードウェア出力なし)のエンジンでTimePitch処理だけを完了させる。
                    let offlineEngine = AVAudioEngine()
                    let offlinePlayerNode = AVAudioPlayerNode()
                    let offlineTimePitch = AVAudioUnitTimePitch()
                    offlineTimePitch.rate = extraSpeed
                    offlineEngine.attach(offlinePlayerNode)
                    offlineEngine.attach(offlineTimePitch)
                    offlineEngine.connect(offlinePlayerNode, to: offlineTimePitch, format: format)
                    offlineEngine.connect(offlineTimePitch, to: offlineEngine.mainMixerNode, format: format)

                    let renderedBuffer: AVAudioPCMBuffer?
                    do {
                        try offlineEngine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 4096)
                        try offlineEngine.start()
                        offlinePlayerNode.scheduleBuffer(sourceBuffer, completionCallbackType: .dataPlayedBack, completionHandler: nil)
                        offlinePlayerNode.play()

                        // 加速後の総フレーム数を見積もり、多少余裕を持たせてレンダリングする。
                        let estimatedOutputFrames = AVAudioFrameCount(Double(totalFrames) / Double(extraSpeed)) + offlineEngine.manualRenderingMaximumFrameCount * 4
                        let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: estimatedOutputFrames)
                        let chunk = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: offlineEngine.manualRenderingMaximumFrameCount)
                        if let output = output, let chunk = chunk {
                            while output.frameLength < estimatedOutputFrames {
                                let framesToRender = min(offlineEngine.manualRenderingMaximumFrameCount, estimatedOutputFrames - output.frameLength)
                                let status = try offlineEngine.renderOffline(framesToRender, to: chunk)
                                if status != .success || chunk.frameLength == 0 { break }
                                if let src = chunk.floatChannelData, let dst = output.floatChannelData {
                                    let channelCount = Int(format.channelCount)
                                    let offset = Int(output.frameLength)
                                    for ch in 0..<channelCount {
                                        (dst[ch] + offset).update(from: src[ch], count: Int(chunk.frameLength))
                                    }
                                }
                                output.frameLength += chunk.frameLength
                            }
                        }
                        renderedBuffer = output
                    } catch {
                        NSLog("Speaker: offline render failed: \(error)")
                        renderedBuffer = nil
                    }
                    offlinePlayerNode.stop()
                    offlineEngine.stop()

                    DispatchQueue.main.async {
                        guard self.extraSpeedEngine === liveEngine, !self.isExtraSpeedStopRequested else { return }
                        self.isExtraSpeedSynthesisFinished = true
                        guard let renderedBuffer = renderedBuffer, renderedBuffer.frameLength > 0 else {
                            self.FinishExtraSpeedSpeechIfNeeded()
                            return
                        }
                        liveEngine.connect(livePlayerNode, to: liveEngine.mainMixerNode, format: format)
                        do {
                            try liveEngine.start()
                        } catch {
                            NSLog("Speaker: extra speed live engine start failed: \(error)")
                        }
                        self.extraSpeedPendingBufferCount = 1
                        self.m_Delegate?.willSpeakRange(range: NSRange(location: 0, length: (text as NSString).length))
                        livePlayerNode.play()
                        livePlayerNode.scheduleBuffer(renderedBuffer, completionCallbackType: .dataPlayedBack) { _ in
                            DispatchQueue.main.async {
                                self.extraSpeedPendingBufferCount -= 1
                                self.FinishExtraSpeedSpeechIfNeeded()
                            }
                        }
                    }
                }
                return
            }
            DispatchQueue.main.async {
                guard self.extraSpeedEngine === liveEngine, !self.isExtraSpeedStopRequested else { return }
                if collectedFormat == nil { collectedFormat = pcmBuffer.format }
                collectedBuffers.append(pcmBuffer)
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
