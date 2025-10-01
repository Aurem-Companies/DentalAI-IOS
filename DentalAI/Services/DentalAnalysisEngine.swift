import UIKit
import Vision
import CoreML

class DentalAnalysisEngine: ObservableObject {
    private let imageProcessor = ImageProcessor()
    
    // MARK: - Main Analysis Function
    func analyzeDentalImage(_ image: UIImage) async -> DentalAnalysisResult {
        // Step 1: Image Quality Assessment
        let imageQuality = imageProcessor.assessImageQuality(image)
        
        // Step 2: Image Enhancement
        let enhancedImage = imageProcessor.enhanceImage(image) ?? image
        
        // Step 3: Color Analysis
        let colorAnalysis = imageProcessor.analyzeToothColor(enhancedImage)
        
        // Step 4: Condition Detection
        let conditions = await detectDentalConditions(enhancedImage, colorAnalysis: colorAnalysis)
        
        // Step 5: Severity Assessment
        let severity = assessOverallSeverity(conditions)
        
        // Step 6: Generate Recommendations
        let recommendations = generateRecommendations(conditions: conditions, severity: severity, colorAnalysis: colorAnalysis)
        
        // Step 7: Calculate Confidence
        let confidence = calculateConfidence(conditions: conditions, imageQuality: imageQuality)
        
        return DentalAnalysisResult(
            conditions: conditions,
            confidence: confidence,
            severity: severity,
            recommendations: recommendations,
            timestamp: Date(),
            image: image
        )
    }
    
    // MARK: - Condition Detection
    private func detectDentalConditions(_ image: UIImage, colorAnalysis: ToothColorAnalysis) async -> [DentalCondition] {
        var detectedConditions: [DentalCondition] = []
        
        // Rule-based detection
        let ruleBasedConditions = detectConditionsByRules(image, colorAnalysis: colorAnalysis)
        detectedConditions.append(contentsOf: ruleBasedConditions)
        
        // ML-based detection (placeholder for future implementation)
        let mlConditions = await detectConditionsByML(image)
        detectedConditions.append(contentsOf: mlConditions)
        
        // Remove duplicates and return
        return Array(Set(detectedConditions))
    }
    
    // MARK: - Rule-Based Detection
    private func detectConditionsByRules(_ image: UIImage, colorAnalysis: ToothColorAnalysis) -> [DentalCondition] {
        var conditions: [DentalCondition] = []
        
        // Color-based detection
        switch colorAnalysis.dominantColor {
        case .black:
            conditions.append(.deadTooth)
        case .brown, .darkYellow:
            conditions.append(.discoloration)
            if colorAnalysis.healthiness < 0.3 {
                conditions.append(.cavity)
            }
        case .yellow, .lightYellow:
            conditions.append(.discoloration)
        case .white, .offWhite:
            // Check for other conditions even with good color
            break
        case .unknown:
            break
        }
        
        // Healthiness-based detection
        if colorAnalysis.healthiness < 0.4 {
            conditions.append(.plaque)
        }
        
        if colorAnalysis.healthiness < 0.2 {
            conditions.append(.tartar)
        }
        
        // Edge detection for structural issues
        if let edgeImage = imageProcessor.detectEdges(image) {
            let edgeAnalysis = analyzeEdges(edgeImage)
            if edgeAnalysis.hasIrregularities {
                conditions.append(.chipped)
            }
            if edgeAnalysis.hasMisalignment {
                conditions.append(.misaligned)
            }
        }
        
        // Texture analysis for gum health
        let textureAnalysis = analyzeTexture(image)
        if textureAnalysis.hasInflammation {
            conditions.append(.gingivitis)
        }
        
        // If no conditions detected, mark as healthy
        if conditions.isEmpty {
            conditions.append(.healthy)
        }
        
        return conditions
    }
    
    // MARK: - ML-Based Detection (Placeholder)
    private func detectConditionsByML(_ image: UIImage) async -> [DentalCondition] {
        // This would integrate with a trained Core ML model
        // For now, return empty array
        return []
    }
    
    // MARK: - Edge Analysis
    private func analyzeEdges(_ edgeImage: UIImage) -> EdgeAnalysis {
        // Simplified edge analysis
        // In a real implementation, this would use computer vision techniques
        
        let brightness = imageProcessor.calculateBrightness(edgeImage)
        let contrast = imageProcessor.calculateContrast(edgeImage)
        
        // High contrast edges might indicate chips or irregularities
        let hasIrregularities = contrast > 0.3
        
        // Check for symmetry (simplified)
        let hasMisalignment = brightness < 0.1 // Very dark edges might indicate misalignment
        
        return EdgeAnalysis(
            hasIrregularities: hasIrregularities,
            hasMisalignment: hasMisalignment,
            edgeStrength: contrast
        )
    }
    
