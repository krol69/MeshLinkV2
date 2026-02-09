import Foundation
import AudioToolbox

// MARK: - Sound Service (reliable system sounds)
final class SoundService {
    static let shared = SoundService()
    
    var enabled: Bool {
        get { UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "soundEnabled") }
    }
    
    func play(_ type: SoundType) {
        guard enabled else { return }
        switch type {
        case .message:
            AudioServicesPlaySystemSound(1007) // message received
        case .connect:
            AudioServicesPlaySystemSound(1003) // positive beep
        case .disconnect:
            AudioServicesPlaySystemSound(1006) // alert
        case .send:
            AudioServicesPlaySystemSound(1004) // sent whoosh
        }
    }
    
    enum SoundType { case message, connect, disconnect, send }
}
