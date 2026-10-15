import SwiftUI
import UIKit

// MARK: - Bilder

enum ImageTools {
    /// Verkleinert und komprimiert ein Foto. Es wird NUR in der App-Datenbank gespeichert.
    static func jpegData(_ image: UIImage, maxDimension: CGFloat, quality: CGFloat = 0.75) -> Data? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let scale = min(1, maxDimension / max(size.width, size.height))
        let newSize = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat.preferred()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}

// MARK: - Symbole

enum SymbolCatalog {
    static let all: [String] = [
        "key.fill", "car.fill", "wallet.pass.fill", "creditcard.fill", "person.text.rectangle.fill",
        "airpods", "headphones", "iphone", "applewatch", "laptopcomputer", "ipad",
        "eyeglasses", "sunglasses.fill", "bag.fill", "backpack.fill", "handbag.fill", "suitcase.fill",
        "umbrella.fill", "book.closed.fill", "pills.fill", "cross.case.fill", "gamecontroller.fill",
        "camera.fill", "bicycle", "house.fill", "lock.fill", "doc.text.fill", "tshirt.fill",
        "shoe.fill", "gift.fill", "pawprint.fill", "tag.fill", "powerplug.fill", "star.fill"
    ]

    /// Symbole für Orte/Räume
    static let places: [String] = [
        "fork.knife", "sofa.fill", "bed.double.fill", "door.left.hand.open", "desktopcomputer",
        "car.fill", "backpack.fill", "bag.fill", "cabinet.fill", "shippingbox.fill", "archivebox.fill",
        "washer.fill", "bathtub.fill", "building.2.fill", "house.fill", "tree.fill", "tent.fill",
        "briefcase.fill", "tray.full.fill", "key.fill", "mappin.and.ellipse", "square.grid.2x2.fill",
        "lamp.desk.fill", "refrigerator.fill", "stairs", "garage" ,"bicycle", "airplane", "train.side.front.car"
    ]
}

// MARK: - Stil

struct Panel: ViewModifier {
    var fill: Color
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(fill))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.black.opacity(0.35), lineWidth: 1.5)
            )
    }
}

extension View {
    /// Gefüllte Fläche mit dunklem Rand – wie im Entwurf.
    func panel(_ fill: Color, radius: CGFloat = 12) -> some View {
        modifier(Panel(fill: fill, radius: radius))
    }

    /// Weicher Schatten, der sich der Theme-Helligkeit anpasst.
    func softShadow(_ settings: AppSettings, radius: CGFloat = 8, y: CGFloat = 4) -> some View {
        shadow(color: settings.shadow, radius: radius, y: y)
    }
}

/// Druck-Feedback: leicht kleiner und etwas dunkler – ruhig und kurz.
struct PressableStyle: ButtonStyle {
    @Environment(\.motion) private var motion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !motion.reduced ? 0.97 : 1)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(motion.quick, value: configuration.isPressed)
    }
}

struct SectionLabel: View {
    let key: Str
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Text(settings.t(key))
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(settings.onBackground)
    }
}

/// Leerer Zustand mit ruhig pulsierendem Symbol.
struct EmptyState: View {
    let symbol: String
    let text: String
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.motion) private var motion

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 30, weight: .regular))
                .symbolEffect(.pulse.byLayer, options: motion.reduced ? .nonRepeating : .repeating.speed(0.6))
            Text(text)
                .font(.subheadline)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(settings.onBackground.opacity(0.75))
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }
}

// MARK: - Gegenstand-Darstellung

