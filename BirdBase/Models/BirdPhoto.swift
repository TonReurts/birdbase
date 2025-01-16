import Foundation

struct BirdPhoto: Identifiable, Codable {
    let id: UUID
    let name: String
    let gender: Gender
    let location: String
    let imagePath: String
    
    enum Gender: String, Codable {
        case male
        case female
        case unknown
    }
}

// Extension to add search functionality
extension BirdPhoto {
    func matches(searchText: String) -> Bool {
        return name.localizedCaseInsensitiveContains(searchText) ||
               location.localizedCaseInsensitiveContains(searchText)
    }
}
