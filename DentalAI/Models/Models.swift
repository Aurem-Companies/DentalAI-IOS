import Foundation
import UIKit

// MARK: - Dental Conditions
enum DentalCondition: String, CaseIterable, Identifiable {
    case cavity = "Cavity"
    case gingivitis = "Gingivitis"
    case discoloration = "Discoloration"
    case plaque = "Plaque"
    case tartar = "Tartar"
    case deadTooth = "Dead Tooth"
    case rootCanal = "Root Canal"
    case chipped = "Chipped Tooth"
    case misaligned = "Misaligned Teeth"
    case healthy = "Healthy"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .cavity:
            return "Tooth decay caused by bacteria"
        case .gingivitis:
            return "Inflammation of the gums"
        case .discoloration:
            return "Staining or yellowing of teeth"
        case .plaque:
            return "Bacterial film on teeth"
        case .tartar:
            return "Hardened plaque buildup"
        case .deadTooth:
            return "Non-vital tooth with no blood supply"
        case .rootCanal:
            return "Treatment for infected tooth pulp"
        case .chipped:
            return "Broken or damaged tooth structure"
        case .misaligned:
            return "Teeth that are not properly aligned"
        case .healthy:
            return "Good oral health"
        }
    }
    
    var severity: SeverityLevel {
        switch self {
        case .cavity, .deadTooth, .rootCanal:
            return .high
        case .gingivitis, .tartar, .chipped:
            return .medium
        case .discoloration, .plaque, .misaligned:
            return .low
        case .healthy:
            return .none
        }
    }
}

// MARK: - Severity Levels
enum SeverityLevel: String, CaseIterable {
    case none = "None"
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var color: String {
        switch self {
        case .none:
            return "green"
        case .low:
            return "yellow"
        case .medium:
            return "orange"
        case .high:
            return "red"
        }
    }
}

// MARK: - Analysis Result
struct DentalAnalysisResult: Identifiable {
    let id = UUID()
    let conditions: [DentalCondition]
    let confidence: Double
    let severity: SeverityLevel
    let recommendations: [Recommendation]
    let timestamp: Date
    let image: UIImage?
    
    var primaryCondition: DentalCondition {
        conditions.first ?? .healthy
    }
    
    var overallHealthScore: Int {
        let baseScore = 100
        let penalty = conditions.reduce(0) { total, condition in
            total + condition.severity.penalty
        }
        return max(0, baseScore - penalty)
    }
}

extension SeverityLevel {
    var penalty: Int {
        switch self {
        case .none: return 0
        case .low: return 10
        case .medium: return 25
        case .high: return 50
        }
    }
}

// MARK: - Recommendations
struct Recommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let priority: Priority
    let category: RecommendationCategory
    let actionItems: [String]
    
    enum Priority: String, CaseIterable {
        case immediate = "Immediate"
        case urgent = "Urgent"
        case important = "Important"
        case general = "General"
        
        var color: String {
            switch self {
            case .immediate: return "red"
            case .urgent: return "orange"
            case .important: return "yellow"
            case .general: return "blue"
            }
        }
    }
    
    enum RecommendationCategory: String, CaseIterable {
        case homeCare = "Home Care"
        case professional = "Professional Care"
        case lifestyle = "Lifestyle Changes"
        case products = "Product Recommendations"
        case emergency = "Emergency Care"
    }
}

// MARK: - User Profile
struct UserProfile: Identifiable {
    let id = UUID()
    var name: String
    var age: Int
    var dentalHistory: [DentalAnalysisResult]
    var preferences: UserPreferences
    
    var lastAnalysis: DentalAnalysisResult? {
        dentalHistory.last
    }
    
    var healthTrend: HealthTrend {
        guard dentalHistory.count >= 2 else { return .stable }
        
        let recent = dentalHistory.suffix(3)
        let scores = recent.map { $0.overallHealthScore }
        
        if scores.isIncreasing {
            return .improving
        } else if scores.isDecreasing {
            return .declining
        } else {
            return .stable
        }
    }
}

struct UserPreferences {
    var notificationsEnabled: Bool = true
    var reminderFrequency: ReminderFrequency = .weekly
    var preferredLanguage: String = "en"
    var shareDataWithDentist: Bool = false
}

enum ReminderFrequency: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case never = "Never"
}

enum HealthTrend: String {
    case improving = "Improving"
    case stable = "Stable"
    case declining = "Declining"
}

// MARK: - Extensions
extension Array where Element == Int {
    var isIncreasing: Bool {
        guard count >= 2 else { return false }
        for i in 1..<count {
            if self[i] <= self[i-1] { return false }
        }
        return true
    }
    
    var isDecreasing: Bool {
        guard count >= 2 else { return false }
        for i in 1..<count {
            if self[i] >= self[i-1] { return false }
        }
        return true
    }
}
