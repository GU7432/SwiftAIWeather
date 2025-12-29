import Foundation
import Combine

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var weatherData: WeatherData?
    @Published var aiInsight: AIInsight?
    @Published var isLoading = false
    @Published var isGeneratingAI = false
    @Published var errorMessage: String?
    @Published var selectedLocation = "臺北市"
    @Published var selectedDistrict: String? = nil
    @Published var availableDistricts: [String] = []
    @Published var useDetailedForecast = true  // 是否使用詳細鄉鎮預報
    
    private let weatherService = WeatherService.shared
    private let aiService = AIService.shared
    
    var popularLocations: [String] {
        return weatherService.getPopularLocations()
    }
    
    var allSupportedCities: [String] {
        return weatherService.getAllSupportedCities()
    }
    
    // MARK: - Fetch Weather and AI Insights
    func fetchWeatherAndInsights(for location: String) async {
        isLoading = true
        errorMessage = nil
        
        NSLog("🔄 [ViewModel] Fetching weather for: \(location), district: \(selectedDistrict ?? "nil")")
        
        do {
            let weather: WeatherData
            
            if useDetailedForecast {
                // 使用詳細鄉鎮預報 API
                NSLog("📡 [ViewModel] Using detailed township API")
                weather = try await weatherService.fetchTownshipForecast(
                    cityName: location,
                    districtName: selectedDistrict
                )
            } else {
                // 使用原本的縣市預報 API
                NSLog("📡 [ViewModel] Using city API")
                weather = try await weatherService.fetchWeatherForecast(for: location)
            }
            
            NSLog("✅ [ViewModel] Weather loaded: \(weather.fullLocationName)")
            NSLog("   🌡 Temp: \(weather.temperatureDisplay)")
            NSLog("   🌧 Rain: \(weather.rainProbability ?? "nil")")
            NSLog("   ☁️ Condition: \(weather.condition ?? "nil")")
            
            self.weatherData = weather
            self.isLoading = false
            
            // 2. 使用 AI 生成洞察
            self.isGeneratingAI = true
            self.aiInsight = nil // 清除舊的洞察，避免混淆
            
            let insight = await aiService.generateInsights(for: weather)
            self.aiInsight = insight
            self.isGeneratingAI = false
            
        } catch {
            NSLog("❌ [ViewModel] Error: \(error)")
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            self.isGeneratingAI = false
        }
    }
    
    // MARK: - Load Available Districts
    func loadDistrictsForCity(_ city: String) async {
        NSLog("🔄 [ViewModel] Loading districts for: \(city)")
        do {
            let districts = try await weatherService.getDistrictsForCity(city)
            NSLog("✅ [ViewModel] Found \(districts.count) districts: \(districts.prefix(5))...")
            self.availableDistricts = districts
            // 預設選擇第一個區域
            if selectedDistrict == nil || !districts.contains(selectedDistrict ?? "") {
                self.selectedDistrict = districts.first
                NSLog("   📍 Selected district: \(selectedDistrict ?? "nil")")
            }
        } catch {
            NSLog("❌ [ViewModel] Failed to load districts: \(error)")
            self.availableDistricts = []
            self.selectedDistrict = nil
        }
    }
    
    // MARK: - Change City
    func changeCity(to city: String) async {
        selectedLocation = city
        selectedDistrict = nil
        await loadDistrictsForCity(city)
        await fetchWeatherAndInsights(for: city)
    }
    
    // MARK: - Change District
    func changeDistrict(to district: String?) async {
        selectedDistrict = district
        await fetchWeatherAndInsights(for: selectedLocation)
    }
    
    // MARK: - Refresh Weather
    func refresh() async {
        await fetchWeatherAndInsights(for: selectedLocation)
    }
}
