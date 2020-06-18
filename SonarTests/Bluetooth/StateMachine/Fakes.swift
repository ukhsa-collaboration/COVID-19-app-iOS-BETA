//
//  Fakes.swift
//  SonarTests
//
//  Created by NHSX on 17/6/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

@testable import Sonar

class DelayedExecutor {
    private let executionQueue = DispatchQueue(label: "Execution Queue \(UUID())")
    private var timers: [DispatchSourceTimer] = []

    func executeWithin(interval: TimeInterval, _ handler: @escaping () -> Void) {
        let timer = DispatchSource.makeTimerSource(queue: executionQueue)
        timers.append(timer)
        timer.setEventHandler { [unowned self] in
            handler()
            self.timers.removeAll { t in t.hash == timer.hash }
        }
        timer.schedule(deadline: .now() + interval)
        timer.resume()
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
    
    private var _value: Data?
    override var value: Data? {
        get { _value }
        set { _value = newValue }
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
    
    private var _characteristics: [SonarBTCharacteristic]? = nil
    override var characteristics: [SonarBTCharacteristic]? {
        get { _characteristics }
        set { _characteristics = newValue }
    }
    
    override var uuid: SonarBTUUID {
        return id
    }
}

class FakeBTPeripheral: SonarBTPeripheral {
    private let id: UUID
    private let name: String?
    private var readRSSICallCount = 0
    private let delayedExecutor: DelayedExecutor = DelayedExecutor()

    var rssiWillReadValues: [Int] = [-56]
    var sonarIdWillReadPayload: Data! = nil
    
    var keepaliveNotificationIsOn = false
    var sonarIdNotificationIsOn = false
    
    init(id: SonarBTUUID, delegate: SonarBTPeripheralDelegate?) {
        self.id = UUID(uuidString: id.uuidString)!
        self.name = "Fake Peripheral"
        super.init(delegate: delegate)
    }
    
    private var _services: [SonarBTService]? = nil
    override var services: [SonarBTService]? {
        get { _services }
        set { _services = newValue }
    }
    
    override var identifier: UUID {
        return self.id
    }
    
    override var identifierWithName: String {
        return "\(id) (\(name ?? "unknown"))"
    }
    
    override func readRSSI() {
        delegate?.peripheral(self, didReadRSSI: NSNumber(value: rssiWillReadValues[readRSSICallCount]), error: nil)
        if (readRSSICallCount < rssiWillReadValues.count - 1) {
            readRSSICallCount += 1
        }
    }
    
    override func discoverServices(_ serviceUUIDs: [SonarBTUUID]?) {
        services = [FakeBTService()]
        delayedExecutor.executeWithin(interval: 0.2) { [unowned self] in
            self.delegate?.peripheral(self, didDiscoverServices: nil)
        }
    }
    
    override func discoverCharacteristics(_ characteristicUUIDs: [SonarBTUUID]?, for service: SonarBTService) {
        services!.forEach { service in
            service.characteristics = [FakeBTCharacteristic.sonarIdCharacteristic, FakeBTCharacteristic.keepaliveCharacteristic] }
        delayedExecutor.executeWithin(interval: 0.2) { [unowned self] in
            self.delegate?.peripheral(self, didDiscoverCharacteristicsFor: self.services!.first!, error: nil)
        }
    }
    
    override func readValue(for characteristic: SonarBTCharacteristic) {
        let fakeCharacteristic = characteristic as! FakeBTCharacteristic
        delayedExecutor.executeWithin(interval: 0.2) { [unowned self] in
            if (fakeCharacteristic.isSonarID) {
                fakeCharacteristic.value = self.sonarIdWillReadPayload
                self.delegate?.peripheral(self, didUpdateValueFor: fakeCharacteristic, error: nil)
            } else if (fakeCharacteristic.isSonarKeepalive) {
                fakeCharacteristic.value = randomKeepalive()
                self.delegate?.peripheral(self, didUpdateValueFor: fakeCharacteristic, error: nil)
            } else {
                self.delegate?.peripheral(self, didUpdateValueFor: fakeCharacteristic, error: nil)
            }
        }
    }
    
    override func setNotifyValue(_ enabled: Bool, for characteristic: SonarBTCharacteristic) {
        keepaliveNotificationIsOn = characteristic.isSonarKeepalive
        sonarIdNotificationIsOn = characteristic.isSonarID
        
        delayedExecutor.executeWithin(interval: 0.2) { [unowned self] in
            self.delegate?.peripheral(self, didUpdateNotificationStateFor: characteristic, error: nil)
        }
    }
    
    private var _state: SonarBTPeripheralState = .connecting
    override var state: SonarBTPeripheralState {
        get { _state }
        set { _state = newValue }
    }
}

class FakeBTPeripheralManager: SonarBTPeripheralManager {
    private var stubState: SonarBTManagerState = .unknown
    private var connectedPeripherals: [FakeBTPeripheral] = []
    private let delayedExecutor: DelayedExecutor = DelayedExecutor()
    
    init() {
        super.init(delegate: nil, queue: nil, options: nil)
    }
    
    func setState(_ desiredState: SonarBTManagerState) {
        stubState = desiredState
    }
    
    func addToConnectedPeripherals(_ peripheral: FakeBTPeripheral) {
        connectedPeripherals.append(peripheral)
    }
    
    override var state: SonarBTManagerState {
        return stubState
    }
    
    override func updateValue(_ value: Data, for characteristic: SonarBTCharacteristic, onSubscribedCentrals centrals: [SonarBTCentral]?) -> Bool {
        if characteristic.isSonarKeepalive {
            simulateReceivingKeepaliveFromOtherDevice()
        }
        
        return true
    }
    
    private func simulateReceivingKeepaliveFromOtherDevice() {
        let fakeCharacteristic = FakeBTCharacteristic.keepaliveCharacteristic
        
        delayedExecutor.executeWithin(interval: 0.2) { [unowned self] in
            self.connectedPeripherals
                .filter { peripheral in peripheral.keepaliveNotificationIsOn }
                .forEach { peripheral in
                    fakeCharacteristic.value = randomKeepalive()
                    peripheral.delegate?.peripheral(peripheral, didUpdateValueFor: fakeCharacteristic, error: nil)
            }
        }
    }
}

class FakeBTCentralManager: SonarBTCentralManager {
    struct Connection {
        var txPower: Int = 0
        var rssiValues: [Int] = []
        var payload: Data! = nil
    }
    
    private let fakePeripheralManager: FakeBTPeripheralManager
    
    private var stubState: SonarBTManagerState = .unknown
    private var stubConnections: [SonarBTUUID: Connection] = [:]
    private let delayedExecutor: DelayedExecutor = DelayedExecutor()

    func setState(_ desiredState: SonarBTManagerState) {
        stubState = desiredState
    }
    
    init(fakePeripheralManager: FakeBTPeripheralManager) {
        self.fakePeripheralManager = fakePeripheralManager
        super.init(delegate: nil, peripheralDelegate: nil, queue: nil, options: nil)
    }
    
    override var state: SonarBTManagerState {
        return stubState
    }
    
    func willDiscoverPeripheral(_ peripheralId: SonarBTUUID, withTxPower txPower: Int) {
        if let _ = stubConnections[peripheralId] {
            stubConnections[peripheralId]!.txPower = txPower
        } else {
            stubConnections[peripheralId] = Connection(txPower: txPower, rssiValues: [], payload: nil)
        }
    }
    
    func willReadRSSIs(_ rssiValues: [Int], fromPeripheral peripheralId: SonarBTUUID) {
        if let _ = stubConnections[peripheralId] {
            stubConnections[peripheralId]!.rssiValues = rssiValues
        } else {
            stubConnections[peripheralId] = Connection(txPower: 0, rssiValues: rssiValues, payload: nil)
        }
    }
    
    func willReadCryptogramPayload(_ payload: Data, fromPeripheral peripheralId: SonarBTUUID) {
        if let _ = stubConnections[peripheralId] {
            stubConnections[peripheralId]!.payload = payload
        } else {
            stubConnections[peripheralId] = Connection(txPower: 0, rssiValues: [], payload: payload)
        }
    }
    
    override func scanForPeripherals(withServices serviceUUIDs: [SonarBTUUID]?, options: [String : Any]? = nil) {
        for (peripheralId, connection) in stubConnections {
            let firstRSSIReading = connection.rssiValues.first ?? -47
            let nextRSSIReadings: [Int] = Array(connection.rssiValues[1..<connection.rssiValues.count])
            let peripheral = FakeBTPeripheral(id: peripheralId, delegate: peripheralDelegate)
            peripheral.rssiWillReadValues = nextRSSIReadings
            peripheral.sonarIdWillReadPayload = connection.payload
            
            fakePeripheralManager.addToConnectedPeripherals(peripheral)
            delayedExecutor.executeWithin(interval: 0.2) { [unowned self] in
                self.delegate?.centralManager(
                    self,
                    didDiscover: peripheral,
                    advertisementData: [
                        SonarBTAdvertisementDataTxPowerLevelKey: NSNumber(integerLiteral: connection.txPower)
                    ],
                    rssi: NSNumber(value: firstRSSIReading)
                )
            }
        }
    }
    
    override func connect(_ peripheral: SonarBTPeripheral, options: [String : Any]? = nil) {
        delayedExecutor.executeWithin(interval: 0.2) { [unowned self] in
            self.delegate?.centralManager(self, didConnect: peripheral)
        }
    }
    
}

fileprivate func randomKeepalive() -> Data {
    var keepaliveValue = UInt8.random(in: .min ... .max)
    return Data(bytes: &keepaliveValue, count: MemoryLayout.size(ofValue: keepaliveValue))
}
