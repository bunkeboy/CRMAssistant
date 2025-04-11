// ApiService.swift - Updated version
import Foundation

class ApiService {
    // We'll replace this with your actual Make.com webhook URL
    private let apiUrl = "https://hook.us2.make.com/ko3yo8nvxba3ppdtzcyg7bact6oxquhf"
    
    func sendMessage(_ message: String, completion: @escaping (String?, Error?) -> Void) {
        // Create request body
        let body: [String: Any] = ["message": message]
        
        // Convert body to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(nil, NSError(domain: "ApiService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create JSON data"]))
            return
        }
        
        // Create URL
        guard let url = URL(string: apiUrl) else {
            completion(nil, NSError(domain: "ApiService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle error
            if let error = error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            // Check response
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, NSError(domain: "ApiService", code: 3, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                }
                return
            }
            
            // Parse response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let response = json["response"] as? String {
                    DispatchQueue.main.async {
                        completion(response, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil, NSError(domain: "ApiService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"]))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        
        // Start task
        task.resume()
    }
}
