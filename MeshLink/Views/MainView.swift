import SwiftUI

struct MainView: View {
    @EnvironmentObject var vm: MeshViewModel
    
    var body: some View {
        ZStack {
            Theme.bg0.ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                headerBar.padding(.top, 4)
                
                if vm.showAbout { aboutPanel }
                if vm.showSettings { settingsPanel }
                if vm.showKeyShare { keySharePanel }
                
                tabBar
                
                Group {
                    switch vm.activeTab {
                    case .chat: ChatView()
                    case .peers: PeersView()
                    case .logs: LogsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Header
    private var headerBar: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.gradient)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("MESHLINK")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(Theme.gradient)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(vm.ble.connectedCount > 0 ? Theme.accent : Theme.danger)
                            .frame(width: 6, height: 6)
                            .shadow(color: vm.ble.connectedCount > 0 ? Theme.accent : Theme.danger, radius: 3)
                        
                        Text(vm.ble.connectedCount > 0
                             ? "\(vm.ble.connectedCount) peer\(vm.ble.connectedCount > 1 ? "s" : "")"
                             : "No peers")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Theme.textMuted)
                        
                        Text("|").foregroundColor(Theme.textMuted.opacity(0.4)).font(.system(size: 10))
                        
                        Text(vm.username)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Theme.text2)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                headerBtn(icon: "qrcode", active: vm.showKeyShare) {
                    vm.showKeyShare.toggle()
                    vm.showAbout = false; vm.showSettings = false
                }
                headerBtn(icon: "info.circle", active: vm.showAbout) {
                    vm.showAbout.toggle()
                    vm.showSettings = false; vm.showKeyShare = false
                }
                headerBtn(icon: vm.showSettings ? "xmark" : "gearshape", active: vm.showSettings) {
                    vm.showSettings.toggle()
                    vm.showAbout = false; vm.showKeyShare = false
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Theme.bg0.opacity(0.88))
    }
    
