import SwiftUICore
import SwiftUI

struct FontStyle {
    let size: CGFloat
    let weight: Font.Weight
    let lineHeight: CGFloat
    let letterSpacing: CGFloat
}

struct Fonts {
    static let textMd = FontStyle(size: 16, weight: .regular, lineHeight: 1.5, letterSpacing: 0.01)
    static let textMdBold = FontStyle(size: 16, weight: .semibold, lineHeight: 1.5, letterSpacing: 0.01)
    
    static let textLg = FontStyle(size: 20, weight: .regular, lineHeight: 1.35, letterSpacing: 0)
    static let textLgBold = FontStyle(size: 20, weight: .semibold, lineHeight: 1.35, letterSpacing: 0)
    
    static let textXl = FontStyle(size: 32, weight: .regular, lineHeight: 1.2, letterSpacing: -0.01)
    static let textXlBold = FontStyle(size: 32, weight: .semibold, lineHeight: 1.2, letterSpacing: -0.01)
    
    static let text2Xl = FontStyle(size: 96, weight: .regular, lineHeight: 1.2, letterSpacing: -0.02)
    static let text2XlBold = FontStyle(size: 96, weight: .semibold, lineHeight: 1.2, letterSpacing: -0.02)
}

extension Text {
    func setFontStyle(_ fontStyle: FontStyle) -> some View {
        self.font(Font.system(size: fontStyle.size, weight: fontStyle.weight))
            .kerning(fontStyle.size * fontStyle.letterSpacing)
            .frame(height: fontStyle.size * fontStyle.lineHeight)
            .lineLimit(1)
    }
    func setFontStyleMultiline(_ fontStyle: FontStyle) -> some View {
        self.font(Font.system(size: fontStyle.size, weight: fontStyle.weight))
            .kerning(fontStyle.size * fontStyle.letterSpacing)
            .lineSpacing(fontStyle.size * (fontStyle.lineHeight - 1))
    }
}

struct Colors {
    static let black = Color("Black")
    static let white = Color("White")
    static let red = Color("Red")
}

struct PrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Colors.white)
            .foregroundStyle(Colors.black)
            .clipShape(.capsule)
    }
}

enum TrackingState {
    case good
    case low
    case high
    
    var heartBeatDuration: Double {
        switch self {
            case .good:
                return 30 / 80
            case .low:
                return 30 / 40
            case .high:
                return 30 / 200
        }
    }
    
    var heartBeatDescription: String {
        switch self {
            case .good:
                return "Good"
            case .low:
                return "Too low!"
            case .high:
                return "Too high!"
        }
    }
    
    var heartBeatColor: Color {
        switch self {
        case .good:
            return Colors.white
        case .low:
            return Colors.red
        case .high:
            return Colors.red
        }
    }
    
    var sound: SoundType? {
        switch self {
        case .good:
            return nil
        case .low:
            return SoundType.lowBeep
        case .high:
            return SoundType.highBeep
        }
    }
    
    var soundState: SoundType {
        switch self {
        case .good:
            return SoundType.good
        case .low:
            return SoundType.tooLow
        case .high:
            return SoundType.tooHigh
        }
    }
}
