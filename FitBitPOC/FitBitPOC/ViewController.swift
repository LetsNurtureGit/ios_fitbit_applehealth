//
//  ViewController.swift
//  FitBitPOC
//
//  Created by LN-iMAC-001 on 17/01/19.
//  Copyright © 2019 letsnurture. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {

    @IBOutlet var lblStepCount: UILabel!
    @IBOutlet var lblSyncDate: UILabel!
    
    @IBOutlet var lblAStepCount: UILabel!
    @IBOutlet var lblASyncDate: UILabel!
    
    @IBOutlet var btnLogOut: UIButton!
    
    //ForFttBit Data Fetch
    var authenticationController: AuthenticationController?

    //For Apple Health Data
    struct StepsData {
        var steps = 0
        var dateStr = ""
    }
    
    var stepsDataArray = [StepsData]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authenticationController = AuthenticationController(delegate: self)
        
        if authenticationController!.checkFitbitAlreadyLogin() {
            btnLogOut.isHidden = false
            authenticationController!.authWithFitBit()
        }
        else {
            btnLogOut.isHidden = true
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func btnLoginWithFitBitCLK(_ sender: UIButton) {
        if authenticationController!.checkFitbitAlreadyLogin() {
            authenticationController!.authWithFitBit()
        }
        else {
            authenticationController!.login(fromParentViewController: self)
        }
        
    }
    
    @IBAction func btnLogOutCLK(_ sender: UIButton) {
        authenticationController?.logout()
    }
    
    @IBAction func btnSyncApplHelthkitCLK(_ sender: UIButton) {
        askForHealthKitAccess()
    }
}

extension ViewController : AuthenticationProtocol {
    func authorizationDidFinish(_ success: Bool, _ accessToken: String?) {
        if success {
            guard let accessToken = accessToken else {
                return
            }
            DispatchQueue.main.async {
                self.btnLogOut.isHidden = false
            }
            
            getFitBitDataWithToken(authToken:accessToken)
            
        }
        else {
            DispatchQueue.main.async {
                self.lblStepCount.text = "Step Count"
                self.lblSyncDate.text = "Sync Date"
                self.btnLogOut.isHidden = true
            }
            
        }
    }
}

extension ViewController {
    func getFitBitDataWithToken(authToken : String) {
        
        /*
         let _ = StepStat.fetchSteps(for: NSDateInterval(start: Date().minusDays(15), end: Date()), callback: { [weak self](stepStats, error) in
         print(stepStats)
         })
         */
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            let _ = StepStat.fetchTodaysStepStat(access_token:authToken) { [weak self] stepStat, error in
                if let steps = stepStat {
                    DispatchQueue.main.async {
                        self?.lblStepCount.text = "\(steps.steps)"
                        self?.lblSyncDate.text = self?.getDateFromDateComponants(dateC: steps.day)
                    }
                }
                else {
                    print(error)
                }
            }
        }
        
    }
    
    func getDateFromDateComponants(dateC : DateComponents) -> String? {
        if let d = dateC.day, let m = dateC.month, let y = dateC.year {
            let dateStr = String(format: "%0.2d-%0.2d-%d", d, m, y)
            let df = DateFormatter()
            df.dateFormat = "dd-MM-yyyy"
            let date = df.date(from: dateStr)
            df.dateFormat = "dd-MMM-yyyy"
            return df.string(from: date!)
        }
        return nil
    }
}


//Apple Health Kit

extension ViewController {
    private func askForHealthKitAccess() {
        
        HealthKitController.sharedInstance.authorizeHealthKit { (sucess, error) in
            if !sucess, let error = error {
                print("HealthKit Authentication Failed")
            } else {
                self.getStepCountAppleHelthKit()
            }
        }
    }
    
    
    func getStepCountAppleHelthKit() {
        guard let stepCount = HKSampleType.quantityType(forIdentifier: .stepCount) else {
            print("Something horrible has happened.")
            return
        }
        
        HealthKitController.sharedInstance.readMostRecentSample(for: stepCount) { (samples, error) in
            if let samples = samples {
                var steps: Int = 0
                print(samples)
                for result in samples as [HKQuantitySample]
                {
                    steps += Int(result.quantity.doubleValue(for: HKUnit.count()))
                }
                if !samples.isEmpty {
                    if let obj = samples.last {
                        self.lblAStepCount.text = "\(steps)"
                        self.lblASyncDate.text = "\(obj.endDate)"
                    }
                }
            }
        }
    }
    
    func getAppleStepsHistoryData(_ completionBLK : (([StepsData]?)->())?) {
        HealthKitController.sharedInstance.readStepsHistoryData(for: HKQuantityType.quantityType(forIdentifier: .stepCount)!) { (statistics, error) in
            var arr = [StepsData]()
            if let statistics = statistics {
                for statistic in statistics {
                    if let sum = statistic.sumQuantity() {
                        let steps = sum.doubleValue(for: HKUnit.count())
                        print("Amount of steps: \(steps), date: \(statistic.startDate)")
                        arr.append(StepsData(steps: Int(steps), dateStr:"\(statistic.startDate)"))
                    }
                }
                completionBLK?(arr)
            }
            completionBLK?(nil)
        }
    }
}
