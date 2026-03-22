//
//  AudioFeedbackManager.swift
//  CBED
//

import AudioToolbox
import SwiftySound
import UIKit

final class AudioFeedbackManager {
    enum FeedbackSound {
        case correct
        case incorrect
        case pass
        case fail

        var resourceName: String {
            switch self {
            case .correct:
                return "DING"
            case .incorrect:
                return "KICK"
            case .pass:
                return "VICTORY"
            case .fail:
                return "FAIL"
            }
        }
    }

    static let shared = AudioFeedbackManager()

    private let buttonTapSoundID: SystemSoundID = 1104
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)

    private init() {}

    func prepare() {
        impactGenerator.prepare()
    }

    func playButtonTapIfEnabled() {
        guard Storage.isButtonSoundEnabled else {
            return
        }

        AudioServicesPlaySystemSound(buttonTapSoundID)
        impactGenerator.impactOccurred(intensity: 0.7)
        impactGenerator.prepare()
    }

    func playIfEnabled(_ sound: FeedbackSound) {
        guard Storage.isButtonSoundEnabled,
              let url = Bundle.main.url(forResource: sound.resourceName, withExtension: "mp3") else {
            return
        }

        Sound.play(url: url)
    }
}
