import Foundation
import os.log

private let logger = Logger(subsystem: "matt.iosfinal", category: "WeatherService")

class WeatherService {
    static let shared = WeatherService()
    
    private let apiKey = "CWA-71C8F144-9102-4324-8E53-41174A7CB46B"
    private let baseURL = "https://opendata.cwa.gov.tw/api/v1/rest/datastore"
    
    // 縣市對應的鄉鎮預報 API 代碼 (F-D0047-XXX)
    private let cityAPIMap: [String: String] = [
        "基隆市": "F-D0047-049",
        "臺北市": "F-D0047-061",
        "新北市": "F-D0047-069",
        "桃園市": "F-D0047-005",
        "新竹市": "F-D0047-053",
        "新竹縣": "F-D0047-009",
        "苗栗縣": "F-D0047-013",
        "臺中市": "F-D0047-073",
        "彰化縣": "F-D0047-017",
        "南投縣": "F-D0047-021",
        "雲林縣": "F-D0047-025",
        "嘉義市": "F-D0047-057",
        "嘉義縣": "F-D0047-029",
        "臺南市": "F-D0047-077",
        "高雄市": "F-D0047-065",
        "屏東縣": "F-D0047-033",
        "宜蘭縣": "F-D0047-001",
        "花蓮縣": "F-D0047-041",
        "臺東縣": "F-D0047-037",
        "澎湖縣": "F-D0047-045",
        "金門縣": "F-D0047-085",
        "連江縣": "F-D0047-081"
    ]
    
