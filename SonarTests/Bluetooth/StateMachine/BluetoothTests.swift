import Foundation

import XCTest
import Logging

@testable import Sonar

class BluetoothTests: TestCase {
    override func setUp() {
        continueAfterFailure = false
    }
    
    func test_happyPath() throws {
        SequenceBuilder
            .aSequence
            .powerOn()
            .readsRSSIValues(-47, -56, -45, -34)
            .verify { contactEventStorage in
                Thread.sleep(forTimeInterval: 2.0)
                XCTAssertEqual(contactEventStorage.contactEvents.count, 1)
                XCTAssertTrue(contactEventStorage.contactEvents.first?.rssiValues.count ?? 0 >= 4)
                XCTAssertEqual(contactEventStorage.contactEvents.first?.rssiValues[0..<4], [-47, -56, -45, -34])
        }
    }
}



protocol SonarBTReaderDelegate: class {
    func reader(_ reader: BTReader, didFind broadcastPayload: IncomingBroadcastPayload, for peripheral: Peripheral)
    func reader(_ reader: BTReader, didReadRSSI RSSI: Int, for peripheral: Peripheral)
    func reader(_ reader: BTReader, didReadTxPower txPower: Int, for peripheral: Peripheral)
}

protocol SonarBTScannerDelegate: class {
    func scanner(_ reader: BTScanner, didReadRSSI RSSI: Int, for peripheral: Peripheral)
}

class ContactEventsStorage {
    private let contactEventsRepository: ContactEventRepository
    
    init(contactEventsRepository: ContactEventRepository) {
        self.contactEventsRepository = contactEventsRepository
    }
    
    var contactEvents: [ContactEvent] {
        contactEventsRepository.contactEvents
    }
}

class FakeListener: Listener {
    func start(stateDelegate: ListenerStateDelegate?, delegate: ListenerDelegate?) {
        
    }
    
    func isHealthy() -> Bool {
        return true
    }
}

extension ContactEventsStorage: SonarBTScannerDelegate, SonarBTReaderDelegate {
    func reader(_ reader: BTReader, didFind broadcastPayload: IncomingBroadcastPayload, for peripheral: Peripheral) {
        contactEventsRepository.listener(FakeListener(), didFind: broadcastPayload, for: peripheral)
    }
    
    func scanner(_ reader: BTScanner, didReadRSSI RSSI: Int, for peripheral: Peripheral) {
        contactEventsRepository.listener(FakeListener(), didReadRSSI: RSSI, for: peripheral)
    }
    
    func reader(_ reader: BTReader, didReadRSSI RSSI: Int, for peripheral: Peripheral) {
        contactEventsRepository.listener(FakeListener(), didReadRSSI: RSSI, for: peripheral)
    }
    
    func reader(_ reader: BTReader, didReadTxPower txPower: Int, for peripheral: Peripheral) {
        contactEventsRepository.listener(FakeListener(), didReadTxPower: txPower, for: peripheral)
    }
}

class BluetoothCoordinator {
    private let broadcaster: BTBroadcaster
    private let scanner: BTScanner
    private let readerDelegate: SonarBTReaderDelegate?
    
    init(broadcaster: BTBroadcaster, scanner: BTScanner, readerDelegate: SonarBTReaderDelegate?) {
        self.broadcaster = broadcaster
        self.scanner = scanner
        self.readerDelegate = readerDelegate
    }
}

protocol SonarBTLivenessDelegate: class {
    func keepAlive()
}

class BTBroadcaster: SonarBTLivenessDelegate {
    private let peripheralManager: SonarBTPeripheralManager
    private var identityCharacteristic: SonarBTCharacteristic!
    private var keepaliveCharacteristic: SonarBTCharacteristic!
    
    private var started: Bool = false
    
    private var keepaliveQueue: DispatchQueue = DispatchQueue(label: "Sonar Keepalive Queue")
    private var keepaliveLastBroadcastedAt: Date = Date.distantPast
    private var keepaliveLastScheduledAt: Date = Date.distantPast
    private var keepaliveInterval: Double = 0.5
    private var keepaliveTimer: DispatchSourceTimer!
    
    init(peripheralManager: SonarBTPeripheralManager) {
        self.peripheralManager = peripheralManager
    }
    
