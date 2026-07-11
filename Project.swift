import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "TripPalette",
    organizationName: "ilyailyaovch",
    options: .options(
        automaticSchemesOptions: .disabled,
        defaultKnownRegions: ["en", "Base"],
        developmentRegion: "en"
    ),
    packages: [
        .remote(
            url: "https://github.com/Finalet/Elegant-Emoji-Picker",
            requirement: .branch("main")
        ),
    ],
    settings: TripPaletteSettings.project,
    targets: TripPaletteTargets.all,
    schemes: TripPaletteSchemes.all
)
