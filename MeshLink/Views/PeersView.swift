import SwiftUI

struct PeersView: View {
    @EnvironmentObject var vm: MeshViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Scan Button
                Button(action: {
                    if vm.isScanning { vm.stopScan() } else { vm.startScan() }
                }) {
                    HStack(spacing: 10) {
                        if vm.isScanning {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Theme.accent))
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "bluetooth")
                                .font(.system(size: 15))
                        }
                        Text(vm.isScanning ? "SCANNING..." : "SCAN FOR DEVICES")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .tracking(0.5)
                    }
                    .foregroundColor(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(scanBtnBg)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.borderAccent))
                }
                .padding(.horizontal, 18).padding(.top, 18)
                
                // Filter toggle
                HStack {
                    let meshCount = vm.ble.peers.filter(\.isMeshLink).count
                    Text("DEVICES (\(vm.ble.filteredPeers.count))")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                        .tracking(1.5)
                    
                    if meshCount > 0 {
                        Text("• \(meshCount) MeshLink")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Theme.accent)
                    }
                    
                    Spacer()
                    
                    Button {
                        vm.ble.showMeshLinkOnly.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: vm.ble.showMeshLinkOnly ? "antenna.radiowaves.left.and.right" : "wifi")
                                .font(.system(size: 10))
                            Text(vm.ble.showMeshLinkOnly ? "Mesh" : "All")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(vm.ble.showMeshLinkOnly ? Theme.accent : Theme.textMuted)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(vm.ble.showMeshLinkOnly ? Theme.accent.opacity(0.1) : Theme.surface)
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(vm.ble.showMeshLinkOnly ? Theme.borderAccent : Theme.border))
                    }
                }
                .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 10)
                
                // Bluetooth warning
                if !vm.bluetoothReady {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle").font(.system(size: 12)).foregroundColor(Theme.warning)
                        Text("Bluetooth is off. Enable in Settings > Bluetooth.")
                            .font(.system(size: 11, design: .monospaced)).foregroundColor(Theme.warning.opacity(0.7))
                    }
                    .padding(14)
                    .background(Theme.warning.opacity(0.05)).cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.warning.opacity(0.12)))
                    .padding(.horizontal, 18).padding(.bottom, 16)
                }
                
                // Peer list
                if vm.ble.filteredPeers.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(vm.ble.filteredPeers) { peer in
                            PeerCardView(peer: peer, nickname: vm.displayName(for: peer),
                                        onConnect: { vm.connectPeer(peer) },
                                        onDisconnect: { vm.disconnectPeer(peer) })
                        }
                    }
                    .padding(.horizontal, 18)
                }
                
                howItWorksCard
                    .padding(.horizontal, 18).padding(.top, 24).padding(.bottom, 30)
            }
        }
    }
    
    @ViewBuilder
    private var scanBtnBg: some View {
        if vm.isScanning {
            Theme.accent.opacity(0.04)
        } else {
            LinearGradient(colors: [Theme.accent.opacity(0.1), Theme.accentBlue.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass").font(.system(size: 36)).foregroundColor(Color.white.opacity(0.1)).padding(.top, 20)
            Text("No devices found").font(.system(size: 13)).foregroundColor(Theme.textMuted)
            Text("Tap Scan to find nearby Bluetooth devices.").font(.system(size: 12)).foregroundColor(Theme.textMuted).multilineTextAlignment(.center).frame(maxWidth: 260)
        }
        .padding(.vertical, 20)
    }
    
    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle").font(.system(size: 12)).foregroundColor(Theme.purple.opacity(0.7))
                Text("HOW MESHLINK WORKS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.purple.opacity(0.8)).tracking(1)
            }
            VStack(alignment: .leading, spacing: 8) {
                infoRow(n: "1", t: "Share key via NFC tag, QR code, or type on both devices")
                infoRow(n: "2", t: "Scan and connect to nearby MeshLink peers")
                infoRow(n: "3", t: "Messages are AES-256 encrypted end-to-end")
                infoRow(n: "4", t: "Mesh relay forwards messages through intermediate nodes")
                infoRow(n: "5", t: "Send text and images — all over Bluetooth, no internet")
            }
        }
        .padding(16).background(Theme.purple.opacity(0.04)).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.purple.opacity(0.1)))
    }
    
    private func infoRow(n: String, t: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(n).font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.purple.opacity(0.5))
                .frame(width: 16, height: 16)
                .background(Theme.purple.opacity(0.1)).cornerRadius(4)
            Text(t).font(.system(size: 12)).foregroundColor(Color.white.opacity(0.4)).lineSpacing(2)
        }
    }
}

// MARK: - Peer Card
struct PeerCardView: View {
    let peer: BLEPeer
    let nickname: String
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Text(String(nickname.prefix(1)).uppercased())
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Theme.bg0)
                .frame(width: 38, height: 38)
                .background(LinearGradient(
                    colors: [peer.name.meshColor, peer.id.meshColor],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(nickname)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.text1)
                    
                    if peer.isMeshLink {
                        Text("MESH")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.accent)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Theme.accent.opacity(0.12))
                            .cornerRadius(3)
                    }
                }
                
                HStack(spacing: 8) {
                    Text(String(peer.id.prefix(12)) + "...")
                        .font(.system(size: 9, design: .monospaced)).foregroundColor(Theme.textMuted)
                    
                    HStack(spacing: 2) {
                        signalBars(rssi: peer.rssi)
                        Text("\(peer.rssi)dBm")
                            .font(.system(size: 9, design: .monospaced)).foregroundColor(Theme.textMuted)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Circle()
                    .fill(peer.connected ? Theme.accent : Theme.danger)
                    .frame(width: 8, height: 8)
                    .shadow(color: peer.connected ? Theme.accent : Theme.danger, radius: 3)
                
                if peer.connected {
                    Button(action: onDisconnect) {
                        Image(systemName: "wifi.slash").font(.system(size: 12)).foregroundColor(Theme.danger)
                            .frame(width: 28, height: 28)
                            .background(Theme.danger.opacity(0.08)).cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.danger.opacity(0.2)))
                    }
                } else {
                    Button(action: onConnect) {
                        Image(systemName: "bluetooth").font(.system(size: 12)).foregroundColor(Theme.accent)
                            .frame(width: 28, height: 28)
                            .background(Theme.accent.opacity(0.15)).cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.borderAccent))
                    }
                }
            }
        }
        .padding(12).background(Theme.surface).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(peer.isMeshLink ? Theme.borderAccent : Theme.border))
    }
    
    @ViewBuilder
    private func signalBars(rssi: Int) -> some View {
        HStack(spacing: 1.5) {
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(rssi > [-85, -70, -55, -40][i] ? Theme.accent : Theme.textMuted.opacity(0.3))
                    .frame(width: 3, height: CGFloat(4 + i * 3))
            }
        }
        .frame(height: 14, alignment: .bottom)
    }
}
