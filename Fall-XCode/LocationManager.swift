//import core location for using location services

import CoreLocation
//class which handles location management
class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    //private instance of clllocationmanager to manage location services
    private let manager = CLLocationManager()
    //variable to store the most recently recorded location
    var lastKnownLocation: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    // Delegate method that handles changes in location authorization status
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    // Delegate method that is called when new locations are available
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Update lastKnownLocation with the most recent location
        lastKnownLocation = locations.last
    }
}
