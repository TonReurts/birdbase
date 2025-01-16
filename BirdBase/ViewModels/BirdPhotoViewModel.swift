import Foundation
import SwiftUI

class BirdPhotoViewModel: ObservableObject {
    @Published var birds: [BirdPhoto] = []
    @Published var searchText: String = ""
    
    var filteredBirds: [BirdPhoto] {
        if searchText.isEmpty {
            return birds
        }
        return birds.filter { $0.matches(searchText: searchText) }
    }
    
    func loadPhotos() {
        // TODO: Implement photo loading from local storage
        // This will be implemented when we have the photo storage system ready
    }
}