    private func startBroadcasting() {
        let broadcastService = SonarBTService(type: Environment.sonarServiceUUID, primary: true)
        
        identityCharacteristic = SonarBTCharacteristic(
            type: Environment.sonarIdCharacteristicUUID,
            properties: SonarBTCharacteristicProperties([.read, .notify]),
            value: nil,
            permissions: .readable)
        
        keepaliveCharacteristic = SonarBTCharacteristic(
            type: Environment.keepaliveCharacteristicUUID,
            properties: SonarBTCharacteristicProperties([.notify]),
            value: nil,
            permissions: .readable)
        
        broadcastService.characteristics = [identityCharacteristic, keepaliveCharacteristic!]
        peripheralManager.add(broadcastService)
        started = true
    }
    
    private let logger: Logger = {
        var logger = Logger(label: "[BT Broadcaster]")
        #if BLE_LOGLEVEL_NODEBUG
        logger.logLevel = .notice
        #else
        logger.logLevel = .debug
        #endif
        return logger
    }()
    
    func keepAlive() {
        if Date().timeIntervalSince(keepaliveLastBroadcastedAt) > keepaliveInterval {
            broadcastKeepAlive()
        }
        
        scheduleKeepalive()
    }
    
    private func scheduleKeepalive() {
        guard Date().timeIntervalSince(keepaliveLastScheduledAt) > keepaliveInterval else { return }
        
        keepaliveLastScheduledAt = Date()
        keepaliveTimer = DispatchSource.makeTimerSource(queue: keepaliveQueue)
        keepaliveTimer.setEventHandler { [unowned self] in
            self.broadcastKeepAlive()
        }
        keepaliveTimer.schedule(deadline: .now() + keepaliveInterval)
        keepaliveTimer.resume()
    }
    
    private func broadcastKeepAlive() {
        guard started else { return }

        var keepaliveValue = UInt8.random(in: .min ... .max)
        let value = Data(bytes: &keepaliveValue, count: MemoryLayout.size(ofValue: keepaliveValue))
        
        peripheralManager.updateValue(value, for: self.keepaliveCharacteristic, onSubscribedCentrals: nil)
        keepaliveLastBroadcastedAt = Date()
    }
}

extension BTBroadcaster: SonarBTPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: SonarBTPeripheralManager) {
        startBroadcasting()
    }
    
    func peripheralManager(_ peripheral: SonarBTPeripheralManager, willRestoreState dict: [String: Any]) {
    }
    
    func peripheralManager(_ peripheral: SonarBTPeripheralManager, didAdd service: SonarBTService, error: Error?) {
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: SonarBTPeripheralManager, error: Error?) {
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: SonarBTPeripheralManager) {
    }
    
    func peripheralManager(_ peripheral: SonarBTPeripheralManager, central: SonarBTCentral, didSubscribeTo characteristic: SonarBTCharacteristic) {
    }
    
    func peripheralManager(_ peripheral: SonarBTPeripheralManager, central: SonarBTCentral, didUnsubscribeFrom characteristic: SonarBTCharacteristic) {
    }
    
    func peripheralManager(_ peripheral: SonarBTPeripheralManager, didReceiveRead request: SonarBTATTRequest) {
    }
}

class BTScanner {
    private let centralManager: SonarBTCentralManager
    private let peripheralDelegate: SonarBTPeripheralDelegate
    weak var delegate: SonarBTScannerDelegate?
    weak var livenessDelegate: SonarBTLivenessDelegate?

    init(centralManager: SonarBTCentralManager, peripheralDelegate: SonarBTPeripheralDelegate) {
        self.centralManager = centralManager
        self.peripheralDelegate = peripheralDelegate
        
        centralManager.delegate = self
    }
    
    private func startScanning() {
        centralManager.scanForPeripherals(withServices: [Environment.sonarServiceUUID])
    }
    
    private let logger: Logger = {
        var logger = Logger(label: "[BT Scanner]")
        #if BLE_LOGLEVEL_NODEBUG
        logger.logLevel = .notice
        #else
        logger.logLevel = .debug
        #endif
        return logger
    }()
}

