import Foundation

// MARK: - Weather Response Models
struct WeatherResponse: Codable {
    let records: Records
}

struct Records: Codable {
    let location: [Location]
}

struct Location: Codable {
    let locationName: String
    let weatherElement: [WeatherElement]
}

struct WeatherElement: Codable {
    let elementName: String
    let time: [TimeData]
}

struct TimeData: Codable {
    let startTime: String
    let endTime: String
    let parameter: Parameter?
}

struct Parameter: Codable {
    let parameterName: String?
}

// MARK: - Township Forecast Models (F-D0047 API)
struct TownshipForecastResponse: Codable {
    let records: TownshipRecords
}

struct TownshipRecords: Codable {
    let locations: [TownshipLocations]
    
    enum CodingKeys: String, CodingKey {
        case locations = "Locations"
    }
}

struct TownshipLocations: Codable {
    let datasetDescription: String?
    let locationsName: String?
    let location: [TownshipDetailLocation]
    
    enum CodingKeys: String, CodingKey {
        case datasetDescription = "DatasetDescription"
        case locationsName = "LocationsName"
        case location = "Location"
    }
}

struct TownshipDetailLocation: Codable {
    let locationName: String
    let geocode: String?
    let latitude: String?
    let longitude: String?
    let weatherElement: [TownshipDetailWeatherElement]
    
    enum CodingKeys: String, CodingKey {
        case locationName = "LocationName"
        case geocode = "Geocode"
        case latitude = "Latitude"
        case longitude = "Longitude"
        case weatherElement = "WeatherElement"
    }
}

struct TownshipDetailWeatherElement: Codable {
    let elementName: String
    let time: [TownshipDetailTimeData]
    
    enum CodingKeys: String, CodingKey {
        case elementName = "ElementName"
        case time = "Time"
    }
}

struct TownshipDetailTimeData: Codable {
    let startTime: String?
    let endTime: String?
    let dataTime: String?
    let elementValue: [ElementValue]
    
    enum CodingKeys: String, CodingKey {
        case startTime = "StartTime"
        case endTime = "EndTime"
        case dataTime = "DataTime"
        case elementValue = "ElementValue"
    }
}

// F-D0047 API 的 ElementValue 格式
// 不同元素有不同的 key: Temperature, Weather, WeatherCode, ProbabilityOfPrecipitation, etc.
struct ElementValue: Codable {
    // 溫度相關
    let temperature: String?
    let apparentTemperature: String?
    let dewPoint: String?
    
    // 天氣現象
    let weather: String?
    let weatherCode: String?
    
    // 降雨機率
    let probabilityOfPrecipitation: String?
    
    // 舒適度
    let comfortIndex: String?
    let comfortIndexDescription: String?
    
    // 濕度
    let relativeHumidity: String?
    
    // 風速/風向
    let windSpeed: String?
    let beaufortScale: String?
    let windDirection: String?
    
    // 綜合描述
    let weatherDescription: String?
    
    enum CodingKeys: String, CodingKey {
        case temperature = "Temperature"
        case apparentTemperature = "ApparentTemperature"
        case dewPoint = "DewPoint"
        case weather = "Weather"
        case weatherCode = "WeatherCode"
        case probabilityOfPrecipitation = "ProbabilityOfPrecipitation"
        case comfortIndex = "ComfortIndex"
        case comfortIndexDescription = "ComfortIndexDescription"
        case relativeHumidity = "RelativeHumidity"
        case windSpeed = "WindSpeed"
        case beaufortScale = "BeaufortScale"
        case windDirection = "WindDirection"
        case weatherDescription = "WeatherDescription"
    }
}

// MARK: - App Domain Models
struct WeatherData: Identifiable, Equatable {
    let id = UUID()
    let location: String
    let district: String?        // 區域名稱（鄉鎮市區）
    let minTemperature: String?  // 最低溫度
    let maxTemperature: String?  // 最高溫度
    let rainProbability: String? // 降雨機率
    let condition: String?       // 天氣狀況
    let comfort: String?         // 舒適度指數
    let humidity: String?        // 相對濕度（鄉鎮 API 有提供）
    let windSpeed: String?       // 風速（鄉鎮 API 有提供）
    let timestamp: Date
    
