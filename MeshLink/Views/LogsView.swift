import SwiftUI

struct LogsView: View {
    @EnvironmentObject var vm: MeshViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(vm.logs.count) events")
                    .font(.system(size: 10, design: .monospaced)).foregroundColor(Theme.textMuted)
                Spacer()
                Button {
                    vm.logs.removeAll()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash").font(.system(size: 10))
                        Text("Clear").font(.system(size: 10, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(Theme.text2)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border))
                }
            }
            .padding(.horizontal, 18).padding(.vertical, 6)
            .background(Theme.bg0.opacity(0.4))
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.02)), alignment: .bottom)
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 3) {
                        ForEach(vm.logs) { log in
                            HStack(alignment: .top, spacing: 8) {
                                Text(log.timeString)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(Theme.textMuted)
                                    .frame(width: 60, alignment: .leading)
                                
                                Circle()
                                    .fill(logColor(log.level))
                                    .frame(width: 5, height: 5)
                                    .padding(.top, 4)
                                
                                Text(log.text)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(logColor(log.level).opacity(0.8))
                                    .lineSpacing(2)
                            }
                            .id(log.id)
                        }
                    }
                    .padding(14)
                }
                .onChange(of: vm.logs.count) { _ in
                    if let last = vm.logs.last {
                        withAnimation { proxy.scrollTo(last.id) }
                    }
                }
            }
        }
    }
    
    private func logColor(_ level: LogEntry.LogLevel) -> Color {
        switch level {
        case .info: return Theme.text2
        case .success: return Theme.accent
        case .warning: return Theme.warning
        case .error: return Theme.danger
        case .data: return Theme.accentBlue
        }
    }
}
