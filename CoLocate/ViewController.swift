//
//  ViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreBluetooth

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print("Initialising location services")
        checkLocationServices()
        print("Initialising bluetooth services")
        initBluetooth()
        checkBluetooth()
        print("Initialisation complete")
    }

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationStatus: UILabel!
    @IBOutlet weak var bluetoothStatus: UILabel!
    @IBOutlet weak var nearbyBeacons: UILabel!
    @IBOutlet weak var nearBeaconID: UILabel!
    @IBOutlet weak var nearBeaconProximity: UILabel!
    @IBOutlet weak var myBeaconID: UILabel!
    @IBOutlet weak var nearBeaconAccuracy: UILabel!
    
    
    let locationManager = CLLocationManager()
    let regionInMeters:Double = 1000
    
    var peripheralManager:CBPeripheralManager?
    var transmitRegion:CLBeaconRegion?
    
    func setupLocationManager() {
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        // TODO determine what this means per device, and show accuracy on map
    }
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            // setup our location manager
            setupLocationManager()
            checkLocationAuth()
        } else {
            // TODO show some message here, with a link to fix it
        }
    }
    
    func initBluetooth() {
        let uuid = UUID(uuidString: "c1f5983c-fa94-4ac8-8e2e-bb86d6de9b21")! //UUID()
        let identifier = "uk.nhs.colocate.beacon"
        let region = CLBeaconRegion(proximityUUID: uuid, major: 1, minor: 0, identifier: identifier)
        transmitRegion = region
        myBeaconID.text = "My phone's beacon ID: " + uuid.uuidString
        
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func checkBluetooth() {
        
        checkBluetoothAuth()
        checkBluetoothState()
        
        rangeBeacons(region:transmitRegion!) // TODO make these unique
        //advertiseDevice(region:region)
    }
    
    func checkBluetoothAuth() {
        print(" - Checking bluetooth auth")
        switch CBPeripheralManager.authorizationStatus() {
        case .authorized:
            // ok
            break
        case .denied:
            print("Bluetooth use not authorised")
            break
        case .notDetermined:
            print("Bluetooth use auth not determined")
            break
        case .restricted:
            print("Bluetooth use restricted")
            break
        }
    }
    
    func checkBluetoothState() {
        print(" - Checking bluetooth enabled")
        switch peripheralManager!.state {
        case .poweredOn:
            print("Bluetooth is On.")
            bluetoothStatus.text = "Bluetooth Status: On"
            break
        case .poweredOff:
            print("Bluetooth is Off.")
            bluetoothStatus.text = "Bluetooth Status: Off"
            // TODO show enable link button
            break
        case .resetting:
            bluetoothStatus.text = "Bluetooth Status: Resetting"
            break
        case .unauthorized:
            bluetoothStatus.text = "Bluetooth Status: Unauthorised"
            break
        case .unsupported:
            bluetoothStatus.text = "Bluetooth Status: Unsupported"
            break
        case .unknown:
            bluetoothStatus.text = "Bluetooth Status: Unknown"
            break
        default:
            bluetoothStatus.text = "Bluetooth Status: Other"
            break
        }
    }
    
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center:location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func showMap() {
        locationManager.requestAlwaysAuthorization()
        mapView.showsUserLocation = true
        //mapView.showAnnotations(<#T##annotations: [MKAnnotation]##[MKAnnotation]#>, animated: <#T##Bool#>)
        centerViewOnUserLocation()
        locationManager.startUpdatingLocation()
        
    }
    
    func checkLocationAuth() {
        print(" - Checking location auth")
        switch CLLocationManager.authorizationStatus() {
        
        case .authorizedWhenInUse:
            // Work, but give a link and recommend 'always'
            locationStatus.text = "Location Status: Authorised when in use only!"
            showMap()
            break
        case .authorizedAlways:
            locationStatus.text = "Location Status: Authorised"
            showMap()
            break
        case .denied:
            locationManager.requestAlwaysAuthorization()
            break
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            break
        case .restricted:
            // TODO show alert as to why it wont work
            break
        }
    }
    
    func advertiseDevice(region : CLBeaconRegion) {
        print(" - Advertising this device as a beacon")
        //let peripheral = CBPeripheralManager(delegate: self, queue: nil)
        let peripheralData = region.peripheralData(withMeasuredPower: nil)
        
        peripheralManager?.startAdvertising(((peripheralData as NSDictionary) as! [String : Any]))
    }
    
    func rangeBeacons(region: CLBeaconRegion) {
        print(" - Ranging other nearby beacons")
        
        locationManager.startRangingBeacons(in: region)
    }
}

extension ViewController:CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            checkBluetooth()
            let peripheralData = transmitRegion!.peripheralData(withMeasuredPower: nil)
            peripheral.startAdvertising(((peripheralData as NSDictionary) as! [String : Any]))
        }
    }
}

extension ViewController:CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuth()
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        guard let discoveredBeaconProximity = beacons.first?.proximity else { return }
        
        // TODO loop over all beacons in range
        nearbyBeacons.text = "Nearby NHS Co-Locate users: " + String(beacons.count)
        
        // unknown, immediate (<3 feet), near (3-5 feet), far (beyond 5 ft but in range)
        // updates every second or so
        print("UUID: " + (beacons.first?.proximityUUID.uuidString)! + " accuracy: " + "\(String(describing: beacons.first?.accuracy))")
        nearBeaconID.text = "Bluetooth beacon ID: " + (beacons.first?.proximityUUID.uuidString)!
        nearBeaconAccuracy.text = "Bluetooth proximity accuracy: " + (String(describing: beacons.first!.accuracy))
        switch discoveredBeaconProximity {
        case .immediate:
            print("immediately - < 1 metre")
            nearBeaconProximity.text = "Bluetooth beacon proximity: < 1 metre"
            break
        case .near:
            print("near - 1-3 metres")
            nearBeaconProximity.text = "Bluetooth beacon proximity: 1-3 metres"
            break
        case .far:
            print("far - > 3 metres")
            nearBeaconProximity.text = "Bluetooth beacon proximity: > 3 metres"
            break
        case .unknown:
            print("unknown range")
            nearBeaconProximity.text = "Bluetooth beacon proximity: unknown"
            break
        }
    }

}
