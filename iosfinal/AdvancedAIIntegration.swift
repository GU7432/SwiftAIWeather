//import Foundation

/// ============================================
/// 高級 AI 集成指南
/// 使用 OpenAI API 進行更智能的天氣分析
/// ============================================

/*
 ### 步驟 1: 安裝 OpenAI SDK
 
 在 Package.swift 或通過 Xcode 添加：
 
 .package(url: "https://github.com/MacPaw/OpenAI.git", .upToNextMinor(from: "0.1.0"))
 
 
 ### 步驟 2: 修改 AIService 以支持 OpenAI
 
 示例代碼（可選實現）：
 
 import OpenAI
 
 class AdvancedAIService {
     private let openAIClient = OpenAI(apiToken: "sk-your-api-key")
     
     func generateAdvancedInsight(weatherData: WeatherData) async -> String {
         let prompt = """
         根據以下天氣信息，給出專業的生活建議：
         
         地點: \(weatherData.location)
         溫度: \(weatherData.temperature ?? "未知")°C
         降雨機率: \(weatherData.rainProbability ?? "未知")%
         天氣狀況: \(weatherData.condition ?? "未知")
         
         請提供：
         1. 簡短的天氣總結
         2. 穿衣建議
         3. 戶外活動建議
         4. 健康提示
         """
         
         let query = ChatQuery(
             messages: [
                 .init(role: .user, content: prompt)
             ],
             model: .gpt3_5Turbo
         )
         
         let result = try await openAIClient.chats(query: query)
         return result.choices.first?.message.content ?? "無法生成建議"
     }
 }
 
 
 ### 步驟 3: 在應用中使用高級 AI
 
 class EnhancedWeatherViewModel: ObservableObject {
     private let advancedAI = AdvancedAIService()
     
     func fetchWithAdvancedAI(for location: String) async {
         let weather = try await weatherService.fetchWeatherForecast(for: location)
         let aiResponse = await advancedAI.generateAdvancedInsight(weatherData: weather)
         // 更新 UI
     }
 }
 
 
 ### 當前實現特點
 
 ✅ 優點：
 - 完全本地邏輯，無需外部 API
 - 快速響應（毫秒級）
 - 可靠且可控
 - 無隱私風險
 
 ⚠️ 局限：
 - 規則固定，不夠智能
 - 無法理解複雜情境
 - 無法生成自然語言響應
 
 
 ### 混合方案建議
 
 1. 保留本地規則（快速反應）
 2. 異步調用 OpenAI（深度分析）
 3. 給用戶兩種選項
 
 @Published var basicInsight: AIInsight?     // 本地規則
 @Published var advancedInsight: String?     // OpenAI 結果
 @Published var isLoadingAdvanced = false
 
 func loadAdvancedAnalysis() async {
     isLoadingAdvanced = true
     advancedInsight = await advancedAI.generateAdvancedInsight(...)
     isLoadingAdvanced = false
 }
 */
