import Foundation
import CryptoKit
import CommonCrypto

// MARK: - AES-256-GCM Encryption Service
final class CryptoService {
    static let shared = CryptoService()
    
    private let salt = "meshlink-salt-v2".data(using: .utf8)!
    private let iterations = 100_000
    private(set) var derivedKey: SymmetricKey?
    
    var isReady: Bool { derivedKey != nil }
    
    // MARK: - Key Derivation (PBKDF2 → AES-256)
    func deriveKey(from password: String) {
        guard !password.isEmpty else { derivedKey = nil; return }
        let passwordData = password.data(using: .utf8)!
        var derivedBytes = [UInt8](repeating: 0, count: 32)
        let status = derivedBytes.withUnsafeMutableBytes { derivedBuf in
            passwordData.withUnsafeBytes { pwBuf in
                salt.withUnsafeBytes { saltBuf in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        pwBuf.baseAddress?.assumingMemoryBound(to: Int8.self),
                        passwordData.count,
                        saltBuf.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedBuf.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        32
                    )
                }
            }
        }
        if status == kCCSuccess {
            derivedKey = SymmetricKey(data: derivedBytes)
        }
    }
    
    func encrypt(_ plaintext: String) -> String {
        guard let key = derivedKey, let data = plaintext.data(using: .utf8) else { return plaintext }
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            let combined = sealedBox.combined!
            return "AES:" + combined.base64EncodedString()
        } catch {
            return plaintext
        }
    }
    
    func decrypt(_ ciphertext: String) -> String {
        guard ciphertext.hasPrefix("AES:"), let key = derivedKey else {
            return ciphertext
        }
        let b64 = String(ciphertext.dropFirst(4))
        guard let data = Data(base64Encoded: b64) else { return "[Invalid data]" }
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decrypted = try AES.GCM.open(sealedBox, using: key)
            return String(data: decrypted, encoding: .utf8) ?? "[Decode error]"
        } catch {
            return "[Decryption failed]"
        }
    }
    
    func encryptData(_ data: Data) -> Data? {
        guard let key = derivedKey else { return nil }
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch { return nil }
    }
    
    func decryptData(_ data: Data) -> Data? {
        guard let key = derivedKey else { return nil }
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: key)
        } catch { return nil }
    }
}
