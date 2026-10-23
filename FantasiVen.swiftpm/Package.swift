// swift-tools-version: 6.0
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "FantasiVen",
    defaultLocalization: "da",
    platforms: [.iOS("15.0")],
    products: [
        .iOSApplication(
            name: "FantasiVen",
            targets: ["AppModule"],
            bundleIdentifier: "dk.fantasiven.app",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .asset("AppIcon"),
            accentColor: .presetColor(.purple),
            supportedDeviceFamilies: [.phone, .pad],
            supportedInterfaceOrientations: [.portrait, .portraitUpsideDown, .landscapeLeft, .landscapeRight]
        )
    ],
    targets: [
        .executableTarget(name: "AppModule", path: ".", resources: [.process("Resources")])
    ],
    swiftLanguageModes: [.v6]
)