/// Name oder (wenn eingestellt) nur das Symbol eines Gegenstands.
struct ItemTitle: View {
    let item: Item
    var symbolFont: Font = .title3

    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Group {
            if settings.showSymbols, let symbol = item.symbol {
                Image(systemName: symbol).font(symbolFont)
            } else {
                HStack(spacing: 6) {
                    Text(item.name).lineLimit(1)
                    if let symbol = item.symbol {
                        Image(systemName: symbol).imageScale(.small)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.name)
    }
}

struct SymbolBadge: View {
    let symbol: String?
    var size: CGFloat = 56
    var fill: Color? = nil

    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        let background = fill ?? settings.tile
        ZStack {
            background
            Image(systemName: symbol ?? "shippingbox.fill")
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(HexColor.readableText(on: background.hexString))
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .stroke(Color.black.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Kleines Vorschaubild: Foto, sonst Symbol.
struct ItemThumb: View {
    let item: Item
    var size: CGFloat = 48

    var body: some View {
        if let data = item.thumbnailData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                        .stroke(Color.black.opacity(0.3), lineWidth: 1)
                )
        } else {
            SymbolBadge(symbol: item.symbol ?? "note.text", size: size)
        }
    }
}

/// Kleine Orts-Anzeige (Symbol + Name) in Listen und Kacheln.
struct PlaceTag: View {
    let place: Place
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: place.displaySymbol)
            if !compact {
                Text(place.name).lineLimit(1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(place.name)
    }
}

struct SymbolPicker: View {
    @Binding var selection: String?
    var catalog: [String] = SymbolCatalog.all
    @EnvironmentObject private var settings: AppSettings

    private let columns = [GridItem(.adaptive(minimum: 50), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            cell(nil)
            ForEach(catalog, id: \.self) { symbol in
                cell(symbol)
            }
        }
        .sensoryFeedback(.selection, trigger: selection) { _, _ in settings.haptics }
    }

    private func cell(_ symbol: String?) -> some View {
        let selected = selection == symbol
        return Button {
            selection = symbol
        } label: {
            Image(systemName: symbol ?? "nosign")
                .font(.system(size: 22, weight: .semibold))
                .frame(width: 50, height: 50)
                .foregroundStyle(selected ? settings.onTile : settings.onList)
                .panel(selected ? settings.tile : settings.list, radius: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(settings.onBackground, lineWidth: selected ? 2.5 : 0)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol ?? settings.t(.noSymbol))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: - Orts-Chips (Auswahl & Filter) mit gleitender Hervorhebung

struct PlaceChipsRow: View {
    let places: [Place]
    @Binding var selection: Place?
    /// Erster Chip „Alle“/„Ohne Ort“ (für die Suche); nil = kein Extra-Chip
    var leadingLabel: String? = nil
    /// Letzter Chip „+ Neuer Ort“
    var onAdd: (() -> Void)? = nil

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.motion) private var motion
    @Namespace private var highlight

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let leadingLabel {
                    chip(id: "all", symbol: "square.grid.2x2", label: leadingLabel,
                         selected: selection == nil, fill: settings.tile) {
                        withAnimation(motion.standard) { selection = nil }
                    }
                }
                ForEach(places) { place in
                    let selected = selection?.persistentModelID == place.persistentModelID
                    chip(id: "\(place.stableID)", symbol: place.displaySymbol, label: place.name,
                         selected: selected, fill: settings.placeColor(place)) {
                        withAnimation(motion.standard) {
                            selection = selected && leadingLabel == nil ? nil : place
                        }
                    }
                }
                if let onAdd {
                    Button(action: onAdd) {
                        Label(settings.t(.newPlace), systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(settings.onBackground)
                            .padding(.horizontal, 12)
                            .frame(height: 36)
                            .overlay(
                                Capsule().strokeBorder(settings.onBackground.opacity(0.5),
                                                       style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 1)
        }
        .sensoryFeedback(.selection, trigger: selection?.persistentModelID) { _, _ in settings.haptics }
    }

    private func chip(id: String, symbol: String, label: String, selected: Bool, fill: Color,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol).imageScale(.small)
                Text(label).lineLimit(1)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(selected ? HexColor.readableText(on: fill.hexString) : settings.onList)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background {
                if selected {
                    Capsule().fill(fill)
                        .matchedGeometryEffect(id: "chip", in: highlight)
                } else {
                    Capsule().fill(settings.list)
                }
            }
            .overlay(Capsule().stroke(Color.black.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: - Speicher-Bestätigung

/// Kurze Häkchen-Bestätigung nach dem Speichern.
struct SaveConfirmation: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.motion) private var motion
    @State private var bounce = 0

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 54, weight: .semibold))
                .symbolEffect(.bounce, options: motion.reduced ? .nonRepeating.speed(10) : .nonRepeating, value: bounce)
            Text(settings.t(.saved))
                .font(.headline)
        }
        .foregroundStyle(settings.onTile)
        .padding(28)
        .panel(settings.tile, radius: 20)
        .softShadow(settings, radius: 14, y: 6)
        .onAppear { bounce += 1 }
    }
}
