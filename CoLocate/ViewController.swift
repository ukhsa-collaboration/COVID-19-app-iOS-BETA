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
import CoreData

class ViewController: UIViewController {
    
    var broadcaster: BTLEBroadcaster!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print("Initialising device ID")
        initDeviceID()
        print("Initialising location services")
        checkLocationServices()
        print("Initialising bluetooth services")
        
        broadcaster = BTLEBroadcaster()
        broadcaster.start()
        
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
    @IBOutlet weak var recordsSaved: UILabel!
    @IBOutlet weak var lastAccuracy: UILabel!
    
    // Combination or MAJOR and MINOR gives many million ID options for a user on a given device
    var major:UInt16?
    var minor:UInt16?
    
    private var fetchedBeaconRC: NSFetchedResultsController<BeaconPing>!
    private var appDelegate = UIApplication.shared.delegate as! AppDelegate
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    let locationManager = CLLocationManager()
    let regionInMeters:Double = 1000
    
    var peripheralManager:CBPeripheralManager?
    var transmitRegion:CLBeaconRegion?
    var queryRegion:CLBeaconRegion?
    
    //let coreDataManager = CoreDataManager(modelName: "BeaconModel")
    
    func initDeviceID() {
        // TODO generate major and minor or check for JSON
        //let path = Bundle.main.path(forResource: "locatedata.json", ofType: "json")
        let path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent("locatedata.json") {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                print("FILE AVAILABLE")
                // load major and minor
                do {
                    let fileUrl = URL(fileURLWithPath: filePath)
                    let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let major = json["major"] as? UInt16 {
                            self.major = major
                        }
                        if let minor = json["minor"] as? UInt16 {
                            self.minor = minor
                        }
                    }
                } catch {
                    // Handle error here
                }
                print("READ USER JSON FILE")
            } else {
                print("FILE NOT AVAILABLE")
                // generate uint16 at random
                self.major = UInt16.random(in:UInt16.min...UInt16.max)
                self.minor = UInt16.random(in:UInt16.min...UInt16.max)
                // save to json file
                var dictonary : [String : Any] = ["major": self.major,"minor": self.minor]
                do {
                    if let jsonData = try JSONSerialization.data(withJSONObject: dictonary, options: .init(rawValue: 0)) as? Data
                    {
                        // Check if everything went well
                        print(NSString(data: jsonData, encoding: 1)!)

                        try jsonData.write(to: pathComponent, options: [.atomicWrite])
                    }
                } catch {
                    // TODO handle write errors
                }
                // TODO initialise registration of user
                print("WRITTEN USER JSON FILE")
            }
        } else {
            print("FILE PATH NOT AVAILABLE")
        }
    }
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
        nearBeaconID.text = "Bluetooth beacon ID: " + String(describing: beacons.first!.major) + "." + String(describing: beacons.first!.minor)
        nearBeaconAccuracy.text = "Bluetooth proximity accuracy: " + (String(describing: beacons.first!.accuracy))
        /*
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
        */
        
        // Loop over all contacts
        // get NOW
        let now = Date()
        for beacon in beacons {
            let ping = BeaconPing(context: context)
            //ping.remoteID = beacon.proximityUUID
            ping.major = Int16(beacon.major)
            ping.minor = Int16(beacon.minor)
            ping.when = now
            switch beacon.proximity {
            case .immediate:
                print("immediately - < 1 metre")
                nearBeaconProximity.text = "Bluetooth beacon proximity: < 1 metre"
                ping.proximity = "immediate"
                break
            case .near:
                print("near - 1-3 metres")
                nearBeaconProximity.text = "Bluetooth beacon proximity: 1-3 metres"
                ping.proximity = "near"
                break
            case .far:
                print("far - > 3 metres")
                nearBeaconProximity.text = "Bluetooth beacon proximity: > 3 metres"
                ping.proximity = "far"
                break
            case .unknown:
                print("unknown range")
                nearBeaconProximity.text = "Bluetooth beacon proximity: unknown"
                ping.proximity = "unknown"
                break
            }
            ping.accuracy = beacon.accuracy
            appDelegate.saveContext()
            print("Saved beacon ping")
            
        }
        
        // load saved count
        //let fetch: NSFetchRequest = BeaconPing.fetchRequest()
        let keypathExp = NSExpression(forKeyPath: "when") // can be any column
        let expression = NSExpression(forFunction: "count:", arguments: [keypathExp])

        let countDesc = NSExpressionDescription()
        countDesc.expression = expression
        countDesc.name = "count"
        countDesc.expressionResultType = .integer64AttributeType
        //let fetch = BeaconPing.fetchRequest() as NSFetchRequest<BeaconPing>
        let fetch:NSFetchRequest<NSDictionary> = NSFetchRequest<NSDictionary>(entityName: "BeaconPing")
        //let fetch = NSFetchRequest(entityName: "BeaconPing")
        //let fetch = NSManagedObject.fetchRequest()
        //fetch.entity = NSEntityDescription.entity(forEntityName: "BeaconPing",in: context)
        fetch.returnsObjectsAsFaults = false
        fetch.propertiesToFetch = [countDesc]
        fetch.resultType = .dictionaryResultType
        do {
            //let frc = NSFetchedResultsController(fetchRequest: fetch, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            let results = try context.fetch(fetch)
            // results is now an array: [Record]
            recordsSaved.text = "Beacon Records Saved: " + String(describing: results.first!["count"]!)
            
        } catch {
            NSLog("Error fetching entity: %@", String(describing: error))
        }
            
        // load last accuracy too
        let request = BeaconPing.fetchRequest() as NSFetchRequest<BeaconPing>
        let sort = NSSortDescriptor(key: #keyPath(BeaconPing.when), ascending: false)
        request.sortDescriptors = [sort]
        do {
            self.fetchedBeaconRC = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            self.fetchedBeaconRC.delegate = self
            try self.fetchedBeaconRC.performFetch()
        } catch let error as NSError {
          print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        
        
    }

}

extension ViewController: NSFetchedResultsControllerDelegate {
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?,
                  for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    print("CoreData beacon load done")
    let index = (newIndexPath ?? nil)
    guard let cellIndex = index else { return }
    switch type {
      case .insert:
        //todoTableView.insertRows(at: [cellIndex], with: .fade)
        let ping = fetchedBeaconRC.object(at: newIndexPath!)
        lastAccuracy.text = "Last Accuracy: " + String(describing: ping.accuracy)
      default:
        break
    }
  }
}
