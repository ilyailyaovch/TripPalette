import ProjectDescription

public enum TripPaletteTargets {
    public static let all: [Target] = [
        app,
    ]

    public static let app = Target.target(
        name: "TripPalette",
        destinations: [.iPhone, .iPad],
        product: .app,
        bundleId: "ilyailyaovch.TripPalette",
        deploymentTargets: .iOS("26.0"),
        infoPlist: .extendingDefault(
            with: [
                "UILaunchScreen": [:],
                "UISupportedInterfaceOrientations": [
                    "UIInterfaceOrientationPortrait",
                    "UIInterfaceOrientationLandscapeLeft",
                    "UIInterfaceOrientationLandscapeRight",
                ],
                "UISupportedInterfaceOrientations~ipad": [
                    "UIInterfaceOrientationPortrait",
                    "UIInterfaceOrientationPortraitUpsideDown",
                    "UIInterfaceOrientationLandscapeLeft",
                    "UIInterfaceOrientationLandscapeRight",
                ],
            ]
        ),
        sources: [
            "TripPalette/App/**",
            "TripPalette/Core/**",
            "TripPalette/Screens/**",
            "TripPalette/Services/**",
        ],
        resources: ["TripPalette/Resources/**"],
        dependencies: [
            .package(product: "ElegantEmojiPicker"),
        ],
        settings: TripPaletteSettings.target(
            .relativeToRoot("Tuist/Configs/TripPalette.xcconfig")
        )
    )
}
