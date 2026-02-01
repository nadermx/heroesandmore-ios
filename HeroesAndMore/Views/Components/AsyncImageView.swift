import SwiftUI

struct AsyncImageView: View {
    let url: URL?
    var contentMode: ContentMode = .fill

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        ProgressView()
                    }

            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)

            case .failure:
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.gray)
                    }

            @unknown default:
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
        }
    }
}

struct AvatarView: View {
    let url: String?
    var size: CGFloat = 40

    var body: some View {
        if let urlString = url, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    defaultAvatar
                @unknown default:
                    defaultAvatar
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            defaultAvatar
                .frame(width: size, height: size)
        }
    }

    private var defaultAvatar: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .overlay {
                Image(systemName: "person.fill")
                    .foregroundStyle(.gray)
                    .font(.system(size: size * 0.5))
            }
    }
}

#Preview {
    VStack {
        AsyncImageView(url: nil)
            .frame(width: 200, height: 200)

        AvatarView(url: nil, size: 60)
    }
}
