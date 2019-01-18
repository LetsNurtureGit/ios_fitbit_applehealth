import UIKit
import HealthKit

class HealthKitController: NSObject {
    
    // Singleton
    static let sharedInstance = HealthKitController()

    private enum HealthKitControllerError: Error {
        case DeviceNotSupported
        case DataTypeNotAvailable
    }
    
    private let healthStore = HKHealthStore()

    func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Void) {
        
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, HealthKitControllerError.DeviceNotSupported)
            return
        }
        
        guard let weight = HKObjectType.quantityType(forIdentifier: .bodyMass),
            let height = HKObjectType.quantityType(forIdentifier: .height),
            let bodyMassIndex = HKObjectType.quantityType(forIdentifier: .bodyMassIndex),
            let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount),
            let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
            let flightCount = HKObjectType.quantityType(forIdentifier: .flightsClimbed) else {
                
                completion(false, HealthKitControllerError.DataTypeNotAvailable)
                return
        }
        
        let dataToWrite: Set<HKSampleType> = [weight,
                                              height,
                                              bodyMassIndex]
        
        let dataToRead: Set<HKSampleType> = [weight,
                                             height,
                                             stepCount,
                                             distance,
                                             flightCount]
        
        healthStore.requestAuthorization(toShare: dataToWrite, read: dataToRead) { (success, error) in
            completion(success, error)
        }
    }
    
    func readMostRecentSample(for type: HKSampleType, completion: @escaping ([HKQuantitySample]?, Error?) -> Void) {
        print(Date.distantPast)
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        let mostRecentSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let sampleQuery = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [mostRecentSortDescriptor]) { (query, result, error) in
            
            DispatchQueue.main.async {
                guard let samples = result as? [HKQuantitySample], !samples.isEmpty else {
                    completion(nil, error)
                    return
                }
                completion(samples, nil)
            }
        }
        
        healthStore.execute(sampleQuery)
    }
    
    func readStepsHistoryData(for type: HKQuantityType, completion: @escaping ([HKStatistics]?, Error?) -> Void) {
        let pastDate = "26-09-2014 00:00:00"
        let pDate = pastDate.date(withFormat: "dd-MM-yyyy HH:mm:ss")
        var interval = DateComponents()
        interval.day = 1
        
        var anchorComponents = Calendar.current.dateComponents([.day, .month, .year], from: Date())
        anchorComponents.hour = 0
        let anchorDate = Calendar.current.date(from: anchorComponents)!
        
        let query = HKStatisticsCollectionQuery(quantityType: type,
                                                quantitySamplePredicate: nil,
                                                options: [.cumulativeSum],
                                                anchorDate: anchorDate,
                                                intervalComponents: interval)
        
        
        query.initialResultsHandler = { _, results, error in
            var arr = [HKStatistics]()
            guard let results = results else {
                print(error.debugDescription)
                completion(nil, error)
                return
            }
            
            results.enumerateStatistics(from: pDate!, to: Date()) { statistics, _ in
                arr.append(statistics)
            }
            completion(arr, nil)
            return
        }
        
        healthStore.execute(query)
    }
    
    
    func writeSample(for quantityType: HKQuantityType, sampleQuantity: HKQuantity, completion: @escaping (Bool, Error?) -> Void) {
        
        let sample = HKQuantitySample(type: quantityType, quantity: sampleQuantity, start: Date(), end: Date())
        healthStore.save(sample) { (sucess, error) in
            DispatchQueue.main.async {
                completion(sucess, error)
            }
        }
    }
    
}
