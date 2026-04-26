import SwiftUI

enum SkinID: String, CaseIterable, Identifiable, Codable {
    case `default` = "default"
    case paperInk = "paper-ink"
    case frostglass = "frostglass"
    case velvetNoir = "velvet-noir"
    case jadePorcelain = "jade-porcelain"
    case emberLacquer = "ember-lacquer"
    case sapphireClub = "sapphire-club"

    var id: String { rawValue }
}

struct Skin: Identifiable {
    let id: SkinID
    let name: String
    let summary: String
    let price: Int
    let systemImage: String
    let palette: AureliaSkinPalette

    static let `default` = Skin(
        id: .default,
        name: "Aurelia Classic",
        summary: "The original luxe salon palette with warm gold, ruby, and emerald highlights.",
        price: 0,
        systemImage: "crown.fill",
        palette: .default
    )

    static let paperInk = Skin(
        id: .paperInk,
        name: "Paper & Ink",
        summary: "A bright broadsheet look with ivory paper, charcoal ink, and brass press accents.",
        price: 120,
        systemImage: "doc.richtext.fill",
        palette: .paperInk
    )

    static let frostglass = Skin(
        id: .frostglass,
        name: "Frostglass",
        summary: "An arctic neon treatment with deep navy glass, cyan glow, and frozen chrome highlights.",
        price: 180,
        systemImage: "snowflake",
        palette: .frostglass
    )

    static let velvetNoir = Skin(
        id: .velvetNoir,
        name: "Velvet Noir",
        summary: "A black-plum evening palette with rose-gold light, smoky mauve tiles, and gallery-depth shadows.",
        price: 165,
        systemImage: "moon.stars.fill",
        palette: .velvetNoir
    )

    static let jadePorcelain = Skin(
        id: .jadePorcelain,
        name: "Jade Porcelain",
        summary: "A bright porcelain finish with lacquered jade accents, deep ink borders, and refined spa calm.",
        price: 150,
        systemImage: "leaf.fill",
        palette: .jadePorcelain
    )

    static let emberLacquer = Skin(
        id: .emberLacquer,
        name: "Ember Lacquer",
        summary: "A rich oxblood and espresso treatment with burnished amber highlights and high-contrast tile edges.",
        price: 195,
        systemImage: "flame.fill",
        palette: .emberLacquer
    )

    static let sapphireClub = Skin(
        id: .sapphireClub,
        name: "Sapphire Club",
        summary: "A tailored midnight blue palette with ivory text, champagne trims, and crisp club-room separation.",
        price: 175,
        systemImage: "sparkles",
        palette: .sapphireClub
    )

    static let catalog: [Skin] = [
        .default,
        .paperInk,
        .frostglass,
        .velvetNoir,
        .jadePorcelain,
        .emberLacquer,
        .sapphireClub
    ]
}

struct AureliaSkinPalette {
    let ink: Color
    let obsidian: Color
    let parchment: Color
    let champagne: Color
    let secondaryText: Color
    let tertiaryText: Color
    let bronze: Color
    let apricot: Color
    let copper: Color
    let ruby: Color
    let emerald: Color
    let mint: Color
    let sky: Color
    let cobalt: Color
    let slate: Color
    let charcoal: Color
    let panel: Color
    let panelDeep: Color
    let background: LinearGradient
    let hero: LinearGradient
    let sheetBackground: LinearGradient
    let unknownTile: Color
    let absentTile: Color
    let unknownTileBorder: Color
    let activeTileBorder: Color
    let unknownKeyFill: Color
    let absentKeyGradient: [Color]
    let unknownKeyText: Color
    let coinCapsuleFill: Color
    let coinCapsuleStroke: Color
    let actionText: Color
    let selectedGlow: Color

    let presentGradient: [Color]
    let correctGradient: [Color]
    let colorBlindPresentGradient: [Color]
    let colorBlindCorrectGradient: [Color]

