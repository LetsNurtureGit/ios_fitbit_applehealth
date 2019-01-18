//
//  AppConstant.swift
//  FitBitPOC
//
//  Created by LN-iMAC-001 on 17/01/19.
//  Copyright © 2019 letsnurture. All rights reserved.
//

import Foundation

struct NotificationConstants {
    static let launchNotification = "SampleBitLaunchNotification"
}

let clientID = "22DFW4"
let clientSecret = "35755156b0ee832e851d3ece5eec8763"
let fitbitURI = "letsnurture.com://fitbit"

let khealthInfo = "SavedHealthInfo"

class HelthKitData : NSObject, NSCoding  {
    
    var ftokenExpireDate : Date?
    var fAccessToken = ""
    var fRefreshToken = ""
    
    init(ftokenExpireDate : Date?, fAccessToken : String, fRefreshToken : String ) {
        self.ftokenExpireDate = ftokenExpireDate
        self.fAccessToken = fAccessToken
        self.fRefreshToken = fRefreshToken
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.ftokenExpireDate, forKey: "ftokenExpireDate")
        aCoder.encode(self.fAccessToken, forKey: "fAccessToken")
        aCoder.encode(self.fRefreshToken, forKey: "fRefreshToken")
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.ftokenExpireDate = aDecoder.decodeObject(forKey: "ftokenExpireDate") as? Date
        self.fAccessToken = aDecoder.decodeObject(forKey: "fAccessToken") as! String
        self.fRefreshToken = aDecoder.decodeObject(forKey: "fRefreshToken") as! String
    }
    
    
    func save() {
        let defaults: UserDefaults = UserDefaults.standard
        let data: NSData = NSKeyedArchiver.archivedData(withRootObject: self) as NSData
        defaults.set(data, forKey: khealthInfo)
        defaults.synchronize()
    }
    
    class func savedData() -> HelthKitData? {
        let defaults: UserDefaults = UserDefaults.standard
        let data = defaults.object(forKey: khealthInfo) as? NSData
        if data != nil {
            if let info = NSKeyedUnarchiver.unarchiveObject(with: data! as Data) as? HelthKitData {
                return info
            }
            else {
                return nil
            }
        }
        return nil
    }
    
    class func clearData() {
        let defaults: UserDefaults = UserDefaults.standard
        defaults.removeObject(forKey: khealthInfo)
        defaults.synchronize()
    }
}
