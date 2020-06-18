import Foundation

import XCTest
import Logging

@testable import Sonar

class BluetoothTests: TestCase {
    override func setUp() {
        continueAfterFailure = false
    }
    
    func test_happyPath() throws {
        let peripheral1 = "C67B5205-BAD0-4D05-AA38-1A7C4E3231CA"
        let peripheral2 = "C3575FCB-CDE3-42CC-9A50-1BC492E2C9EE"
        SequenceBuilder
            .aSequence
            .powerOn()
            .discoversPeripheral(peripheral1, withTxPower: -77)
            .discoversPeripheral(peripheral2, withTxPower: -66)
            .readsCryptogramPayload(samplePayload1, fromPeripheral: peripheral1)
            .readsCryptogramPayload(samplePayload2, fromPeripheral: peripheral2)
            .readsRSSIValues(-47, -56, -45, -34, fromPeripheral: peripheral1)
            .readsRSSIValues(-34, -23, -12, -22, fromPeripheral: peripheral2)
            .verify { contactEventStorage in
                Thread.sleep(forTimeInterval: 3.0)
                XCTAssertEqual(contactEventStorage.contactEvents.count, 2)
                
                let peripheral1ContactEvent = contactEventStorage.contactEvents.first { contactEvent in contactEvent.broadcastPayload == IncomingBroadcastPayload(data: samplePayload1) }
                
                let peripheral2ContactEvent = contactEventStorage.contactEvents.first { contactEvent in contactEvent.broadcastPayload == IncomingBroadcastPayload(data: samplePayload2) }
                
                XCTAssertNotNil(peripheral1ContactEvent)
                XCTAssertNotNil(peripheral2ContactEvent)
                
                XCTAssertEqual(peripheral1ContactEvent?.txPower, -77)
                XCTAssertEqual(peripheral2ContactEvent?.txPower, -66)
                
                XCTAssertEqual(peripheral1ContactEvent?.rssiValues.prefix(4), [-47, -56, -45, -34])
                XCTAssertEqual(peripheral2ContactEvent?.rssiValues.prefix(4), [-34, -23, -12, -22])
        }
    }
    
    var samplePayload1: Data {
        var data = Data(count: BroadcastPayload.length)
        data.replaceSubrange(0..<2, with: UInt16(1).networkByteOrderData)
        data.replaceSubrange(2..<4, with: UInt16(1).networkByteOrderData)
        return data
    }
    
    var samplePayload2: Data {
        var data = Data(count: BroadcastPayload.length)
        data.replaceSubrange(0..<2, with: UInt16(2).networkByteOrderData)
        data.replaceSubrange(2..<4, with: UInt16(2).networkByteOrderData)
        return data
    }
    
    var samplePayload3: Data {
        var data = Data(count: BroadcastPayload.length)
        data.replaceSubrange(0..<2, with: UInt16(3).networkByteOrderData)
        data.replaceSubrange(2..<4, with: UInt16(3).networkByteOrderData)
        return data
    }
}

extension Logger {
    func trace(_ peripheral: SonarBTPeripheral, _ message: String) {
        self.trace("[\(peripheral.identifierWithName)] \(message)")
    }
}

protocol SonarBTReaderDelegate: class {
    func reader(_ reader: BTReader, didFind broadcastPayload: IncomingBroadcastPayload, for peripheral: Peripheral)
    func reader(_ reader: BTReader, didReadRSSI RSSI: Int, for peripheral: Peripheral)
    func reader(_ reader: BTReader, didReadTxPower txPower: Int, for peripheral: Peripheral)
}

protocol SonarBTScannerDelegate: class {
    func scanner(_ scanner: BTScanner, didReadRSSI RSSI: Int, for peripheral: Peripheral)
    func scanner(_ scanner: BTScanner, didReadTxPower txPower: Int, for peripheral: Peripheral)
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
    
    func scanner(_ scanner: BTScanner, didReadRSSI RSSI: Int, for peripheral: Peripheral) {
        contactEventsRepository.listener(FakeListener(), didReadRSSI: RSSI, for: peripheral)
    }
    
