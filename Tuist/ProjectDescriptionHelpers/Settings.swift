import ProjectDescription

public enum TripPaletteSettings {
    public static let project = Settings.settings(
        configurations: [
            .debug(name: "Debug", xcconfig: .relativeToRoot("Tuist/Configs/Project.xcconfig")),
            .release(name: "Release", xcconfig: .relativeToRoot("Tuist/Configs/Project.xcconfig")),
        ]
    )

    public static func target(_ xcconfig: Path) -> Settings {
        .settings(
            configurations: [
                .debug(name: "Debug", xcconfig: xcconfig),
                .release(name: "Release", xcconfig: xcconfig),
            ]
        )
    }
}
