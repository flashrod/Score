import SwiftUI
import AppKit

struct CrestImage: View {
    let url: String?
    let size: CGSize

    init(_ url: String?, width: CGFloat, height: CGFloat) {
        self.url = url
        self.size = CGSize(width: width, height: height)
    }

    init(_ url: String?, size: CGFloat) {
        self.url = url
        self.size = CGSize(width: size, height: size)
    }

    var body: some View {
        if let url = url.flatMap({ URL(string: $0) }) {
            RemoteImage(url: url)
                .frame(width: size.width, height: size.height)
        }
    }
}

private struct RemoteImage: View {
    let url: URL
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.clear
            }
        }
        .task {
            guard let data = try? await URLSession.shared.data(for: URLRequest(url: url)).0,
                  let loaded = NSImage(data: data)
            else { return }
            image = loaded
        }
    }
}
