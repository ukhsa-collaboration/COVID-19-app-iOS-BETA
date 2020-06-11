//
//  ApnsAttemptable.swift
//  RegistrationCanary
//
//  Created by NHSX on 6/10/20
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit
import Logging

let RemoteNotificationReceivedNotification = NSNotification.Name("RemoteNotificationReceivedNotification")
private let timeoutSecs = 5 * 60.0

class ApnsAttemptable: Attemptable {
    var delegate: AttemptableDelegate?
    var state: AttemptableState = .initial
    var numAttempts = 0
    var numSuccesses = 0
    
    private var apnsToken: String?
    private let timer = BackgroundableTimer(
        notificationCenter: NotificationCenter.default,
        queue: DispatchQueue.main
    )
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(remoteNotificationReceived(_:)),
            name: RemoteNotificationReceivedNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(apnsTokenReceived(_:)),
            name: ApnsTokenReceivedNotification, object: nil
        )
    }
    
    func attempt() {
        let prevNumSuccesses = numSuccesses
        state = .inProgress(deadline: Date().advanced(by: timeoutSecs))
        delegate?.attemptableDidChange(self)
        makeRequest()
        
        timer.schedule(deadline: .now() + timeoutSecs) {
            if self.numSuccesses <= prevNumSuccesses && self.isInProgress() {
                self.fail("Timeout waiting for canary notification")
            }
        }
    }
    
    private func makeRequest() {
        guard let apnsToken = apnsToken else {
            fail("APNs token is nil")
            return
        }
        
        let url = URL(string: "http://\(RegistrationCanaryEnvironment.apnsProxyHostname):8001/ping/\(apnsToken)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                self.error("Error connecting to local APNs proxy (is it running?): \(error!.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                fatalError("Expected an HTTPURLResponse, got \(String(describing: response))")
            }
            
            logger.info("Got status code \(httpResponse.statusCode)")
            
            guard 200..<300 ~= httpResponse.statusCode else {
                self.error("Local APNs proxy returned status \(httpResponse.statusCode)")
                return
            }
            
            // Only increment the attempts counter once we've made the request,
            // so that failures to connect to the local proxy don't affect the stats.
            self.numAttempts += 1
            self.callDelegate()
        }
        
        task.resume()
    }
    
    @objc private func apnsTokenReceived(_ notification: Notification) {
        self.apnsToken = notification.object as? String
    }
    
    @objc private func remoteNotificationReceived(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            logger.warning("Received a notification with no userInfo")
            return
        }
        
        guard userInfo["canary"] as? String == "true" else { return }
        
        succeed()
    }
    
    private func succeed() {
        numSuccesses += 1
        state = .succeeded
        callDelegate()
    }
    
    private func fail(_ msg: Logger.Message) {
        logger.error(msg)
        state = .failed
        callDelegate()
    }
    
    private func error(_ msg: Logger.Message) {
        logger.error(msg)
        state = .errored(message: msg.description)
        callDelegate()
    }

    private func callDelegate() {
        DispatchQueue.main.async {
            self.delegate?.attemptableDidChange(self)
        }
    }
    
    private func isInProgress() -> Bool {
        switch state {
        case .inProgress(deadline: _):
            return true
        default:
            return false
        }
    }
}

private let logger = Logging.Logger(label: "ApnsAttemptable")
