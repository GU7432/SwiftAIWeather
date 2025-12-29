import Foundation
import FoundationModels

class AIService {
    static let shared = AIService()
    
    private var isModelAvailable = false
    private var unavailableReason: String = ""
    
    init() {
        checkModelAvailability()
    }
    
    private func checkModelAvailability() {
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            NSLog("🔍 [AIService] Checking Foundation Model availability...")
            NSLog("🔍 [AIService] Model: %@", String(describing: model))
            
            switch model.availability {
            case .available:
                isModelAvailable = true
                unavailableReason = ""
                NSLog("✅ [AIService] Apple Foundation Model is AVAILABLE!")
                
            case .unavailable(let reason):
                isModelAvailable = false
                // 解析不可用原因 - 直接顯示原始 reason
                unavailableReason = String(describing: reason)
                NSLog("❌ [AIService] Foundation Model UNAVAILABLE: %@", unavailableReason)
                
            @unknown default:
                isModelAvailable = false
                unavailableReason = "未知狀態"
                NSLog("⚠️ [AIService] Unknown availability state")
            }
        } else {
            NSLog("❌ [AIService] iOS < 26, Foundation Models not available")
            isModelAvailable = false
            unavailableReason = "需要 iOS 26.0 或更新版本"
        }
    }
    
    // 公開方法讓 UI 可以取得狀態
    func getAvailabilityStatus() -> (available: Bool, reason: String) {
        return (isModelAvailable, unavailableReason)
    }
    
    func generateInsights(for weatherData: WeatherData) async -> AIInsight {
        let temp = extractTemperature(from: weatherData.minTemperature ?? weatherData.maxTemperature)
        let rainProb = extractProbability(from: weatherData.rainProbability)
        let condition = weatherData.condition ?? "晴朗"
        let humidity = weatherData.humidity ?? "N/A"
        let windSpeed = weatherData.windSpeed ?? "N/A"
        let location = weatherData.fullLocationName
        
        if #available(iOS 26.0, *), isModelAvailable {
            print("🤖 [AIService] Using Apple Foundation Model")
            return await generateWithFoundationModel(
                location: location,
                temperature: temp,
                condition: condition,
                rainProbability: rainProb,
                humidity: humidity,
                windSpeed: windSpeed
            )
        } else {
            print("📋 [AIService] Using rule-based generation (AI not available)")
            return generateWithRules(
                temperature: temp,
                condition: condition,
                rainProbability: rainProb
            )
        }
    }
    
    @available(iOS 26.0, *)
    private func generateWithFoundationModel(
        location: String,
        temperature: Double,
        condition: String,
        rainProbability: Int,
        humidity: String,
        windSpeed: String
    ) async -> AIInsight {
        
        let summaryPrompt = "你是專業天氣播報員。地點：\(location)，天氣：\(condition)，溫度：\(Int(temperature))°C，降雨機率：\(rainProbability)%。用一句話描述，不超過25字，開頭加emoji。"
        
        let recommendPrompt = "你是生活顧問。天氣：\(condition)，\(Int(temperature))°C，降雨\(rainProbability)%。給2-3條建議，每條前加emoji。"
        
        let clothingPrompt = "你是穿搭顧問。溫度：\(Int(temperature))°C，天氣：\(condition)。分別建議上衣、下身、鞋子，每項前加emoji。"
        
        let activityPrompt = "你是活動規劃師。溫度：\(Int(temperature))°C，天氣：\(condition)，降雨\(rainProbability)%。推薦2-3項活動，每項前加emoji。"
        
        let warningPrompt = "你是氣象安全專家。溫度：\(Int(temperature))°C，天氣：\(condition)，降雨\(rainProbability)%。如有極端天氣用警告符號警告，否則回答天氣良好。"
        
        async let s = queryLLM(prompt: summaryPrompt)
        async let r = queryLLM(prompt: recommendPrompt)
        async let c = queryLLM(prompt: clothingPrompt)
        async let a = queryLLM(prompt: activityPrompt)
        async let w = queryLLM(prompt: warningPrompt)
        
        let (summary, recommend, clothing, activity, warning) = await (s, r, c, a, w)
        
        return AIInsight(
            summary: summary ?? "今日\(condition)，\(Int(temperature))°C",
            recommendation: recommend ?? "享受美好的一天！",
            clothingAdvice: clothing ?? "請根據溫度適當穿著",
            activityAdvice: activity ?? "適合各種活動",
            warning: warning,
            isAIGenerated: true  // ✅ 使用 Foundation Model
        )
    }
    
    @available(iOS 26.0, *)
    private func queryLLM(prompt: String) async -> String? {
        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            print("Foundation Model Error: \(error)")
            return nil
        }
    }
    
    private func generateWithRules(temperature: Double, condition: String, rainProbability: Int) -> AIInsight {
        let summary = generateRuleSummary(temperature: temperature, condition: condition, rainProbability: rainProbability)
        let recommendation = generateRuleRecommendation(temperature: temperature, rainProbability: rainProbability)
        let clothing = generateRuleClothing(temperature: temperature)
        let activity = generateRuleActivity(temperature: temperature, rainProbability: rainProbability)
        let warning = generateRuleWarning(temperature: temperature, condition: condition, rainProbability: rainProbability)
        
        return AIInsight(
            summary: summary,
            recommendation: recommendation,
            clothingAdvice: clothing,
            activityAdvice: activity,
            warning: warning,
            isAIGenerated: false  // ❌ 使用規則式
        )
    }
    
    private func generateRuleSummary(temperature: Double, condition: String, rainProbability: Int) -> String {
        var emoji = "☀️"
        if condition.contains("雨") {
            emoji = "🌧️"
        } else if condition.contains("雲") || condition.contains("陰") {
            emoji = "☁️"
        } else if condition.contains("晴") {
            emoji = "☀️"
        }
        return "\(emoji) 今日\(condition)，氣溫 \(Int(temperature))°C，降雨機率 \(rainProbability)%"
    }
    
    private func generateRuleRecommendation(temperature: Double, rainProbability: Int) -> String {
        var recommendations: [String] = []
        if rainProbability > 50 {
            recommendations.append("🌂 記得攜帶雨具")
        }
        if temperature > 30 {
            recommendations.append("💧 多補充水分")
            recommendations.append("🧴 做好防曬措施")
        } else if temperature < 15 {
            recommendations.append("🧥 注意保暖")
        }
        if rainProbability < 30 && temperature >= 20 && temperature <= 28 {
            recommendations.append("🚶 適合外出散步")
        }
        if recommendations.isEmpty {
            recommendations.append("😊 享受美好的一天！")
        }
        return recommendations.joined(separator: "\n")
    }
    
    private func generateRuleClothing(temperature: Double) -> String {
        if temperature > 30 {
            return "👕 上衣：輕薄透氣短袖\n👖 下身：短褲或裙子\n👟 鞋子：涼鞋或透氣鞋"
        } else if temperature > 25 {
            return "👕 上衣：短袖 T-shirt\n👖 下身：長褲或短褲\n👟 鞋子：運動鞋"
        } else if temperature > 20 {
            return "👔 上衣：薄長袖\n👖 下身：長褲\n👟 鞋子：休閒鞋"
        } else if temperature > 15 {
            return "🧥 上衣：外套 + 長袖\n👖 下身：長褲\n👟 鞋子：包鞋"
        } else {
            return "🧥 上衣：厚外套 + 毛衣\n👖 下身：厚長褲\n🧣 配件：圍巾、手套"
        }
    }
    
    private func generateRuleActivity(temperature: Double, rainProbability: Int) -> String {
        if rainProbability > 60 {
            return "🏠 室內活動：看電影、逛商場\n📚 閱讀或學習新技能\n🎮 居家娛樂"
        } else if temperature > 30 {
            return "🏊 游泳消暑\n🛒 室內購物\n☕ 咖啡廳休憩"
        } else if temperature > 20 {
            return "🚴 騎單車\n🥾 戶外健行\n📸 拍照打卡"
        } else {
            return "♨️ 泡溫泉\n🍜 享用熱食\n🏃 室內運動"
        }
    }
    
    private func generateRuleWarning(temperature: Double, condition: String, rainProbability: Int) -> String? {
        var warnings: [String] = []
        if temperature > 35 {
            warnings.append("⚠️ 高溫警報：注意防曬補水，避免中暑")
        }
        if temperature < 10 {
            warnings.append("⚠️ 低溫警報：注意保暖，預防感冒")
        }
        if rainProbability > 70 {
            warnings.append("⚠️ 降雨警報：外出請攜帶雨具")
        }
        if condition.contains("颱風") || condition.contains("暴雨") || condition.contains("大雨") {
            warnings.append("⚠️ 極端天氣：建議減少外出")
        }
        if warnings.isEmpty {
            return "✅ 天氣狀況良好，無需特別注意"
        }
        return warnings.joined(separator: "\n")
    }
    
    private func extractTemperature(from tempString: String?) -> Double {
        guard let tempString = tempString, let temp = Double(tempString) else {
            return 25.0
        }
        return temp
    }
    
    private func extractProbability(from probString: String?) -> Int {
        guard let probString = probString, let prob = Int(probString) else {
            return 0
        }
        return prob
    }
}
