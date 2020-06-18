//
//  Fakes.swift
//  SonarTests
//
//  Created by NHSX on 17/6/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

@testable import Sonar

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
    
    override var value: Data? {
        if Environment.sonarIdCharacteristicUUID == uuid {
            return Data(count: BroadcastPayload.length)
        } else {
            var keepaliveValue = UInt8.random(in: .min ... .max)
            return Data(bytes: &keepaliveValue, count: MemoryLayout.size(ofValue: keepaliveValue))
        }
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
    private var rssiWillReadValues: [Int] = [-56]
    private var readRSSICallCount = 0
    
    init(delegate: SonarBTPeripheralDelegate?, rssiWillReadValues: [Int]?) {
        self.id = UUID()
        self.name = "Fake Peripheral"
        if let values = rssiWillReadValues {
            self.rssiWillReadValues = values
        }
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
        delegate?.peripheral(self, didReadRSSI: NSNumber(value: rssiWillReadValues[readRSSICallCount]), error: nil)
        readRSSICallCount += 1
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
    
    private var _stateValue: SonarBTPeripheralState = .connecting
    override var state: SonarBTPeripheralState {
        get {
            return _stateValue
        }
        set {
            _stateValue = newValue
        }
    }
}

class FakeBTPeripheralManager: SonarBTPeripheralManager {
    private var stubState: SonarBTManagerState = .unknown
    private var connectedPeripherals: [FakeBTPeripheral] = []

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
        var fakeCharacteristic = FakeBTCharacteristic.keepaliveCharacteristic
        if characteristic.uuid == Environment.sonarIdCharacteristicUUID {
            fakeCharacteristic = FakeBTCharacteristic.sonarIdCharacteristic
        }
        connectedPeripherals.forEach { peripheral in
            peripheral.delegate?.peripheral(peripheral, didUpdateValueFor: fakeCharacteristic, error: nil)
        }
        return true
    }
}

class FakeBTCentralManager: SonarBTCentralManager {
    private let fakePeripheralManager: FakeBTPeripheralManager
    private var stubState: SonarBTManagerState = .unknown
    public var listener: BTLEListener!
    private var connectedPeripheralsRSSIReadings: [Int]?

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

    func connectedPeripheralsWillSendRSSIs(_ rssiValues: [Int]) {
        connectedPeripheralsRSSIReadings = rssiValues
    }
    
    override func scanForPeripherals(withServices serviceUUIDs: [SonarBTUUID]?, options: [String : Any]? = nil) {
        let peripheral = FakeBTPeripheral(delegate: listener, rssiWillReadValues: connectedPeripheralsRSSIReadings)
        fakePeripheralManager.addToConnectedPeripherals(peripheral)
        listener.centralManager(
            self,
            didDiscover: peripheral,
            advertisementData: [:],
            rssi: NSNumber(-47)
        )
    }

    override func connect(_ peripheral: SonarBTPeripheral, options: [String : Any]? = nil) {
        listener.centralManager(self, didConnect: peripheral)
    }

}
