import SwiftUI
import ImageIO
import CoreLocation
import MapKit

struct BirdImage: Identifiable {
    let id: UUID = UUID()
    let name: String
    let uiImage: UIImage
    let coordinates: CLLocationCoordinate2D?
    let description: String?
}

struct LocationAnnotation: Identifiable {
    let id: UUID = UUID()
    let coordinate: CLLocationCoordinate2D
}

class ImageManager: ObservableObject {
    @Published var images: [BirdImage] = []
    private let fileManager: FileManager = FileManager.default
    
    init() {
        loadImages()
    }
    
    private func loadImages() {
        guard let BirdImagesURL: URL = Bundle.main.url(forResource: "BirdImages", withExtension: nil) else {
            print("BirdImages folder not found.")
            return
        }
        
        do {
            let imageFiles: [URL] = try fileManager.contentsOfDirectory(at: BirdImagesURL, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension.lowercased() == "jpg" }
            
            images = imageFiles.compactMap { url in
                guard let imageData = try? Data(contentsOf: url),
                      let uiImage = UIImage(data: imageData) else { return nil }
                
                // Extract metadata
                let coordinates: CLLocationCoordinate2D?
                let description: String?
                var fileName: String
                
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
                    
                    if let iptcMetadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
                       let iptcData = iptcMetadata[kCGImagePropertyIPTCDictionary as String] as? [String: Any],
                       let keywords = iptcData[kCGImagePropertyIPTCKeywords as String] as? [String],
                       let firstKeyword = keywords.first {
                        fileName = firstKeyword
                    } else {
                        fileName = url.deletingPathExtension().lastPathComponent
                    }
                } else {
                    coordinates = nil
                    description = nil
                    fileName = url.deletingPathExtension().lastPathComponent
                }
                
                if let range = fileName.range(of: " \\d+$", options: .regularExpression) {
                    fileName.removeSubrange(range)
                }
                return BirdImage(
                    name: fileName,
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
    @Environment(\.dismiss) private var dismiss: DismissAction
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showMap: Bool = false
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if showMap, let coordinates = image.coordinates {
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: coordinates,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )), annotationItems: [LocationAnnotation(coordinate: coordinates)]) { location in
                    MapMarker(coordinate: location.coordinate, tint: .red)
                }
            } else {
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
        }
        .overlay(alignment: .topTrailing) {
            HStack {
                if image.coordinates != nil {
                    Button(action: {
                        withAnimation {
                            showMap.toggle()
                        }
                    }) {
                        Image(systemName: showMap ? "photo.fill" : "map.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                }
            }
        }
        .overlay(alignment: .bottom) {
            VStack(alignment: .leading) {
                Text(image.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
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
    @StateObject private var imageManager: ImageManager = ImageManager()
    @StateObject private var locationManager = LocationManager()
    @State private var selectedImage: BirdImage?
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $region, annotationItems: imageManager.images) { image in
                    MapAnnotation(coordinate: image.coordinates ?? CLLocationCoordinate2D()) {
                        Button(action: {
                            selectedImage = image
                        }) {
                            Image(systemName: "photo")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                    }
                }
                .ignoresSafeArea()
                .onAppear {
                    if let userLocation = locationManager.userLocation {
                        region.center = userLocation
                    }
                }
                
                VStack {
                    Spacer()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(imageManager.images) { image in
                                VStack {
                                    Image(uiImage: image.uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
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
            }
            .navigationTitle("Bird Photos (\(imageManager.images.count))")
        }
        .fullScreenCover(item: $selectedImage) { image in
            FullScreenImageView(image: image)
        }
        .onReceive(locationManager.$userLocation) { newLocation in
            if let newLocation = newLocation {
                region.center = newLocation
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
