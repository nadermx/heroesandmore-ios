import SwiftUI

struct PriceText: View {
    let price: String
    var style: PriceStyle = .regular
    var showCurrency: Bool = true

    enum PriceStyle {
        case regular
        case large
        case small
        case highlighted
    }

    var body: some View {
        Text(formattedPrice)
            .font(font)
            .foregroundStyle(foregroundColor)
            .fontWeight(fontWeight)
    }

    private var formattedPrice: String {
        if showCurrency {
            return "$\(price)"
        }
        return price
    }

    private var font: Font {
        switch style {
        case .regular:
            return .body
        case .large:
            return .title2
        case .small:
            return .caption
        case .highlighted:
            return .headline
        }
    }

    private var fontWeight: Font.Weight {
        switch style {
        case .regular, .small:
            return .regular
        case .large, .highlighted:
            return .semibold
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .highlighted:
            return .green
        default:
            return .primary
        }
    }
}

struct PriceChangeText: View {
    let change: String?
    let percentChange: String?

    var body: some View {
        if let change = change {
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                    .font(.caption2)

                Text("$\(change.replacingOccurrences(of: "-", with: ""))")
                    .font(.caption)

                if let percent = percentChange {
                    Text("(\(percent)%)")
                        .font(.caption2)
                }
            }
            .foregroundStyle(isPositive ? .green : .red)
        }
    }

    private var isPositive: Bool {
        guard let change = change,
              let value = Double(change) else {
            return false
        }
        return value >= 0
    }
}

struct RatingView: View {
    let rating: Double?
    let count: Int
    var showCount: Bool = true

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Image(systemName: starImage(for: index))
                    .font(.caption)
                    .foregroundStyle(.yellow)
            }

            if showCount && count > 0 {
                Text("(\(count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func starImage(for index: Int) -> String {
        guard let rating = rating else {
            return "star"
        }

        let threshold = Double(index) + 0.5
        if rating >= Double(index + 1) {
            return "star.fill"
        } else if rating >= threshold {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PriceText(price: "29.99")
        PriceText(price: "199.99", style: .large)
        PriceText(price: "9.99", style: .small)
        PriceText(price: "49.99", style: .highlighted)

        PriceChangeText(change: "5.00", percentChange: "10.5")
        PriceChangeText(change: "-3.50", percentChange: "-7.2")

        RatingView(rating: 4.5, count: 123)
        RatingView(rating: 3.0, count: 45)
    }
    .padding()
}
