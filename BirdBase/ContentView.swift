import SwiftUI

struct BirdImage: Identifiable {
    let id = UUID()
    let name: String
    let uiImage: UIImage
}

class ImageManager: ObservableObject {
    @Published var images: [BirdImage] = []
    private let fileManager = FileManager.default
    
    init() {
        loadImages()
    }
    
    private func loadImages() {
        // Get URL directly from the main bundle
        guard let bundleURL = Bundle.main.url(forResource: "BirdImages", withExtension: nil) else {
            print("Could not find BirdImages directory in bundle")
            return
        }
        
        do {
            let imageFiles = try fileManager.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension.lowercased() == "jpg" }
            
            images = imageFiles.compactMap { url in
                guard let imageData = try? Data(contentsOf: url),
                      let uiImage = UIImage(data: imageData) else { return nil }
                return BirdImage(
                    name: url.deletingPathExtension().lastPathComponent,
                    uiImage: uiImage
                )
            }.sorted { $0.name < $1.name }
            
            print("Loaded \(images.count) images from \(bundleURL.path)")
        } catch {
            print("Error loading images: \(error.localizedDescription)")
        }
    }
    
    func getImagesPath() -> String? {
        Bundle.main.url(forResource: "BirdImages", withExtension: nil)?.path
    }
}

struct ContentView: View {
    @StateObject private var imageManager = ImageManager()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.9, green: 0.8, blue: 1.0)
                    .ignoresSafeArea()
                
                VStack {
                    if let path = imageManager.getImagesPath() {
                        Text("Images loaded from:")
                            .font(.caption)
                        Text(path)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(imageManager.images) { image in
                                VStack {
                                    Image(uiImage: image.uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                        .cornerRadius(10)
                                    
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
