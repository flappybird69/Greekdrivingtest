import Foundation
import SwiftData

// MARK: - Category

enum QuestionCategory: String, CaseIterable, Codable {
    case signs    = "signs"
    case rules    = "rules"
    case behavior = "behavior"
    case vehicle  = "vehicle"
    case firstAid = "firstAid"

    func name(greek: Bool) -> String {
        switch self {
        case .signs:    return greek ? "Πινακίδες"              : "Road Signs"
        case .rules:    return greek ? "Κανόνες Κυκλοφορίας"   : "Traffic Rules"
        case .behavior: return greek ? "Οδική Συμπεριφορά"     : "Road Behavior"
        case .vehicle:  return greek ? "Όχημα & Περιβάλλον"    : "Vehicle & Environment"
        case .firstAid: return greek ? "Πρώτες Βοήθειες"       : "First Aid"
        }
    }

    var icon: String {
        switch self {
        case .signs:    return "signpost.right.fill"
        case .rules:    return "road.lanes"
        case .behavior: return "person.fill.checkmark"
        case .vehicle:  return "car.fill"
        case .firstAid: return "cross.fill"
        }
    }
}

// MARK: - Traffic Sign Types

enum TrafficSignType: Equatable {
    // Warning (triangle)
    case warningGeneral, warningCrossroads, warningPedestrian, warningSlippery
    case warningTwoWay, warningRailway, warningCurveLeft, warningCurveRight
    case warningNarrowRoad, warningRoadworks, warningAnimals, warningChildren

    // Prohibition (circle + red border)
    case noEntry, noOvertaking, noHorns, noParking, noStopping
    case speedLimit(Int), endSpeedLimit(Int), endNoOvertaking, endRestrictions

    // Obligation (blue circle)
    case roundabout, mandatoryRight, mandatoryLeft, mandatoryStraight
    case mandatoryBicycle, pedestrianOnly, minSpeed(Int)

    // Priority
    case stop, giveWay, priorityRoad, endPriorityRoad
    case priorityOverOncoming, giveWayToOncoming

    // Information (blue rectangle)
    case motorway, endMotorway, oneWay, parking
}

// MARK: - Question Visual

enum QuestionVisual {
    case none
    case trafficSign(TrafficSignType)
    case scenario(sfSymbol: String, colorName: String)
    case image(named: String)
}

// MARK: - Question

struct Question: Identifiable {
    let id: Int
    let textGR: String
    let textEN: String
    let category: QuestionCategory
    let optionsGR: [String]
    let optionsEN: [String]
    let correctIndex: Int
    let explanationGR: String
    let explanationEN: String
    let visual: QuestionVisual

    func text(greek: Bool)        -> String { greek ? textGR : textEN }
    func options(greek: Bool)     -> [String] { greek ? optionsGR : optionsEN }
    func explanation(greek: Bool) -> String { greek ? explanationGR : explanationEN }
}

// MARK: - SwiftData Persistence

@Model
final class TestResult {
    var date: Date = Date()
    var score: Int = 0
    var totalQuestions: Int = 30
    var passed: Bool = false
    var timeElapsed: TimeInterval = 0
    var wrongQuestionIds: [Int] = []

    init(score: Int, totalQuestions: Int = 30, passed: Bool,
         timeElapsed: TimeInterval, wrongQuestionIds: [Int]) {
        self.date = Date()
        self.score = score
        self.totalQuestions = totalQuestions
        self.passed = passed
        self.timeElapsed = timeElapsed
        self.wrongQuestionIds = wrongQuestionIds
    }

    var percentage: Double { Double(score) / Double(totalQuestions) * 100 }
    var errors: Int { totalQuestions - score }
}

@Model
final class BookmarkedQuestion {
    var questionId: Int = 0
    var dateAdded: Date = Date()

    init(questionId: Int) {
        self.questionId = questionId
        self.dateAdded = Date()
    }
}

@Model
final class DifficultQuestion {
    var questionId: Int = 0
    var dateAdded: Date = Date()

    init(questionId: Int) {
        self.questionId = questionId
        self.dateAdded = Date()
    }
}
