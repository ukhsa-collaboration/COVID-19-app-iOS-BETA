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
    public var listener: BTLEListener!

    func setState(_ desiredState: SonarBTManagerState) {
        stubState = desiredState
    }

    init() {
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
