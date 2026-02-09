# MeshLink v3.0

**Encrypted peer-to-peer Bluetooth mesh messaging for iOS**

No servers. No internet. No third parties. Just Bluetooth.

## Features

- **AES-256-GCM Encryption** — PBKDF2-SHA256 key derivation (100k iterations)
- **Mesh Relay** — Messages hop through intermediate nodes (TTL-based)
- **NFC Key Sharing** — Write encryption key to NFC tag, tap to pair devices
- **QR Code Exchange** — Show/scan QR code to share encryption keys
- **Image Sharing** — Send compressed photos over BLE
- **Auto-Reconnect** — Automatically reconnects to known peers
- **Background Bluetooth** — State restoration keeps connections alive
- **Local Notifications** — Get notified of new messages when backgrounded
- **MeshLink Device Detection** — Filters and highlights MeshLink peers
- **Multi-Peer Broadcast** — Connect to multiple devices simultaneously
- **Typing Indicators** — See when peers are typing
- **Delivery Confirmations** — Sent ✓ and Delivered ✓✓
- **Message Persistence** — Last 300 messages saved locally
- **Chunked Messaging** — Large messages split with sequence-based reassembly

## Building

This project uses GitHub Actions to build. Push to `main` and the IPA will be available as an artifact.

### Requirements
- GitHub account (free)
- Signulous or similar sideloading service for installation

### File Structure
```
MeshLink/
├── MeshLinkApp.swift          # App entry + Theme
├── Info.plist                 # Permissions (BLE, NFC, Photos)
├── MeshLink.entitlements      # NFC entitlement
├── Models/
│   └── Models.swift           # Data models + wire protocol v3
├── Services/
│   ├── BLEService.swift       # Core Bluetooth (central + peripheral)
│   ├── CryptoService.swift    # AES-256-GCM encryption
│   ├── MeshViewModel.swift    # App logic + state management
│   ├── NFCService.swift       # NFC read/write for key sharing
│   ├── NotificationService.swift  # Local push notifications
│   └── SoundService.swift     # Audio feedback
└── Views/
    ├── SetupView.swift        # Join mesh screen
    ├── MainView.swift         # Header, tabs, settings, QR/NFC panel
    ├── ChatView.swift         # Messages + image sending
    ├── PeersView.swift        # Device scanning + connection
    └── LogsView.swift         # System event log
```

## How It Works

1. Both devices open MeshLink and enter the same encryption key (or share via NFC/QR)
2. Scan and connect to nearby Bluetooth devices
3. Messages are AES-256-GCM encrypted before Bluetooth transmission
4. Connected peers relay messages to extend range (mesh networking)
5. All data stays local — zero internet involvement
