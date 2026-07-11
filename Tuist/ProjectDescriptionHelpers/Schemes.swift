import ProjectDescription

public enum TripPaletteSchemes {
    public static let all: [Scheme] = [
        .scheme(
            name: "TripPalette",
            shared: true,
            buildAction: .buildAction(targets: ["TripPalette"]),
            runAction: .runAction(configuration: "Debug", executable: "TripPalette"),
            archiveAction: .archiveAction(configuration: "Release")
        ),
    ]
}