extension BTScanner: SonarBTCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: SonarBTCentralManager) {
        startScanning()
    }
    
    func centralManager(_ central: SonarBTCentralManager, willRestoreState dict: [String: Any]) {
    }
    
    func centralManager(_ central: SonarBTCentralManager, didConnect peripheral: SonarBTPeripheral) {
        logger.info("didConnect peripheral: \(peripheral.identifierWithName)")
        
        peripheral.delegate = peripheralDelegate
        peripheral.readRSSI()
    }
    
    func centralManager(_ central: SonarBTCentralManager, didFailToConnect peripheral: SonarBTPeripheral, error: Error?) {
    }
    
    func centralManager(_ central: SonarBTCentralManager, didDisconnectPeripheral peripheral: SonarBTPeripheral, error: Error?) {
    }
    
    func centralManager(_ central: SonarBTCentralManager, didDiscover peripheral: SonarBTPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        delegate?.scanner(self, didReadRSSI: RSSI.intValue, for: peripheral)
        
        central.connect(peripheral)
        livenessDelegate?.keepAlive()
    }
    
    func centralManager(_ central: SonarBTCentralManager, connectionEventDidOccur event: SonarBTConnectionEvent, for peripheral: SonarBTPeripheral) {
    }
}

class BTReader {
    weak var delegate: SonarBTReaderDelegate?
    weak var livenessDelegate: SonarBTLivenessDelegate?

    private let logger: Logger = {
        var logger = Logger(label: "[BT Scanner]")
        #if BLE_LOGLEVEL_NODEBUG
        logger.logLevel = .notice
        #else
        logger.logLevel = .debug
        #endif
        return logger
    }()
}

extension BTReader: SonarBTPeripheralDelegate {
    func peripheral(_ peripheral: SonarBTPeripheral, didDiscoverServices error: Error?) {
        
    }
    
    func peripheral(_ peripheral: SonarBTPeripheral, didModifyServices invalidatedServices: [SonarBTService]) {
        
    }
    
    func peripheral(_ peripheral: SonarBTPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        delegate?.reader(self, didReadRSSI: RSSI.intValue, for: peripheral)
    }
    
    func peripheral(_ peripheral: SonarBTPeripheral, didUpdateNotificationStateFor characteristic: SonarBTCharacteristic, error: Error?) {
        
    }
    
    func peripheral(_ peripheral: SonarBTPeripheral, didUpdateValueFor characteristic: SonarBTCharacteristic, error: Error?) {
        peripheral.readRSSI()
        livenessDelegate?.keepAlive()
    }
    
    func peripheral(_ peripheral: SonarBTPeripheral, didDiscoverCharacteristicsFor service: SonarBTService, error: Error?) {
        
    }
    
    func peripheralDidUpdateName(_ peripheral: SonarBTPeripheral) {
        
    }
}

class SequenceBuilder {
    private let broadcaster: BTBroadcaster
    private let peripheralManager: FakeBTPeripheralManager
    private let scanner: BTScanner
    private let centralManager: FakeBTCentralManager
    private let contactEventsStorage: ContactEventsStorage
    
    class var aSequence: SequenceBuilder {
        let peripheralManager = FakeBTPeripheralManager()
        let broadcaster = BTBroadcaster(peripheralManager: peripheralManager)
        
        let reader = BTReader()
        
        let centralManager = FakeBTCentralManager(fakePeripheralManager: peripheralManager)
        let scanner = BTScanner(centralManager: centralManager, peripheralDelegate: reader)
        
        let contactEventPersister = PlistPersister<UUID, ContactEvent>(fileName: "contactEvents")
        let contactEventRepository = PersistingContactEventRepository(persister: contactEventPersister)
        contactEventRepository.reset()
        let contactEventsStorage = ContactEventsStorage(contactEventsRepository: contactEventRepository)
        
        reader.delegate = contactEventsStorage
        reader.livenessDelegate = broadcaster

        scanner.delegate = contactEventsStorage
        scanner.livenessDelegate = broadcaster
        
        let coordinator = BluetoothCoordinator(broadcaster: broadcaster, scanner: scanner, readerDelegate: contactEventsStorage)
        
        return SequenceBuilder(broadcaster: broadcaster, peripheralManager: peripheralManager, scanner: scanner, centralManager: centralManager, contactEventsStorage: contactEventsStorage)
    }
    
    init(broadcaster: BTBroadcaster, peripheralManager: FakeBTPeripheralManager, scanner: BTScanner, centralManager: FakeBTCentralManager, contactEventsStorage: ContactEventsStorage) {
        self.broadcaster = broadcaster
        self.peripheralManager = peripheralManager
        self.scanner = scanner
        self.centralManager = centralManager
        self.contactEventsStorage = contactEventsStorage
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
    
    func verify(_ verificationClosure: (_ contactEventsStorage: ContactEventsStorage) -> Void) {
        scanner.centralManagerDidUpdateState(centralManager)
        broadcaster.peripheralManagerDidUpdateState(peripheralManager)

        verificationClosure(contactEventsStorage)
    }
}
