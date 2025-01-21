import SwiftUI
import ImageIO
import CoreLocation

struct BirdImage: Identifiable {
    let id = UUID()
    let name: String
    let uiImage: UIImage
    let coordinates: CLLocationCoordinate2D?
    let description: String?
}

class ImageManager: ObservableObject {
    @Published var images: [BirdImage] = []
    private let fileManager = FileManager.default
    
    init() {
        loadImages()
    }
    
    private func loadImages() {
        guard let BirdImagesURL = Bundle.main.url(forResource: "BirdImages", withExtension: nil) else {
            print("BirdImages folder not found.")
            return
        }
        
        do {
            let imageFiles = try fileManager.contentsOfDirectory(at: BirdImagesURL, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension.lowercased() == "jpg" }
            
            images = imageFiles.compactMap { url in
                guard let imageData = try? Data(contentsOf: url),
                      let uiImage = UIImage(data: imageData) else { return nil }
                
                // Extract metadata
                let coordinates: CLLocationCoordinate2D?
                let description: String?
                
                if let source = CGImageSourceCreateWithData(imageData as CFData, nil) {
                    if let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
                       let gpsInfo = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
                        
                        if let latitude = gpsInfo[kCGImagePropertyGPSLatitude as String] as? Double,
                           let longitude = gpsInfo[kCGImagePropertyGPSLongitude as String] as? Double {
                            
                            let latRef = gpsInfo[kCGImagePropertyGPSLatitudeRef as String] as? String ?? "N"
                            let longRef = gpsInfo[kCGImagePropertyGPSLongitudeRef as String] as? String ?? "E"
                            
                            let lat = latRef == "S" ? -latitude : latitude
                            let long = longRef == "W" ? -longitude : longitude
                            
                            coordinates = CLLocationCoordinate2D(latitude: lat, longitude: long)
                        } else {
                            coordinates = nil
                        }
                    } else {
                        coordinates = nil
                    }
                    
                    if let iptcMetadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
                       let iptcData = iptcMetadata[kCGImagePropertyIPTCDictionary as String] as? [String: Any],
                       let desc = iptcData[kCGImagePropertyIPTCCaptionAbstract as String] as? String {
                        description = desc
                    } else {
                        description = nil
                    }
                } else {
                    coordinates = nil
                    description = nil
                }
                
                return BirdImage(
                    name: url.deletingPathExtension().lastPathComponent,
                    uiImage: uiImage,
                    coordinates: coordinates,
                    description: description
                )
            }.sorted { $0.name < $1.name }
            
            print("Loaded \(images.count) images from \(BirdImagesURL.path)")
        } catch {
            print("Error loading images: \(error.localizedDescription)")
        }
    }
    
    func getImagesPath() -> String? {
        Bundle.main.url(forResource: "BirdImages", withExtension: nil)?.path
    }
}

struct FullScreenImageView: View {
    let image: BirdImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image.uiImage)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale = scale * delta
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .simultaneousGesture(
                    TapGesture(count: 2)
                        .onEnded {
                            withAnimation {
                                scale = scale == 1.0 ? 2.0 : 1.0
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                )
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
            }
        }
        .overlay(alignment: .bottom) {
            VStack(alignment: .leading) {
                Text(image.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let coordinates = image.coordinates {
                    Text("Coordinates: \(coordinates.latitude), \(coordinates.longitude)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                
                if let description = image.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(.black.opacity(0.6))
            .cornerRadius(10)
            .padding(.bottom)
        }
        .statusBar(hidden: true)
    }
}

struct ContentView: View {
    @StateObject private var imageManager = ImageManager()
    @State private var selectedImage: BirdImage?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.9, green: 0.8, blue: 1.0)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(imageManager.images) { image in
                            VStack {
                                Image(uiImage: image.uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .cornerRadius(10)
                                    .onTapGesture {
                                        selectedImage = image
                                    }
                                
                                Text(image.name)
                                    .font(.caption)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Bird Photos (\(imageManager.images.count))")
        }
        .fullScreenCover(item: $selectedImage) { image in
            FullScreenImageView(image: image)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
