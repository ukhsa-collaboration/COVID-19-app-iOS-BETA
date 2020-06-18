import Foundation

import XCTest

@testable import Sonar

class BluetoothTests: TestCase {
    func test_happyPath() throws {
        SequenceBuilder
            .aSequence
            .powerOn()
            .readsRSSIValues(-56, -45)
            .verify { nursery in
                Thread.sleep(forTimeInterval: 2.0)
                XCTAssertEqual(nursery.contactEventRepository.contactEvents.count, 1)
                XCTAssertEqual(nursery.contactEventRepository.contactEvents.first!.rssiValues, [-56, -45])
        }
    }
}

class SequenceBuilder {
    private var nursery: BluetoothNursery
    private var peripheralManager: FakeBTPeripheralManager
    private var centralManager: FakeBTCentralManager
    
    class var aSequence: SequenceBuilder {
        let peripheralManager = FakeBTPeripheralManager()
        let centralManager = FakeBTCentralManager(fakePeripheralManager: peripheralManager)
        
        let nursery = ConcreteBluetoothNursery(
            persistence: PersistenceDouble(),
            userNotificationCenter: UNUserNotificationCenter.current(),
            notificationCenter: NotificationCenter.default,
            monitor: NoOpAppMonitoring(),
            peripheralManagerFactory: {
                return peripheralManager
            },
            centralManagerFactory: { listener in
                centralManager.listener = listener
                return centralManager
            },
            keepaliveInterval: 0.5
        )
        nursery.contactEventRepository.reset()
        nursery.startBluetooth(registration: nil)
        
        return SequenceBuilder(nursery, centralManager: centralManager, peripheralManager: peripheralManager)
    }
    
    init(_ nursery: BluetoothNursery, centralManager: FakeBTCentralManager, peripheralManager: FakeBTPeripheralManager) {
        self.nursery = nursery
        self.centralManager = centralManager
        self.peripheralManager = peripheralManager
    }
    
    func readsRSSIValues(_ rssiValues: Int...) -> SequenceBuilder {
        centralManager.connectedPeripheralsWillSendRSSIs(rssiValues)
        return self
    }
    
    func powerOn() -> SequenceBuilder {
        centralManager.setState(.poweredOn)
        peripheralManager.setState(.poweredOn)
        return self
    }
    
    func verify(_ verificationClosure: (_ nursery: BluetoothNursery) -> Void) {
        nursery.listener?.centralManagerDidUpdateState(centralManager)
        nursery.broadcaster?.peripheralManagerDidUpdateState(peripheralManager)
        verificationClosure(nursery)
    }
}
