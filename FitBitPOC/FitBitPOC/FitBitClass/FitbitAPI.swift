//
//  FitbitAPI.swift
//  FitBitPOC
//
//  Created by LN-iMAC-001 on 17/01/19.
//  Copyright © 2019 letsnurture. All rights reserved.
//

import Foundation

class FitbitAPI {
    static let sharedInstance: FitbitAPI = FitbitAPI()
    
    func authorizewith(Token token: String) -> URLSession?{
        let sessionConfiguration = URLSessionConfiguration.default
        var headers = sessionConfiguration.httpAdditionalHeaders ?? [:]
        headers["Authorization"] = "Bearer \(token)"
        sessionConfiguration.httpAdditionalHeaders = headers
        return URLSession(configuration: sessionConfiguration)
    }
    
    
    func authorizeWithCode() -> URLSession? {
        
        let sessionConfiguration = URLSessionConfiguration.default
        var headers = sessionConfiguration.httpAdditionalHeaders ?? [:]
        let base64Str = "\(clientID):\(clientSecret)".toBase64()
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        headers["Authorization"] = "Basic \(base64Str)"
        sessionConfiguration.httpAdditionalHeaders = headers
        return URLSession(configuration: sessionConfiguration)
    }
    
}

extension String {
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
}