    static let `default` = AureliaSkinPalette(
        ink: Color(red: 0.05, green: 0.045, blue: 0.04),
        obsidian: Color(red: 0.09, green: 0.08, blue: 0.07),
        parchment: Color(red: 0.94, green: 0.86, blue: 0.72),
        champagne: Color(red: 0.92, green: 0.72, blue: 0.43),
        secondaryText: Color.white,
        tertiaryText: Color(red: 0.94, green: 0.86, blue: 0.72),
        bronze: Color(red: 0.56, green: 0.36, blue: 0.18),
        apricot: Color(red: 0.92, green: 0.56, blue: 0.24),
        copper: Color(red: 0.72, green: 0.34, blue: 0.10),
        ruby: Color(red: 0.64, green: 0.15, blue: 0.18),
        emerald: Color(red: 0.14, green: 0.50, blue: 0.34),
        mint: Color(red: 0.31, green: 0.72, blue: 0.52),
        sky: Color(red: 0.36, green: 0.70, blue: 0.96),
        cobalt: Color(red: 0.14, green: 0.42, blue: 0.86),
        slate: Color(red: 0.29, green: 0.31, blue: 0.32),
        charcoal: Color(red: 0.15, green: 0.14, blue: 0.13),
        panel: Color.white.opacity(0.08),
        panelDeep: Color(red: 0.16, green: 0.145, blue: 0.13),
        background: LinearGradient(
            colors: [Color(red: 0.03, green: 0.028, blue: 0.025), Color(red: 0.12, green: 0.095, blue: 0.07), Color(red: 0.04, green: 0.035, blue: 0.03)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        hero: LinearGradient(
            colors: [Color(red: 0.92, green: 0.72, blue: 0.43), Color(red: 0.94, green: 0.86, blue: 0.72), Color(red: 0.74, green: 0.47, blue: 0.22)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        sheetBackground: LinearGradient(
            colors: [Color(red: 0.08, green: 0.065, blue: 0.055), Color(red: 0.13, green: 0.10, blue: 0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        unknownTile: Color(red: 0.16, green: 0.145, blue: 0.13),
        absentTile: Color(red: 0.15, green: 0.14, blue: 0.13),
        unknownTileBorder: Color(red: 0.92, green: 0.72, blue: 0.43).opacity(0.78),
        activeTileBorder: Color(red: 0.92, green: 0.72, blue: 0.43).opacity(0.9),
        unknownKeyFill: Color(red: 0.16, green: 0.145, blue: 0.13).opacity(0.78),
        absentKeyGradient: [
            Color(red: 0.58, green: 0.19, blue: 0.22),
            Color(red: 0.46, green: 0.13, blue: 0.16),
            Color(red: 0.24, green: 0.07, blue: 0.09)
        ],
        unknownKeyText: Color(red: 0.94, green: 0.86, blue: 0.72),
        coinCapsuleFill: .black.opacity(0.28),
        coinCapsuleStroke: Color(red: 1.0, green: 0.84, blue: 0.32).opacity(0.4),
        actionText: Color(red: 0.05, green: 0.045, blue: 0.04),
        selectedGlow: Color(red: 0.92, green: 0.72, blue: 0.43),
        presentGradient: [Color(red: 0.92, green: 0.72, blue: 0.43), Color(red: 0.56, green: 0.36, blue: 0.18)],
        correctGradient: [Color(red: 0.31, green: 0.72, blue: 0.52), Color(red: 0.14, green: 0.50, blue: 0.34)],
        colorBlindPresentGradient: [Color(red: 0.92, green: 0.56, blue: 0.24), Color(red: 0.72, green: 0.34, blue: 0.10)],
        colorBlindCorrectGradient: [Color(red: 0.36, green: 0.70, blue: 0.96), Color(red: 0.14, green: 0.42, blue: 0.86)]
    )

    static let paperInk = AureliaSkinPalette(
        ink: Color(red: 0.11, green: 0.10, blue: 0.09),
        obsidian: Color(red: 0.20, green: 0.17, blue: 0.14),
        parchment: Color(red: 0.22, green: 0.18, blue: 0.14),
        champagne: Color(red: 0.55, green: 0.40, blue: 0.21),
        secondaryText: Color(red: 0.28, green: 0.24, blue: 0.20),
        tertiaryText: Color(red: 0.39, green: 0.33, blue: 0.27),
        bronze: Color(red: 0.55, green: 0.39, blue: 0.20),
        apricot: Color(red: 0.83, green: 0.47, blue: 0.22),
        copper: Color(red: 0.65, green: 0.33, blue: 0.16),
        ruby: Color(red: 0.44, green: 0.21, blue: 0.18),
        emerald: Color(red: 0.23, green: 0.33, blue: 0.24),
        mint: Color(red: 0.63, green: 0.71, blue: 0.59),
        sky: Color(red: 0.59, green: 0.71, blue: 0.81),
        cobalt: Color(red: 0.26, green: 0.38, blue: 0.49),
        slate: Color(red: 0.46, green: 0.42, blue: 0.35),
        charcoal: Color(red: 0.18, green: 0.16, blue: 0.14),
        panel: Color(red: 0.92, green: 0.88, blue: 0.80).opacity(0.76),
        panelDeep: Color(red: 0.79, green: 0.73, blue: 0.63),
        background: LinearGradient(
            colors: [
                Color(red: 0.90, green: 0.86, blue: 0.78),
                Color(red: 0.82, green: 0.76, blue: 0.66),
                Color(red: 0.68, green: 0.59, blue: 0.46)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        hero: LinearGradient(
            colors: [
                Color(red: 0.24, green: 0.21, blue: 0.18),
                Color(red: 0.53, green: 0.42, blue: 0.29),
                Color(red: 0.88, green: 0.76, blue: 0.50)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        sheetBackground: LinearGradient(
            colors: [
                Color(red: 0.91, green: 0.87, blue: 0.80),
                Color(red: 0.81, green: 0.75, blue: 0.66)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        unknownTile: Color(red: 0.86, green: 0.81, blue: 0.72),
        absentTile: Color(red: 0.53, green: 0.48, blue: 0.41),
        unknownTileBorder: Color(red: 0.45, green: 0.31, blue: 0.16).opacity(0.82),
        activeTileBorder: Color(red: 0.63, green: 0.47, blue: 0.24),
        unknownKeyFill: Color(red: 0.84, green: 0.79, blue: 0.71).opacity(0.98),
        absentKeyGradient: [
            Color(red: 0.50, green: 0.43, blue: 0.37),
            Color(red: 0.37, green: 0.31, blue: 0.26),
            Color(red: 0.24, green: 0.20, blue: 0.17)
        ],
        unknownKeyText: Color(red: 0.17, green: 0.15, blue: 0.13),
        coinCapsuleFill: Color(red: 0.90, green: 0.86, blue: 0.79).opacity(0.92),
        coinCapsuleStroke: Color(red: 0.49, green: 0.35, blue: 0.18).opacity(0.42),
        actionText: Color(red: 0.99, green: 0.96, blue: 0.90),
        selectedGlow: Color(red: 0.66, green: 0.50, blue: 0.26),
        presentGradient: [Color(red: 0.90, green: 0.76, blue: 0.48), Color(red: 0.64, green: 0.46, blue: 0.24)],
        correctGradient: [Color(red: 0.46, green: 0.60, blue: 0.48), Color(red: 0.22, green: 0.31, blue: 0.24)],
        colorBlindPresentGradient: [Color(red: 0.86, green: 0.46, blue: 0.18), Color(red: 0.63, green: 0.29, blue: 0.12)],
        colorBlindCorrectGradient: [Color(red: 0.56, green: 0.71, blue: 0.82), Color(red: 0.23, green: 0.37, blue: 0.50)]
    )

    static let frostglass = AureliaSkinPalette(
        ink: Color(red: 0.03, green: 0.10, blue: 0.18),
        obsidian: Color(red: 0.05, green: 0.14, blue: 0.24),
        parchment: Color(red: 0.93, green: 0.99, blue: 1.0),
        champagne: Color(red: 0.62, green: 0.95, blue: 1.0),
        secondaryText: Color.white,
        tertiaryText: Color(red: 0.93, green: 0.99, blue: 1.0),
        bronze: Color(red: 0.20, green: 0.72, blue: 0.92),
        apricot: Color(red: 0.93, green: 0.63, blue: 0.33),
        copper: Color(red: 0.77, green: 0.37, blue: 0.23),
        ruby: Color(red: 0.36, green: 0.66, blue: 1.0),
        emerald: Color(red: 0.18, green: 0.93, blue: 0.87),
        mint: Color(red: 0.57, green: 1.0, blue: 0.96),
        sky: Color(red: 0.56, green: 0.90, blue: 1.0),
        cobalt: Color(red: 0.14, green: 0.47, blue: 0.94),
        slate: Color(red: 0.27, green: 0.43, blue: 0.60),
        charcoal: Color(red: 0.08, green: 0.20, blue: 0.31),
        panel: Color(red: 0.74, green: 0.96, blue: 1.0).opacity(0.20),
        panelDeep: Color(red: 0.11, green: 0.24, blue: 0.37),
        background: LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.08, blue: 0.16),
                Color(red: 0.05, green: 0.24, blue: 0.39),
                Color(red: 0.02, green: 0.13, blue: 0.27)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        hero: LinearGradient(
            colors: [
                Color(red: 0.84, green: 0.99, blue: 1.0),
                Color(red: 0.42, green: 0.92, blue: 1.0),
                Color(red: 0.18, green: 0.60, blue: 0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        sheetBackground: LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.17, blue: 0.29),
                Color(red: 0.11, green: 0.28, blue: 0.42)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        unknownTile: Color(red: 0.14, green: 0.28, blue: 0.41),
        absentTile: Color(red: 0.09, green: 0.17, blue: 0.26),
        unknownTileBorder: Color(red: 0.53, green: 0.95, blue: 1.0).opacity(0.92),
        activeTileBorder: Color(red: 0.78, green: 1.0, blue: 1.0),
        unknownKeyFill: Color(red: 0.13, green: 0.28, blue: 0.42).opacity(0.92),
        absentKeyGradient: [
            Color(red: 0.23, green: 0.42, blue: 0.56),
            Color(red: 0.14, green: 0.27, blue: 0.40),
            Color(red: 0.07, green: 0.15, blue: 0.25)
        ],
        unknownKeyText: Color(red: 0.91, green: 0.97, blue: 1.0),
        coinCapsuleFill: Color(red: 0.08, green: 0.14, blue: 0.20).opacity(0.42),
        coinCapsuleStroke: Color(red: 0.72, green: 0.98, blue: 1.0).opacity(0.58),
        actionText: Color(red: 0.04, green: 0.13, blue: 0.23),
        selectedGlow: Color(red: 0.49, green: 0.95, blue: 1.0),
        presentGradient: [Color(red: 0.78, green: 0.96, blue: 1.0), Color(red: 0.22, green: 0.71, blue: 0.94)],
        correctGradient: [Color(red: 0.56, green: 1.0, blue: 0.95), Color(red: 0.12, green: 0.84, blue: 0.78)],
        colorBlindPresentGradient: [Color(red: 0.95, green: 0.66, blue: 0.29), Color(red: 0.78, green: 0.37, blue: 0.18)],
        colorBlindCorrectGradient: [Color(red: 0.60, green: 0.91, blue: 1.0), Color(red: 0.16, green: 0.50, blue: 0.98)]
    )

    static let velvetNoir = AureliaSkinPalette(
        ink: Color(red: 0.07, green: 0.05, blue: 0.08),
        obsidian: Color(red: 0.11, green: 0.08, blue: 0.12),
        parchment: Color(red: 0.96, green: 0.89, blue: 0.90),
        champagne: Color(red: 0.90, green: 0.70, blue: 0.62),
        secondaryText: Color.white,
        tertiaryText: Color(red: 0.96, green: 0.89, blue: 0.90),
        bronze: Color(red: 0.67, green: 0.42, blue: 0.37),
        apricot: Color(red: 0.92, green: 0.57, blue: 0.38),
        copper: Color(red: 0.76, green: 0.36, blue: 0.28),
        ruby: Color(red: 0.62, green: 0.21, blue: 0.29),
        emerald: Color(red: 0.35, green: 0.55, blue: 0.44),
        mint: Color(red: 0.56, green: 0.76, blue: 0.67),
        sky: Color(red: 0.62, green: 0.72, blue: 0.92),
        cobalt: Color(red: 0.33, green: 0.40, blue: 0.74),
        slate: Color(red: 0.34, green: 0.28, blue: 0.36),
        charcoal: Color(red: 0.14, green: 0.10, blue: 0.16),
        panel: Color(red: 0.93, green: 0.83, blue: 0.88).opacity(0.10),
        panelDeep: Color(red: 0.18, green: 0.12, blue: 0.20),
        background: LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.03, blue: 0.07),
                Color(red: 0.16, green: 0.08, blue: 0.16),
                Color(red: 0.09, green: 0.05, blue: 0.11)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        hero: LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.88, blue: 0.90),
                Color(red: 0.86, green: 0.61, blue: 0.67),
                Color(red: 0.47, green: 0.20, blue: 0.31)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        sheetBackground: LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.06, blue: 0.12),
                Color(red: 0.18, green: 0.10, blue: 0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        unknownTile: Color(red: 0.23, green: 0.15, blue: 0.24),
        absentTile: Color(red: 0.17, green: 0.11, blue: 0.18),
        unknownTileBorder: Color(red: 0.94, green: 0.78, blue: 0.80).opacity(0.84),
        activeTileBorder: Color(red: 0.98, green: 0.84, blue: 0.80),
        unknownKeyFill: Color(red: 0.22, green: 0.15, blue: 0.24).opacity(0.94),
        absentKeyGradient: [
            Color(red: 0.47, green: 0.24, blue: 0.30),
            Color(red: 0.32, green: 0.16, blue: 0.22),
            Color(red: 0.18, green: 0.09, blue: 0.14)
        ],
        unknownKeyText: Color(red: 0.97, green: 0.90, blue: 0.92),
        coinCapsuleFill: Color(red: 0.11, green: 0.06, blue: 0.11).opacity(0.42),
        coinCapsuleStroke: Color(red: 0.98, green: 0.78, blue: 0.78).opacity(0.44),
        actionText: Color(red: 0.16, green: 0.08, blue: 0.13),
        selectedGlow: Color(red: 0.90, green: 0.64, blue: 0.69),
        presentGradient: [Color(red: 0.96, green: 0.80, blue: 0.68), Color(red: 0.72, green: 0.42, blue: 0.42)],
        correctGradient: [Color(red: 0.62, green: 0.82, blue: 0.72), Color(red: 0.29, green: 0.54, blue: 0.42)],
        colorBlindPresentGradient: [Color(red: 0.95, green: 0.61, blue: 0.37), Color(red: 0.77, green: 0.34, blue: 0.26)],
        colorBlindCorrectGradient: [Color(red: 0.69, green: 0.82, blue: 1.0), Color(red: 0.39, green: 0.50, blue: 0.84)]
    )

    static let jadePorcelain = AureliaSkinPalette(
        ink: Color(red: 0.09, green: 0.13, blue: 0.11),
        obsidian: Color(red: 0.16, green: 0.21, blue: 0.18),
        parchment: Color(red: 0.14, green: 0.23, blue: 0.19),
        champagne: Color(red: 0.24, green: 0.45, blue: 0.37),
        secondaryText: Color(red: 0.22, green: 0.31, blue: 0.28),
        tertiaryText: Color(red: 0.32, green: 0.41, blue: 0.37),
        bronze: Color(red: 0.38, green: 0.57, blue: 0.46),
        apricot: Color(red: 0.91, green: 0.66, blue: 0.42),
        copper: Color(red: 0.73, green: 0.42, blue: 0.23),
        ruby: Color(red: 0.53, green: 0.27, blue: 0.23),
        emerald: Color(red: 0.18, green: 0.50, blue: 0.39),
        mint: Color(red: 0.55, green: 0.77, blue: 0.68),
        sky: Color(red: 0.58, green: 0.75, blue: 0.84),
        cobalt: Color(red: 0.27, green: 0.49, blue: 0.57),
        slate: Color(red: 0.53, green: 0.58, blue: 0.54),
        charcoal: Color(red: 0.22, green: 0.27, blue: 0.24),
        panel: Color(red: 0.92, green: 0.95, blue: 0.91).opacity(0.82),
        panelDeep: Color(red: 0.79, green: 0.86, blue: 0.81),
        background: LinearGradient(
            colors: [
                Color(red: 0.88, green: 0.93, blue: 0.89),
                Color(red: 0.80, green: 0.88, blue: 0.83),
                Color(red: 0.68, green: 0.78, blue: 0.73)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        hero: LinearGradient(
            colors: [
                Color(red: 0.19, green: 0.44, blue: 0.35),
                Color(red: 0.44, green: 0.66, blue: 0.56),
                Color(red: 0.88, green: 0.95, blue: 0.91)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        sheetBackground: LinearGradient(
            colors: [
                Color(red: 0.88, green: 0.94, blue: 0.89),
                Color(red: 0.79, green: 0.86, blue: 0.81)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        unknownTile: Color(red: 0.84, green: 0.89, blue: 0.85),
        absentTile: Color(red: 0.60, green: 0.67, blue: 0.62),
        unknownTileBorder: Color(red: 0.18, green: 0.36, blue: 0.29).opacity(0.80),
        activeTileBorder: Color(red: 0.15, green: 0.31, blue: 0.25),
        unknownKeyFill: Color(red: 0.87, green: 0.91, blue: 0.88).opacity(0.98),
        absentKeyGradient: [
            Color(red: 0.59, green: 0.66, blue: 0.61),
            Color(red: 0.43, green: 0.49, blue: 0.45),
            Color(red: 0.28, green: 0.34, blue: 0.31)
        ],
        unknownKeyText: Color(red: 0.11, green: 0.16, blue: 0.13),
        coinCapsuleFill: Color(red: 0.91, green: 0.95, blue: 0.92).opacity(0.92),
        coinCapsuleStroke: Color(red: 0.18, green: 0.38, blue: 0.30).opacity(0.34),
        actionText: Color(red: 0.97, green: 0.99, blue: 0.97),
        selectedGlow: Color(red: 0.28, green: 0.54, blue: 0.45),
        presentGradient: [Color(red: 0.91, green: 0.76, blue: 0.52), Color(red: 0.70, green: 0.50, blue: 0.28)],
        correctGradient: [Color(red: 0.50, green: 0.76, blue: 0.64), Color(red: 0.17, green: 0.48, blue: 0.37)],
        colorBlindPresentGradient: [Color(red: 0.93, green: 0.57, blue: 0.27), Color(red: 0.76, green: 0.38, blue: 0.17)],
        colorBlindCorrectGradient: [Color(red: 0.58, green: 0.79, blue: 0.93), Color(red: 0.25, green: 0.51, blue: 0.67)]
    )

    static let emberLacquer = AureliaSkinPalette(
        ink: Color(red: 0.08, green: 0.04, blue: 0.03),
        obsidian: Color(red: 0.12, green: 0.05, blue: 0.05),
        parchment: Color(red: 0.98, green: 0.91, blue: 0.83),
        champagne: Color(red: 0.93, green: 0.69, blue: 0.42),
        secondaryText: Color.white,
        tertiaryText: Color(red: 0.98, green: 0.91, blue: 0.83),
        bronze: Color(red: 0.71, green: 0.40, blue: 0.17),
        apricot: Color(red: 0.96, green: 0.57, blue: 0.26),
        copper: Color(red: 0.79, green: 0.30, blue: 0.12),
        ruby: Color(red: 0.67, green: 0.15, blue: 0.12),
        emerald: Color(red: 0.34, green: 0.54, blue: 0.33),
        mint: Color(red: 0.60, green: 0.79, blue: 0.57),
        sky: Color(red: 0.65, green: 0.77, blue: 0.88),
        cobalt: Color(red: 0.28, green: 0.46, blue: 0.69),
        slate: Color(red: 0.38, green: 0.25, blue: 0.22),
        charcoal: Color(red: 0.18, green: 0.09, blue: 0.08),
        panel: Color(red: 0.99, green: 0.84, blue: 0.74).opacity(0.09),
        panelDeep: Color(red: 0.24, green: 0.10, blue: 0.10),
        background: LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.03, blue: 0.03),
                Color(red: 0.29, green: 0.08, blue: 0.06),
                Color(red: 0.14, green: 0.05, blue: 0.04)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        hero: LinearGradient(
            colors: [
                Color(red: 0.99, green: 0.87, blue: 0.76),
                Color(red: 0.95, green: 0.58, blue: 0.29),
                Color(red: 0.60, green: 0.14, blue: 0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        sheetBackground: LinearGradient(
            colors: [
                Color(red: 0.16, green: 0.05, blue: 0.05),
                Color(red: 0.28, green: 0.09, blue: 0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        unknownTile: Color(red: 0.28, green: 0.11, blue: 0.10),
        absentTile: Color(red: 0.19, green: 0.08, blue: 0.07),
        unknownTileBorder: Color(red: 0.97, green: 0.76, blue: 0.58).opacity(0.82),
        activeTileBorder: Color(red: 0.99, green: 0.84, blue: 0.68),
        unknownKeyFill: Color(red: 0.27, green: 0.11, blue: 0.10).opacity(0.94),
        absentKeyGradient: [
            Color(red: 0.56, green: 0.20, blue: 0.15),
            Color(red: 0.37, green: 0.12, blue: 0.10),
            Color(red: 0.20, green: 0.07, blue: 0.06)
        ],
        unknownKeyText: Color(red: 0.99, green: 0.91, blue: 0.84),
        coinCapsuleFill: Color(red: 0.15, green: 0.06, blue: 0.05).opacity(0.44),
        coinCapsuleStroke: Color(red: 0.98, green: 0.73, blue: 0.48).opacity(0.46),
        actionText: Color(red: 0.20, green: 0.07, blue: 0.05),
        selectedGlow: Color(red: 0.94, green: 0.57, blue: 0.28),
        presentGradient: [Color(red: 0.98, green: 0.75, blue: 0.48), Color(red: 0.81, green: 0.43, blue: 0.19)],
        correctGradient: [Color(red: 0.63, green: 0.82, blue: 0.57), Color(red: 0.29, green: 0.53, blue: 0.28)],
        colorBlindPresentGradient: [Color(red: 0.98, green: 0.60, blue: 0.27), Color(red: 0.81, green: 0.32, blue: 0.14)],
        colorBlindCorrectGradient: [Color(red: 0.66, green: 0.82, blue: 1.0), Color(red: 0.30, green: 0.50, blue: 0.83)]
    )

    static let sapphireClub = AureliaSkinPalette(
        ink: Color(red: 0.04, green: 0.08, blue: 0.13),
        obsidian: Color(red: 0.06, green: 0.11, blue: 0.18),
        parchment: Color(red: 0.96, green: 0.95, blue: 0.92),
        champagne: Color(red: 0.92, green: 0.78, blue: 0.55),
        secondaryText: Color.white,
        tertiaryText: Color(red: 0.96, green: 0.95, blue: 0.92),
        bronze: Color(red: 0.73, green: 0.56, blue: 0.28),
        apricot: Color(red: 0.92, green: 0.60, blue: 0.29),
        copper: Color(red: 0.76, green: 0.39, blue: 0.18),
        ruby: Color(red: 0.48, green: 0.28, blue: 0.24),
        emerald: Color(red: 0.27, green: 0.57, blue: 0.48),
        mint: Color(red: 0.59, green: 0.83, blue: 0.74),
        sky: Color(red: 0.56, green: 0.78, blue: 0.97),
        cobalt: Color(red: 0.24, green: 0.49, blue: 0.86),
        slate: Color(red: 0.33, green: 0.40, blue: 0.50),
        charcoal: Color(red: 0.11, green: 0.18, blue: 0.28),
        panel: Color(red: 0.82, green: 0.90, blue: 1.0).opacity(0.11),
        panelDeep: Color(red: 0.10, green: 0.20, blue: 0.32),
        background: LinearGradient(
            colors: [
                Color(red: 0.03, green: 0.08, blue: 0.15),
                Color(red: 0.08, green: 0.20, blue: 0.34),
                Color(red: 0.04, green: 0.12, blue: 0.23)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        hero: LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.94, blue: 0.86),
                Color(red: 0.91, green: 0.76, blue: 0.53),
                Color(red: 0.31, green: 0.55, blue: 0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        sheetBackground: LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.15, blue: 0.26),
                Color(red: 0.11, green: 0.23, blue: 0.37)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        unknownTile: Color(red: 0.15, green: 0.26, blue: 0.39),
        absentTile: Color(red: 0.10, green: 0.18, blue: 0.28),
        unknownTileBorder: Color(red: 0.94, green: 0.83, blue: 0.64).opacity(0.82),
        activeTileBorder: Color(red: 0.99, green: 0.91, blue: 0.77),
        unknownKeyFill: Color(red: 0.14, green: 0.26, blue: 0.39).opacity(0.94),
        absentKeyGradient: [
            Color(red: 0.25, green: 0.39, blue: 0.56),
            Color(red: 0.16, green: 0.27, blue: 0.42),
            Color(red: 0.09, green: 0.17, blue: 0.28)
        ],
        unknownKeyText: Color(red: 0.96, green: 0.95, blue: 0.92),
        coinCapsuleFill: Color(red: 0.07, green: 0.12, blue: 0.18).opacity(0.44),
        coinCapsuleStroke: Color(red: 0.95, green: 0.82, blue: 0.60).opacity(0.42),
        actionText: Color(red: 0.08, green: 0.13, blue: 0.20),
        selectedGlow: Color(red: 0.94, green: 0.79, blue: 0.54),
        presentGradient: [Color(red: 0.96, green: 0.82, blue: 0.55), Color(red: 0.77, green: 0.58, blue: 0.27)],
        correctGradient: [Color(red: 0.57, green: 0.84, blue: 0.78), Color(red: 0.24, green: 0.56, blue: 0.49)],
        colorBlindPresentGradient: [Color(red: 0.95, green: 0.61, blue: 0.29), Color(red: 0.79, green: 0.37, blue: 0.17)],
        colorBlindCorrectGradient: [Color(red: 0.60, green: 0.81, blue: 1.0), Color(red: 0.24, green: 0.49, blue: 0.90)]
    )
}

@MainActor
enum AureliaTheme {
    private static var activeSkinID: SkinID = .default

    private static var currentPalette: AureliaSkinPalette {
        activeSkin.palette
    }

    static func applySkin(_ skin: Skin) {
        activeSkinID = skin.id
    }

    static func skin(for id: SkinID) -> Skin {
        Skin.catalog.first(where: { $0.id == id }) ?? .default
    }

    static var activeSkin: Skin {
        skin(for: activeSkinID)
    }

    static let availableSkins = Skin.catalog

    static var ink: Color { currentPalette.ink }
    static var obsidian: Color { currentPalette.obsidian }
    static var parchment: Color { currentPalette.parchment }
    static var champagne: Color { currentPalette.champagne }
    static var secondaryText: Color { currentPalette.secondaryText }
    static var tertiaryText: Color { currentPalette.tertiaryText }
    static var bronze: Color { currentPalette.bronze }
    static var apricot: Color { currentPalette.apricot }
    static var copper: Color { currentPalette.copper }
    static var ruby: Color { currentPalette.ruby }
    static var emerald: Color { currentPalette.emerald }
    static var mint: Color { currentPalette.mint }
    static var sky: Color { currentPalette.sky }
    static var cobalt: Color { currentPalette.cobalt }
    static var slate: Color { currentPalette.slate }
    static var charcoal: Color { currentPalette.charcoal }
    static var panel: Color { currentPalette.panel }
    static var panelDeep: Color { currentPalette.panelDeep }

    static var background: LinearGradient { currentPalette.background }
    static var hero: LinearGradient { currentPalette.hero }
    static var sheetBackground: LinearGradient { currentPalette.sheetBackground }
    static var unknownTile: Color { currentPalette.unknownTile }
    static var absentTile: Color { currentPalette.absentTile }
    static var unknownTileBorder: Color { currentPalette.unknownTileBorder }
    static var activeTileBorder: Color { currentPalette.activeTileBorder }
    static var unknownKeyFill: Color { currentPalette.unknownKeyFill }
    static var unknownKeyText: Color { currentPalette.unknownKeyText }
    static var absentKeyGradient: [Color] { currentPalette.absentKeyGradient }
    static var coinCapsuleFill: Color { currentPalette.coinCapsuleFill }
    static var coinCapsuleStroke: Color { currentPalette.coinCapsuleStroke }
    static var actionText: Color { currentPalette.actionText }
    static var selectedGlow: Color { currentPalette.selectedGlow }

    static func presentGradient(colorBlindMode: Bool) -> [Color] {
        colorBlindMode ? currentPalette.colorBlindPresentGradient : currentPalette.presentGradient
    }

    static func correctGradient(colorBlindMode: Bool) -> [Color] {
        colorBlindMode ? currentPalette.colorBlindCorrectGradient : currentPalette.correctGradient
    }

    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct PremiumCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AureliaTheme.panel.opacity(0.95),
                                AureliaTheme.panelDeep.opacity(0.94)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AureliaTheme.selectedGlow.opacity(0.24), lineWidth: 1)
            )
            .shadow(color: AureliaTheme.obsidian.opacity(0.26), radius: 24, x: 0, y: 16)
    }
}

struct SheetCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AureliaTheme.panel.opacity(0.92),
                                AureliaTheme.panelDeep.opacity(0.98)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AureliaTheme.champagne.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: AureliaTheme.obsidian.opacity(0.14), radius: 14, x: 0, y: 8)
    }
}

extension View {
    func premiumCard() -> some View {
        modifier(PremiumCard())
    }

    func sheetCard() -> some View {
        modifier(SheetCard())
    }
}
