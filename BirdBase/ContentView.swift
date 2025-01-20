import SwiftUI

struct BirdImage: Identifiable {
    let id = UUID()
    let name: String
}

struct ContentView: View {
    let images = [
        BirdImage(name: "Bergeend"),
        BirdImage(name: "Brandgans"),
        BirdImage(name: "IJsvogel")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.9, green: 0.8, blue: 1.0)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(images) { image in
                            Image(image.name)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Bird Photos")
        }
    }
}

#Preview {
    ContentView()
}