    // MARK: - Texture Analysis
    private func analyzeTexture(_ image: UIImage) -> TextureAnalysis {
        // Simplified texture analysis for gum health
        let contrast = imageProcessor.calculateContrast(image)
        let blur = imageProcessor.calculateBlur(image)
        
        // High contrast with low blur might indicate inflammation
        let hasInflammation = contrast > 0.4 && blur < 0.3
        
        return TextureAnalysis(
            hasInflammation: hasInflammation,
            smoothness: 1.0 - blur,
            contrast: contrast
        )
    }
    
    // MARK: - Severity Assessment
    private func assessOverallSeverity(_ conditions: [DentalCondition]) -> SeverityLevel {
        let severities = conditions.map { $0.severity }
        
        if severities.contains(.high) {
            return .high
        } else if severities.contains(.medium) {
            return .medium
        } else if severities.contains(.low) {
            return .low
        } else {
            return .none
        }
    }
    
    // MARK: - Confidence Calculation
    private func calculateConfidence(conditions: [DentalCondition], imageQuality: ImageQuality) -> Double {
        var confidence = 0.8 // Base confidence
        
        // Adjust based on image quality
        confidence *= Double(imageQuality.score) / 100.0
        
        // Adjust based on number of conditions detected
        if conditions.count > 3 {
            confidence *= 0.9 // Slightly lower confidence for many conditions
        }
        
        // Adjust based on condition types
        if conditions.contains(.healthy) && conditions.count == 1 {
            confidence *= 1.1 // Higher confidence for clear healthy result
        }
        
        return min(1.0, max(0.0, confidence))
    }
    
    // MARK: - Recommendation Generation
    private func generateRecommendations(conditions: [DentalCondition], severity: SeverityLevel, colorAnalysis: ToothColorAnalysis) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // Generate recommendations based on detected conditions
        for condition in conditions {
            recommendations.append(contentsOf: getRecommendationsForCondition(condition))
        }
        
        // Add general recommendations based on severity
        recommendations.append(contentsOf: getGeneralRecommendations(severity: severity))
        
        // Add color-specific recommendations
        recommendations.append(contentsOf: getColorBasedRecommendations(colorAnalysis))
        