    func scanner(_ scanner: BTScanner, didReadTxPower txPower: Int, for peripheral: Peripheral) {
        contactEventsRepository.listener(FakeListener(), didReadTxPower: txPower, for: peripheral)
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
        
        _ = peripheralManager.updateValue(value, for: self.keepaliveCharacteristic, onSubscribedCentrals: nil)
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
        logger.logLevel = .trace
        #endif
        return logger
    }()
}

extension BTScanner: SonarBTCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: SonarBTCentralManager) {
        logger.trace("centralManagerDidUpdateState")
        
        startScanning()
    }
    
    func centralManager(_ central: SonarBTCentralManager, willRestoreState dict: [String: Any]) {
    }
    
    func centralManager(_ central: SonarBTCentralManager, didConnect peripheral: SonarBTPeripheral) {
        logger.trace(peripheral, "didConnect")
        
        peripheral.delegate = peripheralDelegate
        peripheral.discoverServices([Environment.sonarServiceUUID])
    }
    
    func centralManager(_ central: SonarBTCentralManager, didFailToConnect peripheral: SonarBTPeripheral, error: Error?) {
    }
    
    func centralManager(_ central: SonarBTCentralManager, didDisconnectPeripheral peripheral: SonarBTPeripheral, error: Error?) {
    }
    
    func centralManager(_ central: SonarBTCentralManager, didDiscover peripheral: SonarBTPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let txPower = (advertisementData[SonarBTAdvertisementDataTxPowerLevelKey] as? NSNumber)?.intValue {
            logger.trace(peripheral, "didDiscover with txPower \(txPower)")

            delegate?.scanner(self, didReadTxPower: txPower, for: peripheral)
        } else {
            logger.trace(peripheral, "didDiscover")
        }
        
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
        logger.logLevel = .trace
        #endif
        return logger
    }()
}

extension BTReader: SonarBTPeripheralDelegate {
    func peripheral(_ peripheral: SonarBTPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        logger.trace(peripheral, "didDiscoverServices \(services.map { service in service.name })")
        
        guard let sonarIdService = services.sonarIdService() else { return }
        logger.trace(peripheral, "didDiscoverServices \(sonarIdService.name)")
        
        peripheral.discoverCharacteristics([
            Environment.sonarIdCharacteristicUUID,
            Environment.keepaliveCharacteristicUUID
        ], for: sonarIdService)
    }
    
    func peripheral(_ peripheral: SonarBTPeripheral, didModifyServices invalidatedServices: [SonarBTService]) {
        
    }
    
    func peripheral(_ peripheral: SonarBTPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        logger.trace(peripheral, "didReadRSSI \(RSSI)")
        
        delegate?.reader(self, didReadRSSI: RSSI.intValue, for: peripheral)
    }
    
    func peripheral(_ peripheral: SonarBTPeripheral, didUpdateNotificationStateFor characteristic: SonarBTCharacteristic, error: Error?) {
        logger.trace(peripheral, "didUpdateNotificationStateFor for characteristic \(characteristic.name)")
    }
    
    func peripheral(_ peripheral: SonarBTPeripheral, didUpdateValueFor characteristic: SonarBTCharacteristic, error: Error?) {
        if characteristic.isSonarKeepalive, let keepaliveValue = characteristic.value?.withUnsafeBytes({ $0.load(as: UInt8.self) }) {
            logger.trace(peripheral, "didUpdateValueFor characteristic \(characteristic.name): \(keepaliveValue)")
            
            peripheral.readRSSI()
            livenessDelegate?.keepAlive()
        } else if characteristic.isSonarID, let data = characteristic.value, data.count == BroadcastPayload.length {
            logger.trace(peripheral, "didUpdateValueFor characteristic \(characteristic.name): \(PrintableBroadcastPayload(data))")
            delegate?.reader(self, didFind: IncomingBroadcastPayload(data: data), for: peripheral)
        }
    }
    
