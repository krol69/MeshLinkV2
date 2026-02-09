import Foundation
import UIKit

// MARK: - Message Model
struct ChatMessage: Identifiable, Codable, Equatable {
    let id: String
    let sender: String
    let text: String
    let timestamp: Date
    let isOwn: Bool
    let encrypted: Bool
    let method: String
    var delivered: Bool
    var imageData: Data?
    
    init(sender: String, text: String, isOwn: Bool = false, encrypted: Bool = true, method: String = "BLE", delivered: Bool = false, imageData: Data? = nil) {
        self.id = UUID().uuidString
        self.sender = sender
        self.text = text
        self.timestamp = Date()
        self.isOwn = isOwn
        self.encrypted = encrypted
        self.method = method
        self.delivered = delivered
        self.imageData = imageData
    }
    
    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: timestamp)
    }
    
    var hasImage: Bool { imageData != nil && !(imageData?.isEmpty ?? true) }
    
    var uiImage: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id && lhs.delivered == rhs.delivered
    }
}

// MARK: - Wire Protocol v3
struct WireMessage: Codable {
    let v: Int
    let type: String         // "msg", "typing", "ack", "img"
    let id: String
    let sender: String
    let text: String?
    let ackId: String?
    let ttl: Int?            // mesh relay hop count
    let originId: String?    // original sender for relay
    let imgData: String?     // base64 image data
    let imgThumb: String?    // base64 thumbnail
    
    init(type: String, sender: String, text: String? = nil, id: String? = nil,
         ackId: String? = nil, ttl: Int = 3, originId: String? = nil,
         imgData: String? = nil, imgThumb: String? = nil) {
        self.v = 3
        self.type = type
        self.id = id ?? UUID().uuidString
        self.sender = sender
        self.text = text
        self.ackId = ackId
        self.ttl = ttl
        self.originId = originId ?? sender
        self.imgData = imgData
        self.imgThumb = imgThumb
    }
}

// MARK: - Chunk Protocol (for large messages)
struct ChunkEnvelope: Codable {
    let msgId: String
    let seq: Int
    let total: Int
    let data: String // base64 chunk
}

// MARK: - Peer Model
struct BLEPeer: Identifiable, Equatable {
    let id: String
    var name: String
    var connected: Bool
    var rssi: Int
    var lastSeen: Date
    var isMeshLink: Bool
    
    var signalStrength: String {
        if rssi > -50 { return "Strong" }
        if rssi > -70 { return "Good" }
        if rssi > -85 { return "Weak" }
        return "Very Weak"
    }
    
    static func == (lhs: BLEPeer, rhs: BLEPeer) -> Bool {
        lhs.id == rhs.id && lhs.connected == rhs.connected && lhs.name == rhs.name && lhs.isMeshLink == rhs.isMeshLink
    }
}

// MARK: - Log Entry
struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let text: String
    let level: LogLevel
    
    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: timestamp)
    }
    
    enum LogLevel {
        case info, success, warning, error, data
    }
}