    // MARK: - Fetch City Weather Forecast (舊 API - F-C0032-001)
    func fetchWeatherForecast(for locationName: String) async throws -> WeatherData {
        let encodedLocation = locationName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? locationName
        let urlStr = "\(baseURL)/F-C0032-001?Authorization=\(apiKey)&locationName=\(encodedLocation)&format=JSON"
        
        guard let url = URL(string: urlStr) else {
            throw WeatherServiceError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw WeatherServiceError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let weatherResponse = try decoder.decode(WeatherResponse.self, from: data)
        
        guard let location = weatherResponse.records.location.first else {
            throw WeatherServiceError.noData
        }
        
        return WeatherData(from: location)
    }
    
    // MARK: - Fetch Township Weather Forecast (新 API - F-D0047)
    /// 取得指定縣市下某鄉鎮區的天氣預報
    /// - Parameters:
    ///   - cityName: 縣市名稱，如 "基隆市"
    ///   - districtName: 鄉鎮區名稱，如 "中正區" (可選，若為 nil 則取第一筆)
    /// - Returns: WeatherData
    func fetchTownshipForecast(cityName: String, districtName: String? = nil) async throws -> WeatherData {
        // 取得對應的 API 代碼
        guard let apiCode = cityAPIMap[cityName] else {
            NSLog("❌ [WeatherService] City not found in apiMap: \(cityName)")
            throw WeatherServiceError.unsupportedCity
        }
        
        var urlStr = "\(baseURL)/\(apiCode)?Authorization=\(apiKey)&format=JSON"
        
        // 若有指定鄉鎮區，加入 locationName 參數
        if let district = districtName {
            let encodedDistrict = district.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? district
            urlStr += "&locationName=\(encodedDistrict)"
        }
        
        NSLog("🌐 [WeatherService] Fetching: \(urlStr)")
        
        guard let url = URL(string: urlStr) else {
            NSLog("❌ [WeatherService] Invalid URL")
            throw WeatherServiceError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            NSLog("❌ [WeatherService] Not HTTP response")
            throw WeatherServiceError.invalidResponse
        }
        
        NSLog("📡 [WeatherService] HTTP Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            NSLog("❌ [WeatherService] HTTP Error: \(httpResponse.statusCode)")
            throw WeatherServiceError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        do {
            let townshipResponse = try decoder.decode(TownshipForecastResponse.self, from: data)
            NSLog("✅ [WeatherService] Decoded successfully")
            NSLog("   📍 locations count: \(townshipResponse.records.locations.count)")
            
            guard let locations = townshipResponse.records.locations.first else {
                NSLog("❌ [WeatherService] No locations found")
                throw WeatherServiceError.noData
            }
            
            NSLog("   📍 location count: \(locations.location.count)")
            
            // 根據指定的區域名稱篩選，若未指定則取第一筆
            let townshipLocation: TownshipDetailLocation
            if let district = districtName {
                // 尋找指定的區域
                if let found = locations.location.first(where: { $0.locationName == district }) {
                    townshipLocation = found
                    NSLog("   📍 Found district: \(district)")
                } else {
                    // 找不到指定區域，使用第一筆
                    NSLog("   ⚠️ District '\(district)' not found, using first")
                    guard let first = locations.location.first else {
                        throw WeatherServiceError.noData
                    }
                    townshipLocation = first
                }
            } else {
                // 未指定區域，使用第一筆
                guard let first = locations.location.first else {
                    NSLog("❌ [WeatherService] No township location found")
                    throw WeatherServiceError.noData
                }
                townshipLocation = first
            }
            
            NSLog("   📍 Township: \(townshipLocation.locationName)")
            NSLog("   🌡 WeatherElements count: \(townshipLocation.weatherElement.count)")
            
            return WeatherData(from: townshipLocation, cityName: cityName)
        } catch {
            NSLog("❌ [WeatherService] Decode error: \(error)")
            // 印出原始 JSON 前 500 字元用於除錯
            if let jsonStr = String(data: data, encoding: .utf8) {
                NSLog("   📄 Raw JSON (first 500 chars): \(String(jsonStr.prefix(500)))")
            }
            throw error
        }
    }
    
    // MARK: - Fetch All Districts for a City
    /// 取得指定縣市的所有鄉鎮區天氣預報
    /// - Parameter cityName: 縣市名稱
    /// - Returns: [WeatherData]
    func fetchAllDistrictsWeather(for cityName: String) async throws -> [WeatherData] {
        guard let apiCode = cityAPIMap[cityName] else {
            NSLog("❌ [WeatherService] fetchAllDistricts - City not found: \(cityName)")
            throw WeatherServiceError.unsupportedCity
        }
        
        let urlStr = "\(baseURL)/\(apiCode)?Authorization=\(apiKey)&format=JSON"
        NSLog("🌐 [WeatherService] fetchAllDistricts: \(urlStr)")
        
        guard let url = URL(string: urlStr) else {
            throw WeatherServiceError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            NSLog("❌ [WeatherService] fetchAllDistricts - HTTP error")
            throw WeatherServiceError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        do {
            let townshipResponse = try decoder.decode(TownshipForecastResponse.self, from: data)
            NSLog("✅ [WeatherService] fetchAllDistricts - Decoded successfully")
            
            guard let locations = townshipResponse.records.locations.first else {
                NSLog("❌ [WeatherService] fetchAllDistricts - No locations")
                throw WeatherServiceError.noData
            }
            
            let result = locations.location.map { WeatherData(from: $0, cityName: cityName) }
            NSLog("   📍 Found \(result.count) districts")
            return result
        } catch {
            NSLog("❌ [WeatherService] fetchAllDistricts - Decode error: \(error)")
            throw error
        }
    }
    
    // MARK: - Get Districts for a City
    /// 取得指定縣市的所有鄉鎮區名稱
    /// - Parameter cityName: 縣市名稱
    /// - Returns: [String] 鄉鎮區名稱列表
    func getDistrictsForCity(_ cityName: String) async throws -> [String] {
        let weatherDataList = try await fetchAllDistrictsWeather(for: cityName)
        return weatherDataList.compactMap { $0.district }
    }
    
    // MARK: - Get Popular Locations
    func getPopularLocations() -> [String] {
        return [
            "臺北市",
            "新北市",
            "臺中市",
            "臺南市",
            "高雄市",
            "基隆市",
            "新竹市",
            "桃園市",
            "苗栗縣",
            "彰化縣"
        ]
    }
    
    // MARK: - Get All Supported Cities
    func getAllSupportedCities() -> [String] {
        return Array(cityAPIMap.keys).sorted()
    }
}

enum WeatherServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case decodingError
    case unsupportedCity
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無效的 URL"
        case .invalidResponse:
            return "無效的服務器響應"
        case .noData:
            return "未找到天氣數據"
        case .decodingError:
            return "解碼天氣數據失敗"
        case .unsupportedCity:
            return "不支援此縣市的鄉鎮預報"
        }
    }
}
