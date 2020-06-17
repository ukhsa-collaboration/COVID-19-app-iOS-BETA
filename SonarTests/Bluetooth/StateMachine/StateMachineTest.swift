import Foundation

import XCTest

@testable import Sonar

class StateMachineTest: TestCase {

    func test_happyPath() throws {
        let persistence = PersistenceDouble()

        let peripheralManager = FakePeripheralManager()
        peripheralManager.setState(.poweredOn)
        
        let nursery = ConcreteBluetoothNursery(
            persistence: persistence,
            userNotificationCenter: UNUserNotificationCenter.current(),
            notificationCenter: NotificationCenter.default,
            monitor: NoOpAppMonitoring(),
            peripheralManagerFactory: {
                return peripheralManager
            },
            centralManagerFactory: { listener in
                return FakeBTCentralManager(listener)
            }
        )

        nursery.contactEventRepository.reset()
        nursery.startBluetooth(registration: nil)

        let stubCentral = FakeBTCentralManager(nursery.listener!)
        stubCentral.setState(.poweredOn)

        nursery.listener?.centralManagerDidUpdateState(stubCentral)
        nursery.broadcaster?.peripheralManagerDidUpdateState(peripheralManager)

        // should call into the delegate.listener( didReadTxPower)
        // should call central.connect
        // assertions
        XCTAssertEqual(nursery.contactEventRepository.contactEvents.count, 1)
        XCTAssertEqual(nursery.contactEventRepository.contactEvents.first!.rssiValues, [-56])
    }
}

class FakeBTCharacteristic: SonarBTCharacteristic {
    private let id: SonarBTUUID
    
    init(uuid: SonarBTUUID) {
        self.id = uuid
        super.init(type: uuid, properties: SonarBTCharacteristicProperties([.read, .notify]), value: nil, permissions: .readable)
    }
    
    class var sonarIdCharacteristic: FakeBTCharacteristic {
        FakeBTCharacteristic(uuid: Environment.sonarIdCharacteristicUUID)
    }
    
    class var keepaliveCharacteristic: FakeBTCharacteristic {
        FakeBTCharacteristic(uuid: Environment.keepaliveCharacteristicUUID)
    }
    
    override var uuid: SonarBTUUID {
        return id
    }
}

class FakeBTService: SonarBTService {
    private let id: SonarBTUUID
    
    init(uuid: SonarBTUUID) {
        self.id = uuid
        super.init(type: uuid, primary: false)
    }
    
    convenience init() {
        self.init(uuid: Environment.sonarServiceUUID)
    }
    
    override var characteristics: [SonarBTCharacteristic]? {
        get {
            return [FakeBTCharacteristic.sonarIdCharacteristic, FakeBTCharacteristic.keepaliveCharacteristic]
        }
        set {}
    }
    
    override var uuid: SonarBTUUID {
        return id
    }
}

class FakeBTPeripheral: SonarBTPeripheral {
    private let id: UUID
    private let name: String?
    
    override init(delegate: SonarBTPeripheralDelegate?) {
        self.id = UUID()
        self.name = "Fake Peripheral"
        super.init(delegate: delegate)
    }
    
    override var services: [SonarBTService]? {
        return [FakeBTService()]
    }

    override var identifier: UUID {
        return self.id
    }
    
    override var identifierWithName: String {
        return "\(id) (\(name ?? "unknown"))"
    }
    
    override func readRSSI() {
        delegate?.peripheral(self, didReadRSSI: NSNumber(-56), error: nil)
    }
    
    override func discoverServices(_ serviceUUIDs: [SonarBTUUID]?) {
        delegate?.peripheral(self, didDiscoverServices: nil)
    }
    
    override func discoverCharacteristics(_ characteristicUUIDs: [SonarBTUUID]?, for service: SonarBTService) {
        delegate?.peripheral(self, didDiscoverCharacteristicsFor: FakeBTService(), error: nil)
    }
    
    override func readValue(for characteristic: SonarBTCharacteristic) {
        delegate?.peripheral(self, didUpdateValueFor: characteristic, error: nil)
    }
    
    override func setNotifyValue(_ enabled: Bool, for characteristic: SonarBTCharacteristic) {
        delegate?.peripheral(self, didUpdateNotificationStateFor: characteristic, error: nil)
    }
    
    override var state: SonarBTPeripheralState {
        return .connecting
    }
}

class FakePeripheralManager: SonarBTPeripheralManager {
    private var stubState: SonarBTManagerState = .unknown

    init() {
        super.init(delegate: nil, queue: nil, options: nil)
    }
    
    func setState(_ desiredState: SonarBTManagerState) {
        stubState = desiredState
    }
    
    override var state: SonarBTManagerState {
        return stubState
    }
    
    override func updateValue(_ value: Data, for characteristic: SonarBTCharacteristic, onSubscribedCentrals centrals: [SonarBTCentral]?) -> Bool {
        return true
    }
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
        return stubState
    }

    override func scanForPeripherals(withServices serviceUUIDs: [SonarBTUUID]?, options: [String : Any]? = nil) {
        listener.centralManager(
            self,
            didDiscover: FakeBTPeripheral(delegate: listener),
            advertisementData: [:],
            rssi: NSNumber(-47)
        )
    }

    override func connect(_ peripheral: SonarBTPeripheral, options: [String : Any]? = nil) {
        listener.centralManager(self, didConnect: peripheral)
    }

}
