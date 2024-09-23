//
//  NetworkManager.swift
//  NetworkModel
//
//  Created by Moon Jongseek on 2022/07/01.
//

import Foundation

final class NetworkManager {
    let baseURL: String
    private var session = URLSession(configuration: URLSessionConfiguration.default,
                                     delegate: nil,
                                     delegateQueue: nil)
    
    private let request: (URL) -> URLRequest =  { url in
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.GET.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
    
    init(baseURL: String) {
        self.baseURL = baseURL
    }
    
    deinit {
        self.session.finishTasksAndInvalidate()
    }
}

extension NetworkManager {
    func multipleObjectRouteValue(ids: [Int]) -> String {
        var result = ""
        if ids.count > 0 {
            result += "/"
            for id in ids {
                result += "\(id),"
            }
            _ = result.popLast()
        }
        return result
    }
    
    func sendRequest(urlString: String, completeHandler: @escaping (Data?, NetworkError?) -> Void) {
        guard let url = URL(string: urlString) else {
            return completeHandler(nil, NetworkError.invalidURL)
        }
        
        let request = request(url)
        self.session.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completeHandler(nil, .nilResponse)
                return
            }
            completeHandler(data, nil)
        }
        .resume()
    }
    
    func sendRequest<D: Codable>(urlString: String, decodeTo: D.Type, completeHandler: @escaping NetworkClosure<D>) {
        sendRequest(urlString: urlString) { (data, error) in
            if let error = error { completeHandler(nil, error) }
            guard let data = data, let result = try? JSONDecoder().decode(D.self, from: data) else {
                completeHandler(nil, .errorDecodingJson)
                return
            }
            completeHandler(result, nil)
        }
    }
    
    func sendRequest<D: Codable>(route: NetworkService.ModelRoute, ids: [Int] = [], decodeTo: D.Type, completeHandler: @escaping NetworkClosure<D>) {
        let urlString = self.baseURL + route.stringValue + multipleObjectRouteValue(ids: ids)
        
        sendRequest(urlString: urlString) { (data, error) in
            if let error = error { completeHandler(nil, error) }
            guard let data = data, let result = try? JSONDecoder().decode(D.self, from: data) else {
                completeHandler(nil, .errorDecodingJson)
                return
            }
            completeHandler(result, nil)
        }
    }
    
    func sendRequest<D: Codable, F: FilterProtocol>(route: NetworkService.ModelRoute, filterBy filters: [F] = [], decodeTo: D.Type, completeHandler: @escaping NetworkClosure<D>) {
        let urlString = self.baseURL + route.stringValue
        
        guard let url = URL(string: urlString) else {
            return completeHandler(nil, NetworkError.invalidURL)
        }
        
        var request = request(url)
        
        if !filters.isEmpty {
            guard let jsonData = try? JSONEncoder().encode(filters) else {
                completeHandler(nil, .errorEncodingJson)
                return
            }
            request.httpBody = jsonData
        }
        
        self.session.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completeHandler(nil, .nilResponse)
                return
            }
            
            guard let result = try? JSONDecoder().decode(D.self, from: data) else {
                completeHandler(nil, .errorDecodingJson)
                return
            }
            
            completeHandler(result, nil)
        }
        .resume()
    }
}
