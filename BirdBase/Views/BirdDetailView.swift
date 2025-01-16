import SwiftUI

struct BirdDetailView: View {
    let bird: BirdPhoto
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Full screen image
            AsyncImage(url: URL(fileURLWithPath: bird.imagePath)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .ignoresSafeArea()
            } placeholder: {
                ProgressView()
            }
            
            // Info overlay at the bottom
            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    Text(bird.name)
                        .font(.title)
                        .bold()
                    
                    HStack {
                        Label(bird.gender.rawValue.capitalized, systemImage: "person.fill")
                        Spacer()
                        Label(bird.location, systemImage: "mappin.circle.fill")
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
