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
        
        guard let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount),
                let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate)
        else {
                
                completion(false, HealthKitControllerError.DataTypeNotAvailable)
                return
        }
        
        let dataToWrite: Set<HKSampleType> = [heartRate]
        
        let dataToRead: Set<HKSampleType> = [heartRate,stepCount]
        
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


/*
 
 let bodyMassIndex = HKObjectType.quantityType(forIdentifier: .bodyMassIndex),
 let bodyFatPercentage = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage),
 let height = HKObjectType.quantityType(forIdentifier: .height),
 let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass),
 let leanBodyMass = HKObjectType.quantityType(forIdentifier: .leanBodyMass),
 let waistCircumference = HKObjectType.quantityType(forIdentifier: .waistCircumference),
 let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount),
 let distanceWalkingRunning = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
 let distanceCycling = HKObjectType.quantityType(forIdentifier: .distanceCycling),
 let distanceWheelchair = HKObjectType.quantityType(forIdentifier: .distanceWheelchair),
 let basalEnergyBurned = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
 let activeEnergyBurned = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
 let flightsClimbed = HKObjectType.quantityType(forIdentifier: .flightsClimbed),
 let nikeFuel = HKObjectType.quantityType(forIdentifier: .nikeFuel),
 let appleExerciseTime = HKObjectType.quantityType(forIdentifier: .appleExerciseTime),
 let pushCount = HKObjectType.quantityType(forIdentifier: .pushCount),
 let distanceSwimming = HKObjectType.quantityType(forIdentifier: .distanceSwimming),
 let swimmingStrokeCount = HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount),
 let vo2Max = HKObjectType.quantityType(forIdentifier: .vo2Max),
 let distanceDownhillSnowSports = HKObjectType.quantityType(forIdentifier: .distanceDownhillSnowSports),
 let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate),
 let bodyTemperature = HKObjectType.quantityType(forIdentifier: .bodyTemperature),
 let basalBodyTemperature = HKObjectType.quantityType(forIdentifier: .basalBodyTemperature),
 let bloodPressureSystolic = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic),
 let bloodPressureDiastolic = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic),
 let respiratoryRate = HKObjectType.quantityType(forIdentifier: .respiratoryRate),
 let restingHeartRate = HKObjectType.quantityType(forIdentifier: .respiratoryRate),
 let walkingHeartRateAverage = HKObjectType.quantityType(forIdentifier: .walkingHeartRateAverage),
 let heartRateVariabilitySDNN = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
 let oxygenSaturation = HKObjectType.quantityType(forIdentifier: .respiratoryRate),
 let peripheralPerfusionIndex = HKObjectType.quantityType(forIdentifier: .peripheralPerfusionIndex),
 let bloodGlucose = HKObjectType.quantityType(forIdentifier: .bloodGlucose),
 let numberOfTimesFallen = HKObjectType.quantityType(forIdentifier: .numberOfTimesFallen),
 let electrodermalActivity = HKObjectType.quantityType(forIdentifier: .electrodermalActivity),
 let inhalerUsage = HKObjectType.quantityType(forIdentifier: .inhalerUsage),
 let insulinDelivery = HKObjectType.quantityType(forIdentifier: .insulinDelivery),
 let bloodAlcoholContent = HKObjectType.quantityType(forIdentifier: .bloodAlcoholContent),
 let forcedVitalCapacity = HKObjectType.quantityType(forIdentifier: .forcedVitalCapacity),
 let forcedExpiratoryVolume1 = HKObjectType.quantityType(forIdentifier: .forcedExpiratoryVolume1),
 let peakExpiratoryFlowRate = HKObjectType.quantityType(forIdentifier: .peakExpiratoryFlowRate),
 let dietaryFatTotal = HKObjectType.quantityType(forIdentifier: .dietaryFatTotal),
 let dietaryFatPolyunsaturated = HKObjectType.quantityType(forIdentifier: .dietaryFatPolyunsaturated),
 let dietaryFatMonounsaturated = HKObjectType.quantityType(forIdentifier: .dietaryFatMonounsaturated),
 let dietaryFatSaturated = HKObjectType.quantityType(forIdentifier: .dietaryFatSaturated),
 let dietaryCholesterol = HKObjectType.quantityType(forIdentifier: .dietaryCholesterol),
 let dietarySodium = HKObjectType.quantityType(forIdentifier: .dietarySodium),
 let dietaryCarbohydrates = HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates),
 let dietaryFiber = HKObjectType.quantityType(forIdentifier: .dietaryFiber),
 let dietarySugar = HKObjectType.quantityType(forIdentifier: .dietarySugar),
 let dietaryEnergyConsumed = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed),
 let dietaryProtein = HKObjectType.quantityType(forIdentifier: .dietaryProtein),
 let dietaryVitaminA = HKObjectType.quantityType(forIdentifier: .dietaryVitaminA),
 let dietaryVitaminB6 = HKObjectType.quantityType(forIdentifier: .dietaryVitaminB6),
 let dietaryVitaminB12 = HKObjectType.quantityType(forIdentifier: .dietaryVitaminB12),
 let dietaryVitaminC = HKObjectType.quantityType(forIdentifier: .dietaryVitaminC),
 let dietaryVitaminD = HKObjectType.quantityType(forIdentifier: .dietaryVitaminD),
 let dietaryVitaminE = HKObjectType.quantityType(forIdentifier: .dietaryVitaminE),
 let dietaryCalcium = HKObjectType.quantityType(forIdentifier: .dietaryCalcium),
 let dietaryVitaminK = HKObjectType.quantityType(forIdentifier: .dietaryVitaminK),
 let dietaryIron = HKObjectType.quantityType(forIdentifier: .dietaryIron),
 let dietaryThiamin = HKObjectType.quantityType(forIdentifier: .dietaryThiamin),
 let dietaryRiboflavin = HKObjectType.quantityType(forIdentifier: .dietaryRiboflavin),
 let dietaryNiacin = HKObjectType.quantityType(forIdentifier: .dietaryNiacin),
 let dietaryFolate = HKObjectType.quantityType(forIdentifier: .dietaryFolate),
 let dietaryBiotin = HKObjectType.quantityType(forIdentifier: .dietaryBiotin),
 let dietaryPantothenicAcid = HKObjectType.quantityType(forIdentifier: .dietaryPantothenicAcid),
 let dietaryPhosphorus = HKObjectType.quantityType(forIdentifier: .dietaryPhosphorus),
 let dietaryIodine = HKObjectType.quantityType(forIdentifier: .dietaryIodine),
 let dietaryMagnesium = HKObjectType.quantityType(forIdentifier: .dietaryMagnesium),
 let dietaryZinc = HKObjectType.quantityType(forIdentifier: .dietaryZinc),
 let dietarySelenium = HKObjectType.quantityType(forIdentifier: .dietarySelenium),
 let dietaryCopper = HKObjectType.quantityType(forIdentifier: .dietaryCopper),
 let dietaryManganese = HKObjectType.quantityType(forIdentifier: .dietaryManganese),
 let dietaryChromium = HKObjectType.quantityType(forIdentifier: .dietaryChromium),
 let dietaryMolybdenum = HKObjectType.quantityType(forIdentifier: .dietaryMolybdenum),
 let dietaryChloride = HKObjectType.quantityType(forIdentifier: .dietaryChloride),
 let dietaryPotassium = HKObjectType.quantityType(forIdentifier: .dietaryPotassium),
 let dietaryCaffeine = HKObjectType.quantityType(forIdentifier: .dietaryCaffeine),
 let dietaryWater = HKObjectType.quantityType(forIdentifier: .dietaryWater),
 let uvExposure = HKObjectType.quantityType(forIdentifier: .uvExposure)
 
 bodyMassIndex,
 bodyFatPercentage,
 height,
 bodyMass,
 leanBodyMass,
 waistCircumference,
 stepCount,
 distanceWalkingRunning,
 distanceCycling,
 distanceWheelchair,
 basalEnergyBurned,
 activeEnergyBurned,
 flightsClimbed,
 nikeFuel,
 appleExerciseTime,
 pushCount,
 distanceSwimming,
 swimmingStrokeCount,
 vo2Max,
 distanceDownhillSnowSports,
 heartRate,
 bodyTemperature,
 basalBodyTemperature,
 bloodPressureSystolic,
 bloodPressureDiastolic,
 respiratoryRate,
 restingHeartRate,
 walkingHeartRateAverage,
 heartRateVariabilitySDNN,
 oxygenSaturation,
 peripheralPerfusionIndex,
 bloodGlucose,
 numberOfTimesFallen,
 electrodermalActivity,
 inhalerUsage,
 insulinDelivery,
 bloodAlcoholContent,
 forcedVitalCapacity,
 forcedExpiratoryVolume1,
 peakExpiratoryFlowRate,
 dietaryFatTotal,
 dietaryFatPolyunsaturated,
 dietaryFatMonounsaturated,
 dietaryFatSaturated,
 dietaryCholesterol,
 dietarySodium,
 dietaryCarbohydrates,
 dietaryFiber,
 dietarySugar,
 dietaryEnergyConsumed,
 dietaryProtein,
 dietaryVitaminA,
 dietaryVitaminB6,
 dietaryVitaminB12,
 dietaryVitaminC,
 dietaryVitaminD,
 dietaryVitaminE,
 dietaryVitaminK,
 dietaryCalcium,
 dietaryIron,
 dietaryThiamin,
 dietaryRiboflavin,
 dietaryNiacin,
 dietaryFolate,
 dietaryBiotin,
 dietaryPantothenicAcid,
 dietaryPhosphorus,
 dietaryIodine,
 dietaryMagnesium,
 dietaryZinc,
 dietarySelenium,
 dietaryCopper,
 dietaryManganese,
 dietaryChromium,
 dietaryMolybdenum,
 dietaryChloride,
 dietaryPotassium,
 dietaryCaffeine,
 dietaryWater,
 uvExposure
 */
