# i2i iOS

## Requirements

- Xcode 15+
- iOS 17+ device or simulator
- [xcodegen](https://github.com/yonaskolb/XcodeGen)

## Setup

```bash
brew install xcodegen
cd ios
xcodegen generate
open i2i.xcodeproj
```

## Structure

```
i2i/
├── App/            Entry point and root navigation
├── Features/       Feature modules (Identity, Pairing, Peers, Messaging)
├── Core/
│   ├── Models/     Data models
│   ├── Storage/    Repository protocols and implementations
│   ├── Transport/  Transport abstraction
│   └── Security/   Keychain access
└── UI/Shared/      Shared UI components
```