    // 從縣市 API (F-C0032-001) 初始化
    init(from location: Location) {
        self.location = location.locationName
        self.district = nil
        self.timestamp = Date()
        
        // 提取各項氣象元素 - F-C0032-001 API 欄位
        // MinT: 最低溫度
        self.minTemperature = location.weatherElement
            .first(where: { $0.elementName == "MinT" })?
            .time.first?
            .parameter?.parameterName
        
        // MaxT: 最高溫度
        self.maxTemperature = location.weatherElement
            .first(where: { $0.elementName == "MaxT" })?
            .time.first?
            .parameter?.parameterName
        
        // PoP: 降雨機率
        self.rainProbability = location.weatherElement
            .first(where: { $0.elementName == "PoP" })?
            .time.first?
            .parameter?.parameterName
        
        // Wx: 天氣現象
        self.condition = location.weatherElement
            .first(where: { $0.elementName == "Wx" })?
            .time.first?
            .parameter?.parameterName
        
        // CI: 舒適度
        self.comfort = location.weatherElement
            .first(where: { $0.elementName == "CI" })?
            .time.first?
            .parameter?.parameterName
        
        // 縣市 API 沒有濕度和風速
        self.humidity = nil
        self.windSpeed = nil
    }
    
    // 從鄉鎮 API (F-D0047) 初始化
    init(from townshipLocation: TownshipDetailLocation, cityName: String) {
        self.location = cityName
        self.district = townshipLocation.locationName
        self.timestamp = Date()
        
        // F-D0047 API 欄位
        // 溫度 (取最新的溫度)
        let temperatureElement = townshipLocation.weatherElement
            .first(where: { $0.elementName == "溫度" })
        let temp = temperatureElement?.time.first?.elementValue.first?.temperature
        self.minTemperature = temp
        self.maxTemperature = temp
        
        // 3小時降雨機率
        self.rainProbability = townshipLocation.weatherElement
            .first(where: { $0.elementName == "3小時降雨機率" })?
            .time.first?
            .elementValue.first?.probabilityOfPrecipitation
        
        // 天氣現象
        self.condition = townshipLocation.weatherElement
            .first(where: { $0.elementName == "天氣現象" })?
            .time.first?
            .elementValue.first?.weather
        
        // 舒適度指數
        self.comfort = townshipLocation.weatherElement
            .first(where: { $0.elementName == "舒適度指數" })?
            .time.first?
            .elementValue.first?.comfortIndexDescription
        
        // 相對濕度
        self.humidity = townshipLocation.weatherElement
            .first(where: { $0.elementName == "相對濕度" })?
            .time.first?
            .elementValue.first?.relativeHumidity
        
        // 風速
        self.windSpeed = townshipLocation.weatherElement
            .first(where: { $0.elementName == "風速" })?
            .time.first?
            .elementValue.first?.windSpeed
    }
    
    // 手動初始化
    init(location: String, district: String?, minTemperature: String?, maxTemperature: String?, rainProbability: String?, condition: String?, comfort: String?, humidity: String?, windSpeed: String?, timestamp: Date) {
        self.location = location
        self.district = district
        self.minTemperature = minTemperature
        self.maxTemperature = maxTemperature
        self.rainProbability = rainProbability
        self.condition = condition
        self.comfort = comfort
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.timestamp = timestamp
    }
    
    // 顯示用的溫度字串
    var temperatureDisplay: String {
        if let min = minTemperature, let max = maxTemperature {
            return "\(min) - \(max)"
        } else if let min = minTemperature {
            return min
        } else if let max = maxTemperature {
            return max
        }
        return "--"
    }
    
    // 顯示用的完整地點名稱
    var fullLocationName: String {
        if let district = district {
            return "\(location)\(district)"
        }
        return location
    }
    
    static func == (lhs: WeatherData, rhs: WeatherData) -> Bool {
        lhs.location == rhs.location &&
        lhs.district == rhs.district &&
        lhs.minTemperature == rhs.minTemperature &&
        lhs.maxTemperature == rhs.maxTemperature &&
        lhs.condition == rhs.condition
    }
}

// MARK: - AI Insight Model
struct AIInsight: Identifiable, Equatable {
    let id = UUID()
    let summary: String          // 天氣摘要
    let recommendation: String   // 生活建議
    let clothingAdvice: String   // 穿衣建議
    let activityAdvice: String   // 活動建議
    let warning: String?         // 警告信息
    let isAIGenerated: Bool      // 是否由 AI 生成（true = Foundation Model, false = 規則式）
    let generatedAt: Date        // 生成時間
    
    init(summary: String, recommendation: String, clothingAdvice: String, activityAdvice: String, warning: String?, isAIGenerated: Bool = false) {
        self.summary = summary
        self.recommendation = recommendation
        self.clothingAdvice = clothingAdvice
        self.activityAdvice = activityAdvice
        self.warning = warning
        self.isAIGenerated = isAIGenerated
        self.generatedAt = Date()
    }
    
    var sourceLabel: String {
        isAIGenerated ? "🤖 Apple Intelligence" : "📋 規則式分析"
    }
    
    static func == (lhs: AIInsight, rhs: AIInsight) -> Bool {
        lhs.id == rhs.id
    }
}
