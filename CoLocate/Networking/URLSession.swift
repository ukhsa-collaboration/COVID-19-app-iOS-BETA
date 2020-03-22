//
//  URLSession.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import Foundation
import CryptoKit

extension URLSession: Session {
    
    static let tolerance:Double = 60.0 // seconds tolerance on timestamp

    static var formatter: ISO8601DateFormatter {
        get {
            let GMT = TimeZone(abbreviation: "GMT")!
            let timestampFormatOptions: ISO8601DateFormatter.Options = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime, .withTimeZone]
            let fmt = ISO8601DateFormatter()
            fmt.formatOptions = timestampFormatOptions
            fmt.timeZone = GMT
            return fmt
        }
    }
    
    var symmetricKey: Data {
        get {
            // TODO replace this with wherever the key is kept post registration on the phone
            return "ABCD".data(using: .utf8)!
        }
    }

    var baseURL: URL {
        let endpoint = Bundle(for: AppDelegate.self).infoDictionary?["API_ENDPOINT"] as! String
        return URL(string: endpoint)!
    }
    
    func createRequest<R: Request>(_ request: R) -> URLRequest {
        let url = URL(string: request.path, relativeTo: baseURL)!
        var urlRequest = URLRequest(url: url)
        
        urlRequest.allHTTPHeaderFields = request.headers
        
        var calculatedHeaders: [String:String]?
        print("\(#file).\(#function) Does request need signing? : \(request.signed)")
        if (request.signed) {
            calculatedHeaders = signRequest(request) // may mutate
            print("\(#file).\(#function) " + String(describing: calculatedHeaders))
        }
        if let calc = calculatedHeaders {
            urlRequest.allHTTPHeaderFields!.merge(calc) { (_, new) in new }
        }
        
        switch request.method {
        case .get:
            urlRequest.httpMethod = "GET"
            
        case .post(let data):
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = data
            
        case .patch(let data):
            urlRequest.httpMethod = "PATCH"
            urlRequest.httpBody = data
        }
        
        return urlRequest
    }
    
    // Returns Base 64 encoded string
    func hmacSha256(dateTimeString: String, body: Data?) -> String {
        if #available(iOS 13.0, *) {
            // Supporting built ins where available for security and performance
            
            var hmac = HMAC<SHA256>(key: SymmetricKey(data: symmetricKey));
            hmac.update(data: dateTimeString.data(using: .utf8)!)
            if let theBody = body {
                hmac.update(data: theBody) // optional (not available for authenticated get requests)
            }
            let hmacCode = hmac.finalize()
            let base64String = hmacCode.map { String(format: "%02hhx", $0) }.joined() // lower x forces lowercase

            //let decData = NSData(bytes: encryptedData, length: Int(encryptedData.count))
            //let base64String = decData.base64EncodedString(options: .lineLength64Characters)
            //print("base64String: \(base64String)")
            return base64String
                
        } else {
            // Fallback on earlier versions
            // TODO which library to use??? OpenSSL (large overhead), other? (swap out attack?)
            return ""
        }
    }
    
    private func signRequest<R: Request>(_ request : R) -> [String: String] {
        let dateTime = Date()

        let dateTimeString = URLSession.formatter.string(from: dateTime)
        
        let hmac = hmacSha256(dateTimeString: dateTimeString,body: request.data)
        
        let calculatedHeaders: [String:String] = [
            SonarHeaders.Signature: hmac,
            SonarHeaders.Timestamp: dateTimeString
        ]
        return calculatedHeaders
    }
    
    // throws if invalid
    func checkResponseSignature(data: Data?, response: HTTPURLResponse, now: TimeInterval) throws {
        let headers = response.allHeaderFields
        if let signature = headers[SonarHeaders.Signature] as? String {
            if let timestamp = headers[SonarHeaders.Timestamp] as? String {
                let seconds = URLSession.formatter.date(from: timestamp)!.timeIntervalSince1970
                if now < seconds + URLSession.tolerance {
                    // ok
                } else {
                    throw RequestErrors.timestampTooOld
                }
                let hmac = hmacSha256(dateTimeString: timestamp, body: data)
                if signature == hmac {
                    // valid! do nothing
                } else {
                    throw RequestErrors.invalidSignature
                }
            } else {
                throw RequestErrors.missingTimestamp
            }
        } else {
            throw RequestErrors.missingSignature
        }
        return
    }
    
    // placeholder in case we need to further encode/encrypt comms later
    private func unpackData(_ data: Data, response: HTTPURLResponse) -> Data {
        return data
    }
    
    func execute<R: Request>(_ request: R, completion: @escaping (Result<R.ResponseType, Error>) -> Void) {
        
        print("URLSESSION:EXECUTE()")
        
        // TODO: Protect our request with a client cert (same for all app instances)
        // TODO: Validate our endpoint certificate identity too
        
        
        let urlRequest = createRequest(request)
        
        let task = dataTask(with: urlRequest) { data, response, error in
            let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            do {
                switch (data, statusCode, error) {
                case (let data?, let statusCode, _) where 200..<300 ~= statusCode:
                    
                    if request.signed {
                        // TODO if response ends up being encrypted, be sure that unpack and check sig are in the correct order

                        let now = Date().timeIntervalSince1970
                        try self.checkResponseSignature(data: data, response: httpResponse, now: now)
                    }
                    
                    let parsed = try request.parse(self.unpackData(data,response: httpResponse))
                    completion(.success(parsed))

                case (_, let statusCode, _):
                    throw NSError(domain: "RequestErrorDomain", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Received \(statusCode) status code from server"])

                case (_, _, let error?):
                    throw error

                default:
                    break
                }
            } catch (let error) {
                completion(.failure(error))
            }
        }

        task.resume()
    }

}
