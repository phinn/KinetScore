import AVFoundation
import Foundation
import Observation

/// 节拍器引擎:AVAudioEngine 实时合成 click 音,零音频资源文件。
/// 强拍 1600Hz 短音 + 弱拍 1100Hz 更短音,envelope 5ms 起、指数衰减防爆音。
/// 合盖练琴场景:后台 audio session 继续响;UI 只读 @Observable 状态。
@Observable @MainActor
final class MetroEngine {
    // MARK: - 状态
    private(set) var isRunning = false
    var bpm: Int = 90 {
        didSet {
            let clamped = min(max(30, bpm), 250)
            if clamped != bpm { bpm = clamped; return }
            if isRunning { reschedule() }
        }
    }
    /// 每小节拍数,强拍落在第 1 拍
    var beatsPerBar: Int = 4 { didSet { beatsPerBar = min(max(1, beatsPerBar), 12); beatInBar = 0 } }
    private(set) var beatInBar: Int = 0     // 小节内当前拍,0-based
    private(set) var totalBeats: Int = 0    // 本次启动总拍数

    /// 免费版限速 60–120 bpm,买断 30–250
    static let freeRange: ClosedRange<Int> = 60...120
    var isPro: Bool = false
    var isLocked: Bool { !isPro && !Self.freeRange.contains(bpm) }

    // MARK: - 音频图
    private let audio = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var outputFormat: AVAudioFormat?
    private var clickStrong: AVAudioPCMBuffer?
    private var clickWeak: AVAudioPCMBuffer?
    /// 下一个未排拍的宿主时间(mach time);nil = 从现在起
    private var nextBeatHost: UInt64?
    private var schedulerTask: Task<Void, Never>?
    private let lookahead: Double = 0.18   // 排程提前量,秒

    init() {
        let out = audio.outputNode
        let format = out.inputFormat(forBus: 0)
        outputFormat = format
        audio.attach(player)
        audio.connect(player, to: audio.mainMixerNode, format: format)
        clickStrong = Self.makeClick(freq: 1600, dur: 0.055, format: format)
        clickWeak = Self.makeClick(freq: 1100, dur: 0.038, format: format)
    }

    // MARK: - 控制

    func start() {
        guard !isRunning else { return }
        beatInBar = 0
        totalBeats = 0
        do {
            if !audio.isRunning { try audio.start() }
            if !player.isPlaying { player.play() }
            isRunning = true
            nextBeatHost = nil
            pump()
        } catch {
            NSLog("[KinetScore] metro start failed: %@", error.localizedDescription)
        }
    }

    func stop() {
        isRunning = false
        nextBeatHost = nil
        schedulerTask?.cancel()
        schedulerTask = nil
        player.stop()
    }

    func toggle() { isRunning ? stop() : start() }

    /// BPM 设置(免费版 60–120 限速由 capped 控制)
    func setBPM(_ value: Int, capped: Bool) {
        var v = min(max(30, value), 250)
        if capped {
            v = min(max(v, Self.freeRange.lowerBound), Self.freeRange.upperBound)
        }
        bpm = v
    }

    // MARK: - 排程核心(lookahead 窗口内排满拍,40ms 唤醒续排)

    private func pump() {
        guard isRunning else { return }
        let spb = 60.0 / Double(bpm)   // seconds per beat
        var nextHost = nextBeatHost ?? mach_absolute_time()
        let nowHost = mach_absolute_time()

        while true {
            let deltaSec = Self.hostToSeconds(nextHost &- nowHost)
            if deltaSec >= lookahead { break }

            let t = Self.hostToAVAudioTime(nextHost)
            let buf = (totalBeats % max(1, beatsPerBar) == 0) ? clickStrong : clickWeak
            if let buf { player.scheduleBuffer(buf, at: t) }
            beatInBar = (beatInBar + 1) % max(1, beatsPerBar)
            totalBeats += 1
            nextHost = nextHost &+ Self.secondsToHostTicks(spb)
        }
        nextBeatHost = nextHost

        schedulerTask?.cancel()
        schedulerTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 40_000_000)
            guard let self, self.isRunning, !Task.isCancelled else { return }
            self.pump()
        }
    }

    private func reschedule() {
        // bpm 变化后从下一个未排拍开始按新 spb 排
        guard isRunning else { return }
        nextBeatHost = nil
        pump()
    }

    // MARK: - 时间换算

    private static let timebase = {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        return info
    }()

    private static func hostToSeconds(_ ticks: UInt64) -> Double {
        Double(ticks) * Double(timebase.numer) / Double(timebase.denom) / 1_000_000_000
    }

    private static func secondsToHostTicks(_ sec: Double) -> UInt64 {
        UInt64(sec * 1_000_000_000 * Double(timebase.denom) / Double(timebase.numer))
    }

    private static func hostToAVAudioTime(_ host: UInt64) -> AVAudioTime {
        AVAudioTime(hostTime: host)
    }

    // MARK: - click 合成

    private static func makeClick(freq: Double, dur: Double, format: AVAudioFormat?) -> AVAudioPCMBuffer? {
        guard let format else { return nil }
        let sr = format.sampleRate
        let totalFrames = Int(sr * dur)
        let attackFrames = Int(sr * 0.005)
        guard totalFrames > attackFrames + 1,
              let buf = AVAudioPCMBuffer(pcmFormat: format,
                                         frameCapacity: AVAudioFrameCount(totalFrames)) else { return nil }
        buf.frameLength = AVAudioFrameCount(totalFrames)
        guard let data = buf.floatChannelData?[0] else { return nil }
        let decayFrames = Double(totalFrames - attackFrames)
        for i in 0..<totalFrames {
            let t = Double(i) / sr
            let env: Double
            if i < attackFrames {
                env = Double(i) / Double(attackFrames)
            } else {
                let d = Double(i - attackFrames)
                env = exp(-4.0 * d / decayFrames)
            }
            let sample = 0.85 * env * sin(2.0 * Double.pi * freq * t)
            data[i] = Float(sample)
        }
        return buf
    }
}
