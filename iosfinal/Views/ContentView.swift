import SwiftUI
import TipKit
import Shimmer

// MARK: - Animation Views
// 由於 AnimationViews.swift 可能未被正確加入專案，將其內容移至此處以確保編譯通過

import Lottie

/// Lottie 天氣動畫視圖
/// 根據天氣狀況顯示對應的動畫效果
struct WeatherAnimationView: View {
    let animationName: String
    
    var body: some View {
        // 嘗試載入 Lottie 動畫，如果失敗則顯示 SF Symbol
        if let animation = LottieAnimation.named(animationName) {
            LottieView(animation: animation)
                .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                .animationSpeed(0.8)
        } else {
            // 備用的 SF Symbol 圖示
            Image(systemName: fallbackIcon)
                .font(.system(size: 80))
                .foregroundColor(.blue)
        }
    }
    
    private var fallbackIcon: String {
        switch animationName {
        case "weather-sunny":
            return "sun.max.fill"
        case "weather-rainy":
            return "cloud.rain.fill"
        case "weather-cloudy":
            return "cloud.fill"
        case "weather-snow":
            return "cloud.snow.fill"
        default:
            return "cloud.sun.fill"
        }
    }
}

/// AI 分析骨架屏視圖
/// 在等待 AI 生成內容時顯示閃爍的佔位卡片
struct AIInsightSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header 骨架
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 180, height: 24)
                Spacer()
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 24)
            }
            
            Divider()
            
            // 天氣摘要骨架
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 18)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
                    .frame(height: 60)
            }
            
            // 生活建議骨架
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 18)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.yellow.opacity(0.1))
                    .frame(height: 80)
            }
            
            // 穿衣建議骨架
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 18)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.1))
                    .frame(height: 60)
            }
            
            // 活動建議骨架
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 18)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.1))
                    .frame(height: 60)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = WeatherViewModel()
    @State private var showingLocationPicker = false
    
    // Tips
    private let changeCityTip = ChangeCityTip()
    private let aiInsightTip = AIInsightTip()
    private let districtPickerTip = DistrictPickerTip()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.cyan.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("天氣應用")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("AI 智能天氣助手")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            
                            // City Picker
                            Menu {
                                ForEach(viewModel.popularLocations, id: \.self) { location in
                                    Button {
                                        Task {
                                            await viewModel.changeCity(to: location)
                                        }
                                    } label: {
                                        Label(location, systemImage: "mappin.circle.fill")
                                    }
                                }
                            } label: {
                                Label(viewModel.selectedLocation, systemImage: "location.fill")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.3))
                                    .cornerRadius(8)
                            }
                            .popoverTip(changeCityTip, arrowEdge: .top)
                        }
                        .padding()
                        
                        // District Picker (if available)
                        if !viewModel.availableDistricts.isEmpty {
                            HStack {
                                Text("選擇區域")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Menu {
                                    Button {
                                        Task {
                                            await viewModel.changeDistrict(to: nil)
                                        }
                                    } label: {
                                        Label("全部區域", systemImage: "map")
                                    }
                                    
                                    Divider()
                                    
                                    ForEach(viewModel.availableDistricts, id: \.self) { district in
                                        Button {
                                            Task {
                                                await viewModel.changeDistrict(to: district)
                                            }
                                        } label: {
                                            HStack {
                                                Text(district)
                                                if viewModel.selectedDistrict == district {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(viewModel.selectedDistrict ?? "選擇區域")
                                        Image(systemName: "chevron.down")
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                                }
                                .popoverTip(districtPickerTip, arrowEdge: .top)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                    }
                    .background(Color.white.opacity(0.95))
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .padding(.top, 40)
                            } else if let errorMessage = viewModel.errorMessage {
                                VStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.circle")
                                        .font(.title)
                                        .foregroundColor(.red)
                                    Text("出現錯誤")
                                        .font(.headline)
                                    Text(errorMessage)
                                        .font(.body)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            } else if let weather = viewModel.weatherData {
                                // Weather Details
                                VStack(spacing: 16) {
                                    WeatherDetailView(weatherData: weather)
                                        .id(weather.fullLocationName) // 強制在位置改變時重新渲染
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .shadow(radius: 4)
                                    
                                    // AI Insights
                                    if viewModel.isGeneratingAI {
                                        // Shimmer 骨架屏效果
                                        AIInsightSkeletonView()
                                            .shimmering()
                                    } else if let insight = viewModel.aiInsight {
                                        VStack(spacing: 12) {
                                            TipView(aiInsightTip)
                                                .padding(.horizontal)
                                            
                                            AIInsightView(insight: insight)
                                                .background(Color.white)
                                                .cornerRadius(12)
                                                .shadow(radius: 4)
                                        }
                                    }
                                }
                            } else {
                                VStack(spacing: 16) {
                                    Image(systemName: "cloud.circle")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                    Text("點擊刷新獲取天氣數據")
                                        .font(.headline)
                                }
                                .padding(.top, 40)
                            }
                        }
                        .padding()
                    }
                    
                    // Refresh Button
                    Button(action: {
                        Task {
                            await viewModel.refresh()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("刷新天氣")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.isLoading)
                    .padding()
                }
            }
        }
        .task {
            // 初始化時載入區域列表並取得天氣
            await viewModel.loadDistrictsForCity(viewModel.selectedLocation)
            await viewModel.fetchWeatherAndInsights(for: viewModel.selectedLocation)
        }
    }
}

#Preview {
    ContentView()
}