    private func headerBtn(icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(active ? Theme.accent : Theme.text2)
                .frame(width: 34, height: 34)
                .background(active ? Theme.accent.opacity(0.15) : Color.clear)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(active ? Theme.borderAccent : Theme.border))
        }
    }
    
    // MARK: - Key Share Panel (QR + NFC)
    private var keySharePanel: some View {
        VStack(spacing: 16) {
            Text("SHARE ENCRYPTION KEY")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.accent)
                .tracking(1.5)
            
            // QR Code
            if let qrImage = vm.generateQRCode(for: vm.encryptionKey) {
                VStack(spacing: 8) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                        .background(Color.white)
                        .cornerRadius(12)
                    
                    Text("Scan this QR code on another device")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                }
            } else {
                Text("Set an encryption key first")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textMuted)
            }
            
            // NFC Buttons
            if vm.nfc.isAvailable {
                HStack(spacing: 12) {
                    Button(action: vm.readKeyFromNFC) {
                        HStack(spacing: 6) {
                            Image(systemName: "wave.3.right")
                                .font(.system(size: 12))
                            Text("Read NFC")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        }
                        .foregroundColor(Theme.accentBlue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Theme.accentBlue.opacity(0.08))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.accentBlue.opacity(0.2)))
                    }
                    
                    Button(action: vm.writeKeyToNFC) {
                        HStack(spacing: 6) {
                            Image(systemName: "wave.3.left")
                                .font(.system(size: 12))
                            Text("Write NFC")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        }
                        .foregroundColor(Theme.purple)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Theme.purple.opacity(0.08))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.purple.opacity(0.2)))
                    }
                }
                
                Text("Write key to NFC tag → tap other phone to read")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
            }
            
            // NFC status
            if let status = vm.nfc.statusMessage {
                Text(status)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.accent)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Theme.bg0.opacity(0.94))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Theme.border), alignment: .bottom)
    }
    
    // MARK: - About Panel
    private var aboutPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.gradient)
                Text("MeshLink v3.0.0")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.text1)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                featureRow(icon: "lock.fill", text: "AES-256-GCM end-to-end encryption")
                featureRow(icon: "point.3.connected.trianglepath.dotted", text: "Mesh relay — messages hop between peers")
                featureRow(icon: "wave.3.right", text: "NFC key sharing — tap to pair")
                featureRow(icon: "qrcode", text: "QR code key exchange")
                featureRow(icon: "photo", text: "Image sharing over Bluetooth")
                featureRow(icon: "bell.fill", text: "Background notifications")
                featureRow(icon: "arrow.triangle.2.circlepath", text: "Auto-reconnect to known peers")
            }
            
            Text("No servers • No internet • No third parties")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Theme.textMuted)
                .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bg0.opacity(0.94))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Theme.border), alignment: .bottom)
    }
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 10)).foregroundColor(Theme.accent)
                .frame(width: 16)
            Text(text).font(.system(size: 11)).foregroundColor(Theme.text2)
        }
    }
    
    // MARK: - Settings Panel
    private var settingsPanel: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ENCRYPTION KEY")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.accent)
                    .tracking(1.5)
                
                HStack(spacing: 4) {
                    Group {
                        if vm.showKey {
                            TextField("Key", text: $vm.encryptionKey)
                        } else {
                            SecureField("Key", text: $vm.encryptionKey)
                        }
                    }
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Theme.text1)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    
                    Button { vm.showKey.toggle() } label: {
                        Image(systemName: vm.showKey ? "eye.slash" : "eye")
                            .font(.system(size: 11)).foregroundColor(Theme.text2)
                    }
                    Button(action: vm.copyKey) {
                        Image(systemName: vm.keyCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11))
                            .foregroundColor(vm.keyCopied ? Theme.accent : Theme.text2)
                    }
                }
                .padding(10)
                .background(Theme.bg0)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border))
            }
            
            HStack(spacing: 8) {
                settingsBtn(icon: vm.encryptionEnabled ? "lock.fill" : "lock.open",
                           label: vm.encryptionEnabled ? "AES-GCM" : "Off",
                           active: vm.encryptionEnabled,
                           color: vm.encryptionEnabled ? Theme.accent : Theme.danger) {
                    vm.encryptionEnabled.toggle()
                    vm.addLog("Encryption \(vm.encryptionEnabled ? "on" : "off")", .info)
                }
                
                settingsBtn(icon: vm.soundEnabled ? "speaker.wave.2" : "speaker.slash",
                           label: vm.soundEnabled ? "Sound" : "Muted",
                           active: vm.soundEnabled,
                           color: vm.soundEnabled ? Theme.accent : Theme.textMuted) {
                    vm.soundEnabled.toggle()
                    vm.sound.enabled = vm.soundEnabled
                }
                
                settingsBtn(icon: vm.ble.showMeshLinkOnly ? "antenna.radiowaves.left.and.right" : "wifi",
                           label: vm.ble.showMeshLinkOnly ? "Mesh" : "All",
                           active: vm.ble.showMeshLinkOnly,
                           color: Theme.accentBlue) {
                    vm.ble.showMeshLinkOnly.toggle()
                }
            }
            
            // Leave mesh button
            Button(action: vm.leaveMesh) {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.portrait.and.arrow.right").font(.system(size: 11))
                    Text("Leave Mesh").font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
                .foregroundColor(Theme.danger)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Theme.danger.opacity(0.08))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.danger.opacity(0.2)))
            }
        }
        .padding(14)
        .background(Theme.bg0.opacity(0.92))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Theme.border), alignment: .bottom)
    }
    
    private func settingsBtn(icon: String, label: String, active: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 11))
                Text(label).font(.system(size: 11, weight: .semibold, design: .monospaced))
            }
            .foregroundColor(color)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(color.opacity(0.08))
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(active ? color.opacity(0.2) : Theme.border))
        }
    }
    
    // MARK: - Tab Bar
    private var tabBar: some View {
        HStack(spacing: 4) {
            tabBtn(icon: "bubble.left.fill", label: "Chat", tab: .chat, badge: vm.activeTab != .chat ? vm.unreadCount : 0)
            tabBtn(icon: "person.2.fill", label: "Peers", tab: .peers, badge: vm.ble.connectedCount)
            tabBtn(icon: "terminal.fill", label: "Logs", tab: .logs, badge: 0)
        }
        .padding(.horizontal, 14).padding(.vertical, 6)
        .background(Theme.bg0.opacity(0.5))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.03)), alignment: .bottom)
    }
    
    private func tabBtn(icon: String, label: String, tab: MeshViewModel.AppTab, badge: Int) -> some View {
        Button {
            vm.activeTab = tab
            if tab == .chat { vm.unreadCount = 0; vm.notifications.clearBadge() }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: icon).font(.system(size: 11))
                Text(label.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .tracking(0.5)
            }
            .foregroundColor(vm.activeTab == tab ? Theme.accent : Theme.textMuted)
            .padding(.horizontal, 16).padding(.vertical, 7)
            .background(vm.activeTab == tab ? Theme.accent.opacity(0.15) : Color.clear)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(vm.activeTab == tab ? Theme.borderAccent : Color.clear))
            .overlay(alignment: .topTrailing) {
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.bg0)
                        .frame(width: 16, height: 16)
                        .background(Theme.accent)
                        .clipShape(Circle())
                        .offset(x: 4, y: -4)
                }
            }
        }
    }
}
