import SwiftUI

struct SetupView: View {
    @EnvironmentObject var vm: MeshViewModel
    @FocusState private var focusField: Field?
    
    enum Field { case name, key }
    
    var body: some View {
        ZStack {
            Theme.bg0.ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)
                    
                    // Logo
                    VStack(spacing: 12) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 44))
                            .foregroundStyle(Theme.gradient)
                        
                        Text("MESHLINK")
                            .font(.system(size: 38, weight: .black))
                            .foregroundStyle(Theme.gradientFull)
                        
                        Text("AES-256 ENCRYPTED P2P MESH")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(Theme.textMuted)
                            .tracking(2)
                    }
                    .padding(.bottom, 36)
                    
                    // Form Card
                    VStack(spacing: 20) {
                        // Node Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NODE NAME")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(Theme.accent)
                                .tracking(1.5)
                            
                            TextField("Enter your display name", text: $vm.username)
                                .textFieldStyle(.plain)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Theme.text1)
                                .padding(14)
                                .background(Theme.bg0)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border))
                                .focused($focusField, equals: .name)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .submitLabel(.next)
                                .onSubmit { focusField = .key }
                        }
                        
                        // Encryption Key
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "shield.checkered")
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.accent)
                                Text("ENCRYPTION KEY")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Theme.accent)
                                    .tracking(1.5)
                            }
                            
                            HStack(spacing: 8) {
                                Group {
                                    if vm.showKey {
                                        TextField("Shared secret", text: $vm.encryptionKey)
                                            .font(.system(size: 14, design: .monospaced))
                                    } else {
                                        SecureField("Shared secret", text: $vm.encryptionKey)
                                            .font(.system(size: 14, design: .monospaced))
                                    }
                                }
                                .textFieldStyle(.plain)
                                .foregroundColor(Theme.text1)
                                .focused($focusField, equals: .key)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .submitLabel(.go)
                                .onSubmit { vm.joinMesh() }
                                
                                Button { vm.showKey.toggle() } label: {
                                    Image(systemName: vm.showKey ? "eye.slash" : "eye")
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.text2)
                                }
                            }
                            .padding(14)
                            .background(Theme.bg0)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border))
                            
                            // NFC + QR shortcuts
                            HStack(spacing: 8) {
                                if vm.nfc.isAvailable {
                                    Button(action: vm.readKeyFromNFC) {
                                        HStack(spacing: 5) {
                                            Image(systemName: "wave.3.right")
                                                .font(.system(size: 10))
                                            Text("NFC")
                                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        }
                                        .foregroundColor(Theme.accentBlue)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(Theme.accentBlue.opacity(0.08))
                                        .cornerRadius(6)
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.accentBlue.opacity(0.2)))
                                    }
                                }
                                
                                Text("or type same key on both devices")
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.textMuted)
                            }
                        }
                        
                        // Join Button
                        Button(action: vm.joinMesh) {
                            HStack(spacing: 10) {
                                Text("JOIN MESH")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .tracking(1)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(joinButtonBg)
                            .foregroundColor(canJoin ? Theme.bg0 : Theme.textMuted)
                            .cornerRadius(8)
                        }
                        .disabled(!canJoin)
                    }
                    .padding(24)
                    .background(Theme.bg1)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border))
                    .padding(.horizontal, 20)
                    
                    // Bluetooth warning
                    if !vm.bluetoothReady {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.warning)
                            Text("Bluetooth not available. Enable it in Settings.")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(Theme.warning.opacity(0.8))
                        }
                        .padding(14)
                        .background(Theme.warning.opacity(0.06))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.warning.opacity(0.15)))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    
                    // NFC status
                    if let status = vm.nfc.statusMessage {
                        Text(status)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Theme.accent)
                            .padding(.top, 12)
                    }
                    
                    Text("No servers. No internet. Just Bluetooth. v3.0.0")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                        .padding(.top, 20)
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .onAppear { focusField = .name }
    }
    
    private var canJoin: Bool {
        !vm.username.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    @ViewBuilder
    private var joinButtonBg: some View {
        if canJoin { Theme.gradient } else { Color.white.opacity(0.04) }
    }
}
