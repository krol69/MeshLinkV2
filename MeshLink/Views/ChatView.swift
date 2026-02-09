import SwiftUI
import PhotosUI

struct ChatView: View {
    @EnvironmentObject var vm: MeshViewModel
    @FocusState private var inputFocused: Bool
    @State private var showImagePicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat header
            HStack {
                Text("\(vm.messages.count) message\(vm.messages.count == 1 ? "" : "s")")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
                
                Spacer()
                
                if !vm.messages.isEmpty {
                    Button(action: vm.clearChat) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash").font(.system(size: 10))
                            Text("Clear").font(.system(size: 10, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(Theme.text2)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border))
                    }
                }
            }
            .padding(.horizontal, 18).padding(.vertical, 6)
            .background(Theme.bg0.opacity(0.4))
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.02)), alignment: .bottom)
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 6) {
                        if vm.messages.isEmpty {
                            emptyState
                        } else {
                            ForEach(vm.messages) { msg in
                                MessageBubbleView(message: msg).id(msg.id)
                            }
                        }
                        
                        ForEach(Array(vm.typingPeers), id: \.self) { name in
                            TypingView(name: name)
                        }
                        
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal, 18).padding(.vertical, 14)
                }
                .onChange(of: vm.messages.count) { _ in
                    withAnimation { proxy.scrollTo("bottom") }
                }
                .onChange(of: vm.typingPeers) { _ in
                    withAnimation { proxy.scrollTo("bottom") }
                }
            }
            
            inputBar
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 40))
                .foregroundStyle(Theme.gradient)
            Text("No messages yet")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.text2)
            Text("Connect to a peer in the Peers tab, then start chatting.")
                .font(.system(size: 12))
                .foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
            
            if !vm.demoLoaded {
                Button(action: vm.loadDemo) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill").font(.system(size: 10))
                        Text("Load Demo")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    }
                    .foregroundColor(Theme.accent)
                    .padding(.horizontal, 24).padding(.vertical, 10)
                    .background(Theme.surface)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.borderAccent))
                }
            }
        }
    }
    
    // MARK: - Input Bar
    private var inputBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                // Image picker
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: "photo")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.text2)
                        .frame(width: 36, height: 36)
                        .background(Theme.surface)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border))
                }
                .onChange(of: selectedPhoto) { newItem in
                    guard let item = newItem else { return }
                    item.loadTransferable(type: Data.self) { result in
                        if case .success(let data) = result, let data = data, let img = UIImage(data: data) {
                            DispatchQueue.main.async { vm.sendImage(img) }
                        }
                    }
                    selectedPhoto = nil
                }
                
                TextField(
                    vm.ble.connectedCount > 0 ? "Message..." : "Connect peers first...",
                    text: $vm.inputText
                )
                .font(.system(size: 14))
                .foregroundColor(Theme.text1)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Theme.surface)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(inputFocused ? Theme.borderAccent : Theme.border))
                .focused($inputFocused)
                .submitLabel(.send)
                .onSubmit { vm.sendMessage() }
                .onChange(of: vm.inputText) { _ in vm.onInputChanged() }
                
                Button(action: vm.sendMessage) {
                    sendButtonContent
                }
                .disabled(vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            
            // Status bar
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: vm.encryptionEnabled ? "lock.fill" : "lock.open")
                        .font(.system(size: 9))
                        .foregroundColor(vm.encryptionEnabled ? Theme.accent : Theme.danger)
                    Text(vm.encryptionEnabled ? "AES-256-GCM" : "Unencrypted")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(vm.encryptionEnabled ? Theme.accent.opacity(0.5) : Theme.danger.opacity(0.5))
                }
                Spacer()
                Text("\(vm.ble.connectedCount) peer\(vm.ble.connectedCount == 1 ? "" : "s") • Mesh relay on")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(.ultraThinMaterial.opacity(0.3))
        .background(Theme.bg0.opacity(0.88))
    }
    
    @ViewBuilder
    private var sendButtonContent: some View {
        let isEmpty = vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty
        Image(systemName: "arrow.up")
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(isEmpty ? Theme.textMuted : Theme.bg0)
            .frame(width: 44, height: 44)
            .background(Group {
                if isEmpty { Theme.surface } else { Theme.gradient }
            })
            .cornerRadius(12)
            .overlay(Group {
                if isEmpty { RoundedRectangle(cornerRadius: 12).stroke(Theme.border) }
            })
    }
}

// MARK: - Message Bubble
struct MessageBubbleView: View {
    let message: ChatMessage
    @State private var showFullImage = false
    
    private var ownCorners: UIRectCorner { [.topLeft, .topRight, .bottomLeft] }
    private var otherCorners: UIRectCorner { [.topLeft, .topRight, .bottomRight] }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !message.isOwn {
                Text(String(message.sender.prefix(1)).uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.bg0)
                    .frame(width: 30, height: 30)
                    .background(LinearGradient(
                        colors: [message.sender.meshColor, (message.sender + "x").meshColor],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .cornerRadius(8)
            }
            
            if message.isOwn { Spacer(minLength: 50) }
            
            VStack(alignment: message.isOwn ? .trailing : .leading, spacing: 3) {
                if !message.isOwn {
                    Text(message.sender)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(message.sender.meshColor)
                }
                
                // Image display
                if message.hasImage, let img = message.uiImage {
                    Button { showFullImage = true } label: {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 200, maxHeight: 200)
                            .cornerRadius(8)
                    }
                    .sheet(isPresented: $showFullImage) {
                        ZStack {
                            Color.black.ignoresSafeArea()
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .padding()
                        }
                        .onTapGesture { showFullImage = false }
                    }
                }
                
                if !message.text.isEmpty && message.text != "📷 Image" {
                    Text(message.text)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.text1)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                HStack(spacing: 5) {
                    Text(message.timeString)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                    if message.encrypted {
                        Image(systemName: "lock.fill").font(.system(size: 8)).foregroundColor(Theme.accent)
                    }
                    Text(message.method)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(Theme.accent.opacity(0.35))
                    if message.isOwn {
                        Image(systemName: message.delivered ? "checkmark.circle.fill" : "checkmark")
                            .font(.system(size: 9))
                            .foregroundColor(message.delivered ? Theme.accent : Theme.textMuted)
                    }
                }
            }
            .padding(12)
            .background(bubbleBg)
            .cornerRadius(12, corners: message.isOwn ? ownCorners : otherCorners)
            .overlay(
                RoundedCorner(radius: 12, corners: message.isOwn ? ownCorners : otherCorners)
                    .stroke(message.isOwn ? Theme.borderAccent : Theme.border)
            )
            
            if !message.isOwn { Spacer(minLength: 50) }
        }
        .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
    }
    
    @ViewBuilder
    private var bubbleBg: some View {
        if message.isOwn {
            LinearGradient(colors: [Theme.accent.opacity(0.12), Theme.accentBlue.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            Theme.surface
        }
    }
}

// MARK: - Typing
struct TypingView: View {
    let name: String
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 8) {
            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.bg0)
                .frame(width: 30, height: 30)
                .background(name.meshColor)
                .cornerRadius(8)
            
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle().fill(Theme.text2).frame(width: 6, height: 6)
                        .offset(y: animating ? -4 : 0)
                        .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15), value: animating)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Theme.surface)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border))
            Spacer()
        }
        .onAppear { animating = true }
    }
}

// MARK: - Corner Helper
struct RoundedCorner: Shape {
    var radius: CGFloat; var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius)).cgPath)
    }
}
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
