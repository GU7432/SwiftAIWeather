import SwiftUI

struct AIInsightView: View {
    let insight: AIInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with source indicator
            HStack {
                Text("🤖 AI 天氣智能分析")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // 顯示來源（AI 或 規則式）
                Text(insight.sourceLabel)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(insight.isAIGenerated ? Color.purple.opacity(0.2) : Color.gray.opacity(0.2))
                    .foregroundColor(insight.isAIGenerated ? .purple : .gray)
                    .cornerRadius(12)
            }
            
            Divider()
            
            // Summary
            VStack(alignment: .leading, spacing: 8) {
                Label("天氣摘要", systemImage: "doc.text")
                    .font(.headline)
                Text(insight.summary)
                    .font(.body)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Recommendation
            VStack(alignment: .leading, spacing: 8) {
                Label("生活建議", systemImage: "lightbulb.fill")
                    .font(.headline)
                Text(insight.recommendation)
                    .font(.body)
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Clothing Advice
            VStack(alignment: .leading, spacing: 8) {
                Label("穿衣建議", systemImage: "tshirt.fill")
                    .font(.headline)
                Text(insight.clothingAdvice)
                    .font(.body)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Activity Advice
            VStack(alignment: .leading, spacing: 8) {
                Label("活動建議", systemImage: "figure.walk")
                    .font(.headline)
                Text(insight.activityAdvice)
                    .font(.body)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Warning
            if let warning = insight.warning {
                VStack(alignment: .leading, spacing: 8) {
                    Label("⚠️ 警告信息", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(warning)
                        .font(.body)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    AIInsightView(
        insight: AIInsight(
            summary: "晴朗天氣，溫度舒適，降雨機率30%。",
            recommendation: "💧 可能下雨，建議隨身帶傘",
            clothingAdvice: "👕 穿著建議：短袖上衣、薄外套、長褲",
            activityAdvice: "🎉 建議活動：完美的戶外活動天氣！",
            warning: nil,
            isAIGenerated: true
        )
    )
}
