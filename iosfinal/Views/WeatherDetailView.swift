import SwiftUI
import Lottie

struct WeatherDetailView: View {
    let weatherData: WeatherData
    
    // 根據天氣狀況取得對應的動畫名稱
    private var weatherAnimationName: String {
        let condition = weatherData.condition?.lowercased() ?? ""
        if condition.contains("雨") {
            return "weather-rainy"
        } else if condition.contains("雲") || condition.contains("陰") {
            return "weather-cloudy"
        } else if condition.contains("雪") {
            return "weather-snow"
        } else {
            return "weather-sunny"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(weatherData.fullLocationName)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("更新時間: \(formatTime(weatherData.timestamp))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(.bottom, 8)
            
            Divider()
            
            // Temperature Card with Lottie Animation
            HStack(spacing: 16) {
                // Lottie 天氣動畫
                WeatherAnimationView(animationName: weatherAnimationName)
                    .frame(width: 100, height: 100)
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("溫度", systemImage: "thermometer")
                        .font(.headline)
                    HStack {
                        Text(weatherData.temperatureDisplay)
                            .font(.system(size: 40, weight: .bold))
                        Text("°C")
                            .font(.headline)
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            // Weather Grid
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    WeatherDetailCard(
                        title: "天氣狀況",
                        value: weatherData.condition ?? "晴朗",
                        icon: "cloud.sun.fill"
                    )
                    
                    WeatherDetailCard(
                        title: "降雨機率",
                        value: (weatherData.rainProbability ?? "0") + "%",
                        icon: "drop.fill"
                    )
                }
                
                HStack(spacing: 12) {
                    if let windSpeed = weatherData.windSpeed {
                        WeatherDetailCard(
                            title: "風速",
                            value: windSpeed + " m/s",
                            icon: "wind"
                        )
                    } else {
                        WeatherDetailCard(
                            title: "舒適度",
                            value: weatherData.comfort ?? "--",
                            icon: "figure.walk"
                        )
                    }
                    
                    WeatherDetailCard(
                        title: "濕度",
                        value: (weatherData.humidity ?? "--") + "%",
                        icon: "humidity.fill"
                    )
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct WeatherDetailCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    WeatherDetailView(
        weatherData: WeatherData(
            location: "基隆市",
            district: "中正區",
            minTemperature: "18",
            maxTemperature: "22",
            rainProbability: "30",
            condition: "陰",
            comfort: "稍有寒意",
            humidity: "75",
            windSpeed: "6",
            timestamp: Date()
        )
    )
}
