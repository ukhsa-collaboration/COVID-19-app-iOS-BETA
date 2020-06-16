import Foundation

import XCTest
import CoreBluetooth

@testable import Sonar

class StateMachineTest: TestCase {

    func test_happyPath() throws {
        let persistence = Persistence(
            secureRegistrationStorage: SecureRegistrationStorage(),
            broadcastKeyStorage: SecureBroadcastRotationKeyStorage(),
            monitor: NoOpAppMonitoring(),
            storageChecker: StorageChecker(service: "")
        )

        let nursery = ConcreteBluetoothNursery(
            persistence: persistence,
            userNotificationCenter: UNUserNotificationCenter.current(),
            notificationCenter: NotificationCenter.default,
            monitor: NoOpAppMonitoring()
        )


        nursery.startBluetooth(registration: nil)


        let stubCentral = HappyPathFakeCBCentralManager(nursery.listener!)
        stubCentral.setState(.poweredOn)

        nursery.listener?.centralManagerDidUpdateState(stubCentral)

        // should call into the delegate.listener( didReadTxPower)
        // should call central.connect


        // assertions
        // have some readings on disk or persistence object with expected ID and RSSI values
    }
}

class HappyPathFakeCBCentralManager: CBCentralManager {
    private var stubState: CBManagerState = .unknown
    private var listener: BTLEListener

    func setState(_ desiredState: CBManagerState) {
        stubState = desiredState
    }

    init(_ listener: BTLEListener) {
        self.listener = listener
        super.init(delegate: nil, queue: nil, options: nil)
    }

    override var state: CBManagerState {
        get {
            return stubState
        }
    }

    override func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]? = nil) {
        debugPrint("HappyPathFakeCBCentralManager.scanForPeripherals(withServices: \(String(describing: serviceUUIDs)))")

        listener.centralManager(
            self,
            didDiscover: CBPeripheral(name: "Some name"),
            advertisementData: [:],
            rssi: NSNumber(-47)
        )
    }

    override func connect(_ peripheral: CBPeripheral, options: [String : Any]? = nil) {
        debugPrint("HappyPathFakeCBCentralManager.connect(peripheral: \(String(describing: peripheral)), options: \(String(describing: options))")

        listener.centralManager(self, didConnect: peripheral)
    }

    
}
