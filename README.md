# Fitbit-OAuth-Swift
Hey guys! Here's a project I was working on for iOS that connects with the Fitbit API. Becuase of some limitations set by Apple, I can't program a native app with the functionality I wanted. 

There's a button that will open up a browser and allow you to sign into Fitbit and then step count will be populated with current date.

The Fitbit API can be a bit tricky. I used the OAuth 2.0  API and WebKit for handling session.

Feel free to use this code to build your own iOS app that connects with Fitbit. You will need to register your app with Fitbit and add your own Consumer Secret and Key in AppConstant.swift, and change to callback URI.


# Apple-Health-Swift
There's a sunc button that will request Authorization for permition and allow you to access HealthKit data and then step count will be populated with current date.

HealthKit is not supported on all iOS devices.  Using HKHealthStore APIs on devices which are not
supported will result in errors with the HKErrorHealthDataUnavailable code.  Call isHealthDataAvailable
before attempting to use other parts of the framework.


