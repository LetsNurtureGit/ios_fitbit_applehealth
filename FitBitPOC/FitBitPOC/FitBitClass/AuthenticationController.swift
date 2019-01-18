//
//  AuthenticationController.swift
//  FitBitPOC
//
//  Created by LN-iMAC-001 on 17/01/19.
//  Copyright © 2019 letsnurture. All rights reserved.
//

import Foundation
import UIKit
import WebKit

protocol AuthenticationProtocol {
    func authorizationDidFinish(_ success :Bool,_ accessToken : String?)
}

class AuthenticationController : NSObject {
    let defaultScope = "activity+sleep+settings+nutrition+social+heartrate+profile+weight+location"
    
    var delegate: AuthenticationProtocol?
    
    init(delegate: AuthenticationProtocol?) {
        self.delegate = delegate
        super.init()
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: NotificationConstants.launchNotification), object: nil, queue: nil, using: { [weak self] (notification: Notification) in
            // Parse and extract token
            
            print(notification)
            if let code = AuthenticationController.extractCode(notification, key: "code") {
                NSLog("You have successfully authorized")
                self?.getTokenWithDataUsingCode(code: code.components(separatedBy: "#")[0])
            } else {
                print("There was an error extracting the access token from the authentication response.")
                self?.delegate?.authorizationDidFinish(false, nil)
            }
            
            //Call API For Refresh Token And Token
        })
    }
    
    func checkFitbitAlreadyLogin() -> Bool{
        if HelthKitData.savedData() != nil {
            return true
        }
        return false
    }
    
    func authWithFitBit() {
        if let info = HelthKitData.savedData(), let date = info.ftokenExpireDate {
            if date > Date() {
                self.delegate?.authorizationDidFinish(true, info.fAccessToken)
            }
            else {
                getTokenWithDataUsingRefreshToken(refreshToken: info.fRefreshToken)
            }
        }
    }
    
    
    func getTokenWithDataUsingCode(code : String) {
        
        // print(FitbitAPI.sharedInstance.session?.configuration.httpAdditionalHeaders!)
        
        guard let session = FitbitAPI.sharedInstance.authorizeWithCode(),
            let stepURL = URL(string: "https://api.fitbit.com/oauth2/token?client_id=\(clientID)&grant_type=authorization_code&redirect_uri=\(fitbitURI)&code=\(code.components(separatedBy: "#")[0])") else {
                return
        }
        
        var request = URLRequest(url: stepURL)
        request.httpMethod = "POST"
        
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            guard let response = response as? HTTPURLResponse, error == nil, response.statusCode < 300 else {
                return
            }
            
            guard let data = data,
                let dictionary = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: AnyObject] else {
                    return
            }
            
            if let access_token = dictionary["access_token"] as? String, let refresh_token = dictionary["refresh_token"] as? String, let expires_in = dictionary["expires_in"] as? Int {
                let currentDate = Date()
                let expire_Date  = currentDate.addingTimeInterval(TimeInterval(exactly: expires_in) ?? 0.0)
                //Store Token And Refresh Token
                self.storeTokenAndData(ftokenExpireDate: expire_Date, fAccessToken: access_token, fRefreshToken: refresh_token)
                self.delegate?.authorizationDidFinish(true, access_token)
            }
            
        }
        dataTask.resume()
    }
    
    private func storeTokenAndData(ftokenExpireDate : Date?, fAccessToken : String, fRefreshToken : String ) {
        if  let info = HelthKitData.savedData() {
            info.fAccessToken =  fAccessToken
            info.fRefreshToken = fRefreshToken
            info.ftokenExpireDate = ftokenExpireDate
            info.save()
        }
        else {
            let data = HelthKitData(ftokenExpireDate: ftokenExpireDate, fAccessToken: fAccessToken, fRefreshToken: fRefreshToken)
            data.save()
        }
    }
    
    func getTokenWithDataUsingRefreshToken(refreshToken : String) {
        
        guard let session = FitbitAPI.sharedInstance.authorizeWithCode(),
            let stepURL = URL(string: "https://api.fitbit.com/oauth2/token?grant_type=refresh_token&refresh_token=\(refreshToken)") else {
                return
        }
        
        var request = URLRequest(url: stepURL)
        request.httpMethod = "POST"
        
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            guard let response = response as? HTTPURLResponse, error == nil, response.statusCode < 300 else {
                return
            }
            
            guard let data = data,
                let dictionary = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: AnyObject] else {
                    return
            }
            
            if let access_token = dictionary["access_token"] as? String, let refresh_token = dictionary["refresh_token"] as? String, let expires_in = dictionary["expires_in"] as? Int {
                let currentDate = Date()
                let expire_Date  = currentDate.addingTimeInterval(TimeInterval(exactly: expires_in) ?? 0.0)
                //Store Token And Refresh Token
                self.storeTokenAndData(ftokenExpireDate: expire_Date, fAccessToken: access_token, fRefreshToken: refresh_token)
                self.delegate?.authorizationDidFinish(true, access_token)
            }
            
        }
        dataTask.resume()
        //return dataTask
    }
    
    func revokeTokenUsingAccessToken(token : String) {
        
        guard let session = FitbitAPI.sharedInstance.authorizeWithCode(),
            let stepURL = URL(string: "https://api.fitbit.com/oauth2/revoke?token=\(token)&client_id=\(clientID)") else {
                return
        }
        
        var request = URLRequest(url: stepURL)
        request.httpMethod = "POST"
        
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            guard let response = response as? HTTPURLResponse, error == nil, response.statusCode < 300 else {
                return
            }
            HelthKitData.clearData()
            let dataTypes = Set([WKWebsiteDataTypeCookies,
                                 WKWebsiteDataTypeLocalStorage, WKWebsiteDataTypeSessionStorage,
                                 WKWebsiteDataTypeWebSQLDatabases, WKWebsiteDataTypeIndexedDBDatabases])
            WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: Date.distantPast, completionHandler: {})
             self.delegate?.authorizationDidFinish(false,nil)
            
        }
        dataTask.resume()
        //return dataTask
    }
    
    public func login(fromParentViewController viewController: UIViewController) {
        guard let url = URL(string: "https://www.fitbit.com/oauth2/authorize?response_type=code&client_id="+clientID+"&redirect_uri="+fitbitURI+"&scope="+defaultScope) else {
            NSLog("Unable to create authentication URL")
            return
        }
        print(url)
        
        let board = UIStoryboard(name: "Main", bundle: nil)
        
        let controll = board.instantiateViewController(withIdentifier: "WebViewVC") as! WebViewVC
        let nav = UINavigationController(rootViewController: controll)
        controll.targetURL = url
        viewController.present(nav, animated: true, completion: nil)
    }
    
    public func logout() {
        if let info = HelthKitData.savedData(), !info.fAccessToken.isEmpty {
            revokeTokenUsingAccessToken(token: info.fAccessToken)
        }
    }
    
     // Extract the access token from the URL
    private static func extractToken(_ notification: Notification, key: String) -> String? {
        guard let url = notification.userInfo?[UIApplication.LaunchOptionsKey.url] as? URL else {
            NSLog("notification did not contain launch options key with URL")
            return nil
        }
        
       
        let strippedURL = url.absoluteString.replacingOccurrences(of: fitbitURI, with: "")
        return self.parametersFromQueryString(strippedURL)[key]
    }
    
    // Extract the code from the URL
    private static func extractCode(_ notification: Notification, key: String) -> String? {
        guard let url = notification.userInfo?[UIApplication.LaunchOptionsKey.url] as? URL else {
            NSLog("notification did not contain launch options key with URL")
            return nil
        }
        
        
        let strippedURL = url.absoluteString.replacingOccurrences(of: fitbitURI + "?", with: "")
        return self.parametersFromQueryString(strippedURL)[key]
    }
    
    // TODO: this method is horrible and could be an extension and use some functional programming
    private static func parametersFromQueryString(_ queryString: String?) -> [String: String] {
        var parameters = [String: String]()
        if (queryString != nil) {
            let parameterScanner: Scanner = Scanner(string: queryString!)
            var name:NSString? = nil
            var value:NSString? = nil
            while (parameterScanner.isAtEnd != true) {
                name = nil;
                parameterScanner.scanUpTo("=", into: &name)
                parameterScanner.scanString("=", into:nil)
                value = nil
                parameterScanner.scanUpTo("&", into:&value)
                parameterScanner.scanString("&", into:nil)
                if (name != nil && value != nil) {
                    parameters[name!.removingPercentEncoding!]
                        = value!.removingPercentEncoding!
                }
            }
        }
        return parameters
    }
}