    func peripheral(_ peripheral: SonarBTPeripheral, didDiscoverCharacteristicsFor service: SonarBTService, error: Error?) {
        logger.trace(peripheral, "didDiscoverCharacteristicsFor for service \(service.name)")
        
        guard let sonarCharacteristics = service.sonarCharacteristics, sonarCharacteristics.count == 2 else { return }
        
        peripheral.readValue(for: sonarCharacteristics.sonarIdCharacteristic()!)
        
        for sonarCharacteristic in sonarCharacteristics {
            peripheral.setNotifyValue(true, for: sonarCharacteristic)
        }
    }
    
    func peripheralDidUpdateName(_ peripheral: SonarBTPeripheral) {
        
    }
}

class SequenceBuilder {
    private let broadcaster: BTBroadcaster
    private let scanner: BTScanner
    private let contactEventsStorage: ContactEventsStorage
    
    private let fakePeripheralManager: FakeBTPeripheralManager
    private let fakeCentralManager: FakeBTCentralManager
    
    class var aSequence: SequenceBuilder {
        let fakePeripheralManager = FakeBTPeripheralManager()
        let broadcaster = BTBroadcaster(peripheralManager: fakePeripheralManager)
        
        let reader = BTReader()
        
        let fakeCentralManager = FakeBTCentralManager(fakePeripheralManager: fakePeripheralManager)
        let scanner = BTScanner(centralManager: fakeCentralManager, peripheralDelegate: reader)
        
        let contactEventPersister = PlistPersister<UUID, ContactEvent>(fileName: "contactEvents")
        let contactEventRepository = PersistingContactEventRepository(persister: contactEventPersister)
        contactEventRepository.reset()
        let contactEventsStorage = ContactEventsStorage(contactEventsRepository: contactEventRepository)
        
        reader.delegate = contactEventsStorage
        reader.livenessDelegate = broadcaster
        
        scanner.delegate = contactEventsStorage
        scanner.livenessDelegate = broadcaster
        
        _ = BluetoothCoordinator(broadcaster: broadcaster, scanner: scanner, readerDelegate: contactEventsStorage)
        
        return SequenceBuilder(
            broadcaster: broadcaster,
            peripheralManager: fakePeripheralManager,
            scanner: scanner,
            centralManager: fakeCentralManager,
            contactEventsStorage: contactEventsStorage
        )
    }
    
    private init(
        broadcaster: BTBroadcaster,
        peripheralManager: FakeBTPeripheralManager,
        scanner: BTScanner,
        centralManager: FakeBTCentralManager,
        contactEventsStorage: ContactEventsStorage
    ) {
        self.broadcaster = broadcaster
        self.fakePeripheralManager = peripheralManager
        self.scanner = scanner
        self.fakeCentralManager = centralManager
        self.contactEventsStorage = contactEventsStorage
    }
    
    func powerOn() -> SequenceBuilder {
        fakeCentralManager.setState(.poweredOn)
        fakePeripheralManager.setState(.poweredOn)
        return self
    }
    
    func discoversPeripheral(_ peripheralId: String, withTxPower txPower: Int) -> SequenceBuilder {
        fakeCentralManager.willDiscoverPeripheral(SonarBTUUID(string: peripheralId), withTxPower: txPower)
        return self
    }
    
    func readsRSSIValues(_ rssiValues: Int..., fromPeripheral peripheralId: String) -> SequenceBuilder {
        fakeCentralManager.willReadRSSIs(rssiValues, fromPeripheral: SonarBTUUID(string: peripheralId))
        return self
    }
    
    func readsCryptogramPayload(_ payload: Data, fromPeripheral peripheralId: String) -> SequenceBuilder {
        fakeCentralManager.willReadCryptogramPayload(payload, fromPeripheral: SonarBTUUID(string: peripheralId))
        return self
    }
    
    func verify(_ verificationClosure: (_ contactEventsStorage: ContactEventsStorage) -> Void) {
        scanner.centralManagerDidUpdateState(fakeCentralManager)
        broadcaster.peripheralManagerDidUpdateState(fakePeripheralManager)
        
        verificationClosure(contactEventsStorage)
    }
}
