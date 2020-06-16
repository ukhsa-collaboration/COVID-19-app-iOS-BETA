//
//  SonarBTPeripheralManager.swift
//  Sonar
//
//  Created by NHSX on 16/6/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CoreBluetooth

class SonarBTCentral {
    fileprivate let cbCentral: CBCentral
    
    init(_ central: CBCentral) {
        self.cbCentral = central
    }

}


typealias SonarBTATTError = CBATTError
class SonarBTATTRequest {
    fileprivate let cbATTRequest: CBATTRequest
    
    init(_ request: CBATTRequest) {
        self.cbATTRequest = request
    }
    
    var characteristic: SonarBTCharacteristic {
        get {
            return SonarBTCharacteristic(cbATTRequest.characteristic)
        }
    }
    
    var value: Data? {
        get {
            return cbATTRequest.value
        }
        
        set {
            cbATTRequest.value = newValue
        }
    }
}

class SonarBTService {
    fileprivate let cbService: CBService
    public var characteristics: [SonarBTCharacteristic]?
    
    init(_ service: CBService) {
        self.cbService = service
    }
    
    init(type UUID: SonarBTUUID, primary isPrimary: Bool) {
        self.cbService = CBMutableService(type: UUID, primary: isPrimary)
    }
    
    var uuid: SonarBTUUID {
        get {
            return cbService.uuid
        }
    }
}


class SonarBTCharacteristic {
    fileprivate let cbCharacteristic: CBCharacteristic
    
    init(_ characteristic: CBCharacteristic) {
        self.cbCharacteristic = characteristic
    }
    
    init(type UUID: SonarBTUUID, properties: SonarBTCharacteristicProperties, value: Data?, permissions: SonarBTAttributePermissions) {
        self.cbCharacteristic = CBMutableCharacteristic(
            type: UUID,
            properties: properties,
            value: nil,
            permissions: permissions)
    }
    
    var uuid: SonarBTUUID {
        get {
            cbCharacteristic.uuid
        }
    }
}


protocol SonarBTPeripheralManagerDelegate: class {
    func peripheralManagerDidUpdateState(_ peripheral: SonarBTPeripheralManager)
    func peripheralManager(_ peripheral: SonarBTPeripheralManager, willRestoreState dict: [String : Any])
    func peripheralManager(_ peripheral: SonarBTPeripheralManager, didAdd service: SonarBTService, error: Error?)
    func peripheralManagerDidStartAdvertising(_ peripheral: SonarBTPeripheralManager, error: Error?)
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: SonarBTPeripheralManager)
    func peripheralManager(_ peripheral: SonarBTPeripheralManager, central: SonarBTCentral, didSubscribeTo characteristic: SonarBTCharacteristic)
    func peripheralManager(_ peripheral: SonarBTPeripheralManager, central: SonarBTCentral, didUnsubscribeFrom characteristic: SonarBTCharacteristic)
    func peripheralManager(_ peripheral: SonarBTPeripheralManager, didReceiveRead request: SonarBTATTRequest)
}


public let SonarBTPeripheralManagerOptionShowPowerAlertKey: String = CBPeripheralManagerOptionShowPowerAlertKey
public let SonarBTPeripheralManagerOptionRestoreIdentifierKey: String = CBPeripheralManagerOptionRestoreIdentifierKey
public let SonarBTPeripheralManagerRestoredStateServicesKey: String = CBPeripheralManagerRestoredStateServicesKey
public let SonarBTPeripheralManagerRestoredStateAdvertisementDataKey: String = CBPeripheralManagerRestoredStateAdvertisementDataKey

class SonarBTPeripheralManager: NSObject {
    weak var delegate: SonarBTPeripheralManagerDelegate?
    private let cbPeripheralManager: CBPeripheralManager
    
    init(delegate: SonarBTPeripheralManagerDelegate?, queue: DispatchQueue?, options: [String : Any]? = nil) {
        self.delegate = delegate
        self.cbPeripheralManager = CBPeripheralManager(delegate: nil, queue: queue, options: options)
        super.init()
        cbPeripheralManager.delegate = self
    }
    
    var isAdvertising: Bool {
        get {
            return cbPeripheralManager.isAdvertising
        }
    }
    
    var state: SonarBTManagerState {
        get {
            return cbPeripheralManager.state
        }
    }
    
    func add(_ service: SonarBTService) {
        cbPeripheralManager.add(service.cbService as! CBMutableService)
    }
    
    func startAdvertising(_ advertisementData: [String : Any]?) {
        cbPeripheralManager.startAdvertising(advertisementData)
    }
    
    func updateValue(_ value: Data, for characteristic: SonarBTCharacteristic, onSubscribedCentrals centrals: [SonarBTCentral]?) -> Bool {
        return cbPeripheralManager.updateValue(value, for: characteristic.cbCharacteristic as! CBMutableCharacteristic, onSubscribedCentrals: centrals?.map { sonarCentral in sonarCentral.cbCentral })
    }
    
    func respond(to request: SonarBTATTRequest, withResult result: SonarBTATTError.Code) {
        cbPeripheralManager.respond(to: request.cbATTRequest, withResult: result)
    }
}

extension SonarBTPeripheralManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        delegate?.peripheralManagerDidUpdateState(self)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        delegate?.peripheralManager(self, willRestoreState: dict)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        delegate?.peripheralManager(self, didAdd: SonarBTService(service), error: error)
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        delegate?.peripheralManagerDidStartAdvertising(self, error: error)
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        delegate?.peripheralManagerIsReady(toUpdateSubscribers: self)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        delegate?.peripheralManager(self, central: SonarBTCentral(central), didSubscribeTo: SonarBTCharacteristic(characteristic))
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        delegate?.peripheralManager(self, central: SonarBTCentral(central), didUnsubscribeFrom: SonarBTCharacteristic(characteristic))
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        delegate?.peripheralManager(self, didReceiveRead: SonarBTATTRequest(request))
    }
}
