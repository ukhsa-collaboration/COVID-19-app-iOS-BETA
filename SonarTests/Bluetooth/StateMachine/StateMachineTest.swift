import Foundation

import XCTest

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


        let stubCentral = FakeBTCentralManager(nursery.listener!)
        stubCentral.setState(.poweredOn)

        nursery.listener?.centralManagerDidUpdateState(stubCentral)

        // should call into the delegate.listener( didReadTxPower)
        // should call central.connect


        // assertions
        // have some readings on disk or persistence object with expected ID and RSSI values
    }
}

class FakeBTPeripheral: SonarBTPeripheral {
}

class FakeBTCentralManager: SonarBTCentralManager {
    private var stubState: SonarBTManagerState = .unknown
    private var listener: BTLEListener

    func setState(_ desiredState: SonarBTManagerState) {
        stubState = desiredState
    }

    init(_ listener: BTLEListener) {
        self.listener = listener
        super.init(delegate: nil, peripheralDelegate: nil, queue: nil, options: nil)
    }

    override var state: SonarBTManagerState {
        get {
            return stubState
        }
    }

    override func scanForPeripherals(withServices serviceUUIDs: [SonarBTUUID]?, options: [String : Any]? = nil) {
        debugPrint("HappyPathFakeCBCentralManager.scanForPeripherals(withServices: \(String(describing: serviceUUIDs)))")

        listener.centralManager(
            self,
            didDiscover: FakeBTPeripheral(delegate: nil),
            advertisementData: [:],
            rssi: NSNumber(-47)
        )
    }

    override func connect(_ peripheral: SonarBTPeripheral, options: [String : Any]? = nil) {
        debugPrint("HappyPathFakeCBCentralManager.connect(peripheral: \(String(describing: peripheral)), options: \(String(describing: options))")

        listener.centralManager(self, didConnect: peripheral)
    }

}
