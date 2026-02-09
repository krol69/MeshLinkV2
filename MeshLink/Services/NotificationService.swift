import Foundation
import UserNotifications

// MARK: - Local Notification Service
final class NotificationService {
    static let shared = NotificationService()
    
    private var authorized = false
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            DispatchQueue.main.async { self?.authorized = granted }
        }
    }
    
    func sendMessageNotification(from sender: String, text: String) {
        guard authorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "MeshLink: \(sender)"
        content.body = text.count > 100 ? String(text.prefix(100)) + "..." : text
        content.sound = .default
        content.categoryIdentifier = "MESSAGE"
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func sendConnectionNotification(peerName: String, connected: Bool) {
        guard authorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "MeshLink"
        content.body = connected ? "\(peerName) connected" : "\(peerName) disconnected"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: nil)
    }
}
