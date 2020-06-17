import Foundation

import XCTest

@testable import Sonar

class BluetoothTests: TestCase {

    func test_happyPath() throws {
        // inject decisions at event points, e.g. be able to read multiple rssi then error
        
        // power on -> connect device -> read rssi (3x) -> disconnect
        
        // setup
        let peripheralManager = FakePeripheralManager()
        let stubCentral = FakeBTCentralManager()
        
        let nursery = ConcreteBluetoothNursery(
            persistence: PersistenceDouble(),
            userNotificationCenter: UNUserNotificationCenter.current(),
            notificationCenter: NotificationCenter.default,
            monitor: NoOpAppMonitoring(),
            peripheralManagerFactory: {
                return peripheralManager
            },
            centralManagerFactory: { listener in
                stubCentral.listener = listener
                return stubCentral
            }
        )
        nursery.contactEventRepository.reset()
        nursery.startBluetooth(registration: nil)

        // power on
        stubCentral.setState(.poweredOn)
        peripheralManager.setState(.poweredOn)
        nursery.listener?.centralManagerDidUpdateState(stubCentral)
        nursery.broadcaster?.peripheralManagerDidUpdateState(peripheralManager)
        
        XCTAssertEqual(nursery.contactEventRepository.contactEvents.count, 1)
        XCTAssertEqual(nursery.contactEventRepository.contactEvents.first!.rssiValues, [-56])
    }
}
