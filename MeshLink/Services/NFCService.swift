import Foundation
import CoreNFC

// MARK: - NFC Key Sharing Service
final class NFCService: NSObject, ObservableObject {
    static let shared = NFCService()
    
    @Published var lastReadKey: String?
    @Published var isReading = false
    @Published var isWriting = false
    @Published var statusMessage: String?
    
    private var writeSession: NFCNDEFReaderSession?
    private var readSession: NFCNDEFReaderSession?
    private var pendingWriteKey: String?
    
    var onKeyReceived: ((String) -> Void)?
    var onLog: ((String, LogEntry.LogLevel) -> Void)?
    
    var isAvailable: Bool {
        NFCNDEFReaderSession.readingAvailable
    }
    
    // MARK: - Read Key from NFC Tag
    func readKey() {
        guard isAvailable else {
            statusMessage = "NFC not available on this device"
            onLog?("NFC not available", .error)
            return
        }
        readSession = NFCNDEFReaderSession(delegate: self, queue: .main, invalidateAfterFirstRead: true)
        readSession?.alertMessage = "Hold your iPhone near the NFC tag to read the MeshLink encryption key."
        readSession?.begin()
        isReading = true
        onLog?("NFC read session started", .info)
    }
    
    // MARK: - Write Key to NFC Tag
    func writeKey(_ key: String) {
        guard isAvailable else {
            statusMessage = "NFC not available on this device"
            onLog?("NFC not available", .error)
            return
        }
        guard !key.isEmpty else {
            statusMessage = "No key to write"
            return
        }
        pendingWriteKey = key
        writeSession = NFCNDEFReaderSession(delegate: self, queue: .main, invalidateAfterFirstRead: false)
        writeSession?.alertMessage = "Hold your iPhone near an NFC tag to write the MeshLink encryption key."
        writeSession?.begin()
        isWriting = true
        onLog?("NFC write session started", .info)
    }
    
    // MARK: - Create NDEF Message
    private func createNDEFMessage(key: String) -> NFCNDEFMessage {
        // Store as a custom MeshLink record + a URI for cross-platform
        let meshLinkPayload = "meshlink://key/\(key)"
        
        // URI record
        let uriPayload = NFCNDEFPayload.wellKnownTypeURIPayload(string: meshLinkPayload)!
        
        // Text record with the raw key
        let textPayload = NFCNDEFPayload.wellKnownTypeTextPayload(
            string: "MeshLink Key: \(key)",
            locale: Locale(identifier: "en")
        )!
        
        return NFCNDEFMessage(records: [uriPayload, textPayload])
    }
    
    // MARK: - Parse Key from NDEF
    private func extractKey(from message: NFCNDEFMessage) -> String? {
        for record in message.records {
            // Try URI record first
            if let uri = record.wellKnownTypeURIPayload()?.absoluteString {
                if uri.hasPrefix("meshlink://key/") {
                    return String(uri.dropFirst("meshlink://key/".count))
                }
            }
            
            // Try text record
            if let (text, _) = record.wellKnownTypeTextPayload() {
                if text.hasPrefix("MeshLink Key: ") {
                    return String(text.dropFirst("MeshLink Key: ".count))
                }
                // If it's just a plain key string
                if !text.isEmpty && !text.contains(" ") {
                    return text
                }
            }
        }
        return nil
    }
}

// MARK: - NFCNDEFReaderSessionDelegate
extension NFCService: NFCNDEFReaderSessionDelegate {
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        // Session is active
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.isReading = false
            self?.isWriting = false
            
            let nfcError = error as? NFCReaderError
            if nfcError?.code != .readerSessionInvalidationErrorFirstNDEFTagRead &&
               nfcError?.code != .readerSessionInvalidationErrorUserCanceled {
                self?.statusMessage = "NFC error: \(error.localizedDescription)"
                self?.onLog?("NFC error: \(error.localizedDescription)", .error)
            }
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // Read mode — extract key from first message
        guard let message = messages.first, let key = extractKey(from: message) else {
            DispatchQueue.main.async { [weak self] in
                self?.statusMessage = "No MeshLink key found on tag"
                self?.onLog?("NFC tag read but no MeshLink key found", .warning)
            }
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.lastReadKey = key
            self?.statusMessage = "Key received via NFC!"
            self?.onKeyReceived?(key)
            self?.onLog?("Key received via NFC", .success)
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No tag found")
            return
        }
        
        session.connect(to: tag) { [weak self] error in
            guard let self = self, error == nil else {
                session.invalidate(errorMessage: "Connection failed")
                return
            }
            
            tag.queryNDEFStatus { status, _, error in
                guard error == nil else {
                    session.invalidate(errorMessage: "Query failed")
                    return
                }
                
                if self.isWriting, let key = self.pendingWriteKey {
                    // Write mode
                    guard status == .readWrite else {
                        session.invalidate(errorMessage: "Tag is read-only")
                        return
                    }
                    
                    let message = self.createNDEFMessage(key: key)
                    tag.writeNDEF(message) { error in
                        if let error = error {
                            session.invalidate(errorMessage: "Write failed: \(error.localizedDescription)")
                            DispatchQueue.main.async {
                                self.onLog?("NFC write failed: \(error.localizedDescription)", .error)
                            }
                        } else {
                            session.alertMessage = "Key written to NFC tag!"
                            session.invalidate()
                            DispatchQueue.main.async {
                                self.statusMessage = "Key written to NFC tag!"
                                self.pendingWriteKey = nil
                                self.onLog?("Encryption key written to NFC tag", .success)
                            }
                        }
                    }
                } else {
                    // Read mode
                    tag.readNDEF { message, error in
                        if let error = error {
                            session.invalidate(errorMessage: "Read failed: \(error.localizedDescription)")
                            return
                        }
                        guard let message = message, let key = self.extractKey(from: message) else {
                            session.invalidate(errorMessage: "No MeshLink key on this tag")
                            return
                        }
                        session.alertMessage = "Key received!"
                        session.invalidate()
                        DispatchQueue.main.async {
                            self.lastReadKey = key
                            self.statusMessage = "Key received via NFC!"
                            self.onKeyReceived?(key)
                            self.onLog?("Key received via NFC", .success)
                        }
                    }
                }
            }
        }
    }
}
