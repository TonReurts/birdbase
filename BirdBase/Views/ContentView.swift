import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = BirdPhotoViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Image
                Image("background")
                    .resizable()
                    .ignoresSafeArea()
                    .opacity(0.3)
                
                VStack {
                    // Search Bar
                    SearchBar(text: $viewModel.searchText)
                        .padding()
                    
                    // Bird Grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(viewModel.filteredBirds) { bird in
                                NavigationLink(destination: BirdDetailView(bird: bird)) {
                                    BirdGridItem(bird: bird)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Bird Gallery")
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search birds...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct BirdGridItem: View {
    let bird: BirdPhoto
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(fileURLWithPath: bird.imagePath)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Text(bird.name)
                .font(.caption)
                .lineLimit(1)
        }
    }
}
