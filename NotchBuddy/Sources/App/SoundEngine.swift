import AVFoundation
import AppKit

/// Preloaded WAV players with near-zero latency.
/// Volume default 0.12 (matches prototype: gain ×6 then vol=0.12).
///
/// Device churn / volume-bezel fix: some external output devices (e.g. a USB
/// capture device set as the default output) flash the macOS volume HUD every
/// time Core Audio engages them. Playing many short sounds used to StartIO /
/// StopIO the device per sound, popping the bezel repeatedly. We now (1) skip
/// `prepareToPlay()` at launch so nothing engages the device until a sound
/// actually plays, and (2) hold a short silent keep-alive so a burst of sounds
/// reuses one device session instead of re-engaging per sound. The keep-alive
/// is released after a few seconds of silence so the audio device can idle and
/// the Mac can still sleep.
@MainActor
final class SoundEngine {
    static let shared = SoundEngine()

    var enabled: Bool = true
    var volume: Float = 0.12 {
        didSet { players.values.forEach { $0.forEach { $0.volume = volume } } }
    }

    // Pool of 3 players per sound to allow overlapping playback
    private var players: [String: [AVAudioPlayer]] = [:]

    // Silent looping player that keeps the output device engaged across a burst
    // of sounds, plus a cancellable task that releases it after idle.
    private var keepAlive: AVAudioPlayer?
    private var keepAliveStop: DispatchWorkItem?
    private let keepAliveIdle: TimeInterval = 20

    private init() {
        preload()
    }

    private func preload() {
        let names = ["peek","open","close","hover","blip","slap","annoyed","dizzy","greet",
                     "work","finish","error","approval","question","approve","gulp","tick",
                     "send","love","pop","proud","wink","yawn","attach","think","search",
                     "rate","sleep"]
        for name in names {
            guard let url = Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "sounds") else { continue }
            var pool: [AVAudioPlayer] = []
            for _ in 0..<3 {
                if let p = try? AVAudioPlayer(contentsOf: url) {
                    p.volume = volume
                    // No prepareToPlay() — that engages the output device at launch
                    // (and flashes the volume bezel on some devices). Load lazily.
                    pool.append(p)
                }
            }
            if !pool.isEmpty { players[name] = pool }
        }
        // Keep-alive: reuse any loaded sound as a silent, looping player.
        if let url = players.values.first?.first?.url,
           let ka = try? AVAudioPlayer(contentsOf: url) {
            ka.volume = 0
            ka.numberOfLoops = -1
            keepAlive = ka
        }
    }

    func play(_ name: String) {
        guard enabled && AppState.shared.soundEnabled else { return }
        guard let pool = players[name] else { return }
        holdDeviceWarm()
        // Find a player that is not currently playing
        let player = pool.first { !$0.isPlaying } ?? pool[0]
        player.currentTime = 0
        player.volume = volume
        player.play()
    }

    /// Starts (or extends) the silent keep-alive so the output device stays
    /// engaged through a burst of sounds, then releases it after idle.
    private func holdDeviceWarm() {
        if keepAlive?.isPlaying != true { keepAlive?.play() }
        keepAliveStop?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.keepAlive?.stop() }
        keepAliveStop = work
        DispatchQueue.main.asyncAfter(deadline: .now() + keepAliveIdle, execute: work)
    }
}
