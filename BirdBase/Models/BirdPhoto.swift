import Foundation
import CoreData

class BirdPhoto: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var imageData: Data?
    @NSManaged public var timestamp: Date
    @NSManaged public var title: String
    @NSManaged public var location: String?
    @NSManaged public var notes: String?
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        timestamp = Date()
    }
}

extension BirdPhoto {
    static func fetchRequest() -> NSFetchRequest<BirdPhoto> {
        return NSFetchRequest<BirdPhoto>(entityName: "BirdPhoto")
    }
}
