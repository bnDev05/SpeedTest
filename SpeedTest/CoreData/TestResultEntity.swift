import Foundation
import CoreData

@objc(TestResultEntity)
public class TestResultEntity: NSManagedObject {
    
}

extension TestResultEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TestResultEntity> {
        return NSFetchRequest<TestResultEntity>(entityName: "TestResultEntity")
    }
    
    // Basic speed metrics
    @NSManaged public var id: UUID?
    @NSManaged public var downloadSpeed: Double
    @NSManaged public var uploadSpeed: Double
    @NSManaged public var ping: Int16
    @NSManaged public var jitter: Int16
    @NSManaged public var packetLoss: Int16
    
    // Speed history data (stored as JSON)
    @NSManaged public var downloadHistoryData: Data?
    @NSManaged public var uploadHistoryData: Data?
    
    // Server information
    @NSManaged public var serverName: String?
    @NSManaged public var serverLocation: String?
    
    // Connection information
    @NSManaged public var connectionType: String?
    @NSManaged public var providerName: String?
    @NSManaged public var internalIP: String?
    @NSManaged public var externalIP: String?
    
    // Test metadata
    @NSManaged public var testDate: Date?
    
    // Computed properties for speed history
    var downloadHistory: [SpeedDataPoint] {
        get {
            guard let data = downloadHistoryData else { return [] }
            let decoder = JSONDecoder()
            return (try? decoder.decode([SpeedDataPoint].self, from: data)) ?? []
        }
        set {
            let encoder = JSONEncoder()
            downloadHistoryData = try? encoder.encode(newValue)
        }
    }
    
    var uploadHistory: [SpeedDataPoint] {
        get {
            guard let data = uploadHistoryData else { return [] }
            let decoder = JSONDecoder()
            return (try? decoder.decode([SpeedDataPoint].self, from: data)) ?? []
        }
        set {
            let encoder = JSONEncoder()
            uploadHistoryData = try? encoder.encode(newValue)
        }
    }
}

extension TestResultEntity: Identifiable {
    
}

// MARK: - Conversion Methods
extension TestResultEntity {
    
    // Convert from TestResults to TestResultEntity
    func update(from testResults: TestResults) {
        self.id = UUID()
        self.downloadSpeed = testResults.downloadSpeed
        self.uploadSpeed = testResults.uploadSpeed
        self.ping = Int16(testResults.ping)
        self.jitter = Int16(testResults.jitter)
        self.packetLoss = Int16(testResults.packetLoss)
        
        self.downloadHistory = testResults.downloadHistory
        self.uploadHistory = testResults.uploadHistory
        
        self.serverName = testResults.serverName
        self.serverLocation = testResults.serverLocation
        self.connectionType = testResults.connectionType
        self.providerName = testResults.providerName
        self.internalIP = testResults.internalIP
        self.externalIP = testResults.externalIP
        self.testDate = testResults.testDate
    }
    
    @discardableResult
    static func create(from testResults: TestResults) -> TestResultEntity? {
        let context = PersistenceController.shared.container.viewContext
        let entity = TestResultEntity(context: context)
        entity.update(from: testResults)
        
        do {
            try context.save()
            print("✅ Saved new TestResultEntity for test at \(entity.testDate?.formatted() ?? "Unknown date")")
            return entity
        } catch {
            print("❌ Failed to save TestResultEntity: \(error.localizedDescription)")
            context.rollback()
            return nil
        }
    }
    
    static func averageBandwidth() -> Double {
        let entities = fetchAll(sortedByDate: false)
        guard !entities.isEmpty else { return 0 }
        
        // Collect all speeds depending on type
        let allSpeeds: [Double] = entities.flatMap { entity in
            return [entity.downloadSpeed, entity.uploadSpeed]
        }
        
        guard !allSpeeds.isEmpty else { return 0 }
        let total = allSpeeds.reduce(0, +)
        return total / Double(allSpeeds.count)
    }
    
    // Convert from TestResultEntity to TestResults
    func toTestResults() -> TestResults {
        return TestResults(
            downloadSpeed: self.downloadSpeed,
            uploadSpeed: self.uploadSpeed,
            downloadHistory: self.downloadHistory,
            uploadHistory: self.uploadHistory,
            ping: Int(self.ping),
            jitter: Int(self.jitter),
            packetLoss: Int(self.packetLoss),
            serverName: self.serverName ?? "Unknown",
            serverLocation: self.serverLocation ?? "Unknown",
            connectionType: self.connectionType ?? "Unknown",
            providerName: self.providerName ?? "Unknown",
            internalIP: self.internalIP ?? "N/A",
            externalIP: self.externalIP ?? "N/A",
            testDate: self.testDate ?? Date()
        )
    }
    
    static func delete(_ entity: TestResultEntity) {
        let context = PersistenceController.shared.container.viewContext
        context.delete(entity)
        
        do {
            try context.save()
            print("🗑️ Deleted TestResultEntity (id: \(entity.id?.uuidString ?? "nil"))")
        } catch {
            print("❌ Failed to delete TestResultEntity: \(error.localizedDescription)")
            context.rollback()
        }
    }
    
    static func fetchAll(
        sortedByDate: Bool = true
    ) -> [TestResultEntity] {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<TestResultEntity> = TestResultEntity.fetchRequest()
        
        if sortedByDate {
            let sortDescriptor = NSSortDescriptor(key: #keyPath(TestResultEntity.testDate), ascending: false)
            request.sortDescriptors = [sortDescriptor]
        }
        
        do {
            return try context.fetch(request)
        } catch {
            print("⚠️ Failed to fetch TestResultEntity: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Make SpeedDataPoint Codable
extension SpeedDataPoint: Codable {
    enum CodingKeys: String, CodingKey {
        case index, speed
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(speed, forKey: .speed)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let index = try container.decode(Int.self, forKey: .index)
        let speed = try container.decode(Double.self, forKey: .speed)
        self.init(index: index, speed: speed)
    }
}
