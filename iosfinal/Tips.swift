import TipKit

struct ChangeCityTip: Tip {
    var title: Text {
        Text("切換城市")
    }
    
    var message: Text? {
        Text("點擊這裡可以切換不同的城市來查看天氣。")
    }
    
    var image: Image? {
        Image(systemName: "location.fill")
    }
}

struct AIInsightTip: Tip {
    var title: Text {
        Text("AI 智能分析")
    }
    
    var message: Text? {
        Text("這是由 AI 提供的天氣分析與建議，幫助您更好地規劃行程。")
    }
    
    var image: Image? {
        Image(systemName: "sparkles")
    }
}

struct DistrictPickerTip: Tip {
    var title: Text {
        Text("選擇行政區")
    }
    
    var message: Text? {
        Text("您可以進一步選擇特定的行政區來獲取更精確的天氣資訊。")
    }
    
    var image: Image? {
        Image(systemName: "map.fill")
    }
}