        // Remove duplicates and sort by priority
        let uniqueRecommendations = Array(Set(recommendations))
        return uniqueRecommendations.sorted { $0.priority.rawValue < $1.priority.rawValue }
    }
    
    private func getRecommendationsForCondition(_ condition: DentalCondition) -> [Recommendation] {
        switch condition {
        case .cavity:
            return [
                Recommendation(
                    title: "Schedule Dental Appointment",
                    description: "Cavities require professional treatment to prevent further damage.",
                    priority: .immediate,
                    category: .professional,
                    actionItems: ["Call your dentist within 24 hours", "Avoid sugary foods", "Use fluoride toothpaste"]
                ),
                Recommendation(
                    title: "Improve Oral Hygiene",
                    description: "Better brushing and flossing can prevent new cavities.",
                    priority: .urgent,
                    category: .homeCare,
                    actionItems: ["Brush twice daily with fluoride toothpaste", "Floss daily", "Use mouthwash"]
                )
            ]
            
        case .gingivitis:
            return [
                Recommendation(
                    title: "Improve Gum Care",
                    description: "Gingivitis can be reversed with proper oral hygiene.",
                    priority: .urgent,
                    category: .homeCare,
                    actionItems: ["Brush gently along gum line", "Use soft-bristled toothbrush", "Floss daily", "Use antiseptic mouthwash"]
                ),
                Recommendation(
                    title: "Professional Cleaning",
                    description: "Professional cleaning can remove plaque and tartar buildup.",
                    priority: .important,
                    category: .professional,
                    actionItems: ["Schedule dental cleaning", "Ask about deep cleaning if needed"]
                )
            ]
            
        case .discoloration:
            return [
                Recommendation(
                    title: "Teeth Whitening",
                    description: "Professional whitening can restore your smile's brightness.",
                    priority: .important,
                    category: .products,
                    actionItems: ["Consider professional whitening", "Use whitening toothpaste", "Avoid staining foods"]
                ),
                Recommendation(
                    title: "Lifestyle Changes",
                    description: "Reduce consumption of staining substances.",
                    priority: .general,
                    category: .lifestyle,
                    actionItems: ["Limit coffee and tea", "Quit smoking", "Drink water after meals"]
                )
            ]
            
        case .plaque:
            return [
                Recommendation(
                    title: "Better Brushing Technique",
                    description: "Proper brushing can remove plaque buildup.",
                    priority: .urgent,
                    category: .homeCare,
                    actionItems: ["Brush for 2 minutes twice daily", "Use circular motions", "Don't forget to brush tongue"]
                )
            ]
            
        case .tartar:
            return [
                Recommendation(
                    title: "Professional Cleaning Required",
                    description: "Tartar cannot be removed at home and requires professional treatment.",
                    priority: .immediate,
                    category: .professional,
                    actionItems: ["Schedule dental cleaning immediately", "Ask about scaling and root planing"]
                )
            ]
            
        case .deadTooth:
            return [
                Recommendation(
                    title: "Emergency Dental Care",
                    description: "A dead tooth requires immediate professional attention.",
                    priority: .immediate,
                    category: .emergency,
                    actionItems: ["Call dentist immediately", "Consider root canal treatment", "Monitor for pain or swelling"]
                )
            ]
            
        case .chipped:
            return [
                Recommendation(
                    title: "Dental Repair",
                    description: "Chipped teeth should be evaluated by a dentist.",
                    priority: .urgent,
                    category: .professional,
                    actionItems: ["Schedule dental appointment", "Avoid hard foods", "Use dental wax if sharp"]
                )
            ]
            
        case .misaligned:
            return [
                Recommendation(
                    title: "Orthodontic Consultation",
                    description: "Misaligned teeth can be corrected with orthodontic treatment.",
                    priority: .important,
                    category: .professional,
                    actionItems: ["Consult with orthodontist", "Consider braces or aligners", "Maintain good oral hygiene"]
                )
            ]
            
        case .healthy:
            return [
                Recommendation(
                    title: "Maintain Good Oral Health",
                    description: "Keep up your excellent oral hygiene routine.",
                    priority: .general,
                    category: .homeCare,
                    actionItems: ["Continue regular brushing and flossing", "Schedule regular dental checkups", "Maintain healthy diet"]
                )
            ]
            
        case .rootCanal:
            return [
                Recommendation(
                    title: "Follow-up Care",
                    description: "Root canal treatment requires proper follow-up care.",
                    priority: .important,
                    category: .professional,
                    actionItems: ["Follow dentist's post-treatment instructions", "Take prescribed medications", "Schedule follow-up appointment"]
                )
            ]
        }
    }
    
    private func getGeneralRecommendations(severity: SeverityLevel) -> [Recommendation] {
        switch severity {
        case .high:
            return [
                Recommendation(
                    title: "Immediate Professional Care",
                    description: "Your dental health requires immediate attention from a professional.",
                    priority: .immediate,
                    category: .professional,
                    actionItems: ["Schedule emergency dental appointment", "Monitor for pain or swelling", "Avoid hard foods"]
                )
            ]
        case .medium:
            return [
                Recommendation(
                    title: "Schedule Dental Checkup",
                    description: "Regular dental checkups can prevent minor issues from becoming major problems.",
                    priority: .important,
                    category: .professional,
                    actionItems: ["Schedule appointment within 2 weeks", "Prepare questions for your dentist"]
                )
            ]
        case .low:
            return [
                Recommendation(
                    title: "Preventive Care",
                    description: "Focus on preventive measures to maintain good oral health.",
                    priority: .general,
                    category: .homeCare,
                    actionItems: ["Maintain regular brushing and flossing", "Use fluoride products", "Eat a balanced diet"]
                )
            ]
        case .none:
            return []
        }
    }
    
    private func getColorBasedRecommendations(_ colorAnalysis: ToothColorAnalysis) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        if colorAnalysis.healthiness < 0.5 {
            recommendations.append(
                Recommendation(
                    title: "Improve Oral Hygiene",
                    description: "Better oral hygiene can improve the appearance and health of your teeth.",
                    priority: .important,
                    category: .homeCare,
                    actionItems: ["Brush twice daily", "Floss daily", "Use mouthwash", "Consider professional cleaning"]
                )
            )
        }
        
        return recommendations
    }
}

// MARK: - Supporting Types
struct EdgeAnalysis {
    let hasIrregularities: Bool
    let hasMisalignment: Bool
    let edgeStrength: Double
}

struct TextureAnalysis {
    let hasInflammation: Bool
    let smoothness: Double
    let contrast: Double
}

// MARK: - Extensions for ImageProcessor
extension ImageProcessor {
    func calculateBrightness(_ image: UIImage) -> Double {
        // This would be implemented in the ImageProcessor class
        return 0.5 // Placeholder
    }
    
    func calculateContrast(_ image: UIImage) -> Double {
        // This would be implemented in the ImageProcessor class
        return 0.3 // Placeholder
    }
    
    func calculateBlur(_ image: UIImage) -> Double {
        // This would be implemented in the ImageProcessor class
        return 0.2 // Placeholder
    }
}
