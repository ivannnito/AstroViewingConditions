import Foundation
import CoreLocation

public actor ISSService {
    private let baseURL = "https://api.n2yo.com/rest/v1/satellite"
    private let issNoradId = 25544
    private let apiKey: String
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func fetchPasses(
        latitude: Double,
        longitude: Double,
        altitude: Double = 0,
        days: Int = 10,
        minVisibility: Int = 60
    ) async throws -> [ISSPass] {
        // N2YO endpoint: /visualpasses/{id}/{observer_lat}/{observer_lng}/{observer_alt}/{days}/{min_visibility}/
        let urlString = "\(baseURL)/visualpasses/\(issNoradId)/\(latitude)/\(longitude)/\(Int(altitude))/\(days)/\(minVisibility)/&apiKey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw ISSError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ISSError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let issResponse = try decoder.decode(N2YOResponse.self, from: data)
        
        guard issResponse.passes != nil else {
            return []
        }
        
        return issResponse.passes?.map { pass in
            ISSPass(
                riseTime: Date(timeIntervalSince1970: TimeInterval(pass.startUTC)),
                duration: TimeInterval(pass.duration),
                maxElevation: pass.maxEl
            )
        } ?? []
    }
}

// MARK: - Errors

public enum ISSError: Error {
    case invalidURL
    case invalidResponse
    case apiError(String)
}

// MARK: - N2YO Response Models

struct N2YOResponse: Codable {
    let info: N2YOInfo
    let passes: [N2YOPass]?
}

struct N2YOInfo: Codable {
    let satid: Int
    let satname: String
    let transactionscount: Int
    let passescount: Int?
}

struct N2YOPass: Codable {
    let startAz: Double
    let startAzCompass: String
    let startEl: Double
    let startUTC: Int
    let maxAz: Double
    let maxAzCompass: String
    let maxEl: Double
    let maxUTC: Int
    let endAz: Double
    let endAzCompass: String
    let endEl: Double
    let endUTC: Int
    let mag: Double
    let duration: Int
}
