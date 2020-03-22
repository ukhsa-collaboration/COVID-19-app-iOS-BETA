//
//  PatchContactEventsRequest.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation

struct PatchContactEventsRequest: Request {
    var signed: Bool {
        return true
    }
    
    typealias ResponseType = Void
    
    var method: HTTPMethod {
        return .patch(data: data)
    }
    
    let path: String
    
    let data: Data
    
    var headers: [String : String]?
    
    init(deviceId: UUID, contactEvents: [ContactEvent]) {
        print("INIT")
        path = "/api/residents/\(deviceId.uuidString)"
        data = try! JSONEncoder().encode(contactEvents)
        headers = [
               "Accept": "application/json",
               "Content-Type": "application/json"
           ]
    }
    
    func parse(_ data: Data) throws -> Void {
    }
        
}
