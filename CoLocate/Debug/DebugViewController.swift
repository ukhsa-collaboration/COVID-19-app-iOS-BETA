//
//  DebugViewController.swift
//  CoLocate
//
//  Created by NHSX.
//  Copyright © 2020 NHSX. All rights reserved.
//

import UIKit

#if DEBUG || INTERNAL

class DebugViewController: UITableViewController, Storyboarded {
    static let storyboardName = "Debug"

    @IBOutlet weak var versionBuildLabel: UILabel!
    @IBOutlet weak var potentiallyExposedSwitch: UISwitch!
    
    private var persisting: Persisting!
    private var contactEventRepository: ContactEventRepository!
    private var contactEventPersister: ContactEventPersister!
    private var contactEventsUploader: ContactEventsUploader!

    private var bluetoothNursery: ConcreteBluetoothNursery!
    var observation: NSKeyValueObservation?

    @IBOutlet weak var bluetoothStatus: UIView!
    @IBOutlet weak var bluetoothImage: UIImageView!
    var fillLayer: CAShapeLayer!

    @IBOutlet weak var broadcasterStatus: UIImageView!
    @IBOutlet weak var listenerStatus: UIImageView!

    func inject(
        persisting: Persisting,
        bluetoothNursery: BluetoothNursery,
        contactEventRepository: ContactEventRepository,
        contactEventPersister: ContactEventPersister,
        contactEventsUploader: ContactEventsUploader
    ) {
        self.persisting = persisting
        self.bluetoothNursery = bluetoothNursery as? ConcreteBluetoothNursery
        self.contactEventRepository = contactEventRepository
        self.contactEventPersister = contactEventPersister
        self.contactEventsUploader = contactEventsUploader
    }
    
    override func viewDidLoad() {
        potentiallyExposedSwitch.isOn = persisting.potentiallyExposed

        let build = Bundle.main.infoDictionary?["CFBundleVersion"] ?? "unknown"
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "unknown"
        versionBuildLabel.text = "Version \(version) (build \(build))"

        fillLayer = CAShapeLayer()

        if bluetoothNursery.isHealthy {
            self.setupAnimation()
        } else {
            self.removeAnimation()
        }

        setBluetoothStatus(broadcasterStatus, bluetoothNursery.broadcaster?.isHealthy() ?? false)
        setBluetoothStatus(listenerStatus, bluetoothNursery.listener?.isHealthy() ?? false)
    }

    private func setBluetoothStatus(_ imageView: UIImageView, _ isHealthy: Bool) {
        guard #available(iOS 13.0, *) else { return }

        if isHealthy {
            imageView.image = UIImage(systemName: "hand.thumbsup.fill")
        } else {
            imageView.image = UIImage(systemName: "hand.thumbsdown.fill")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        bluetoothImage.addObserver(self, forKeyPath: #keyPath(UIView.bounds), options: .new, context: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        bluetoothImage.removeObserver(self, forKeyPath: #keyPath(UIView.bounds))
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        switch (indexPath.section, indexPath.row) {
        case (0, _):
            break

        case (1, 0):
            persisting.clear()
            try! SecureBroadcastRotationKeyStorage().clear()
            show(title: "Cleared", message: "Registration and diagnosis data has been cleared. Please stop and re-start the application.")

        case (1, 1), (1, 2):
            break
            
        case (1, 3):
            kill(getpid(), SIGINT)
            

        case (2, 0):
            let uuid = UUID()
            contactEventPersister.items[uuid] = ContactEvent(encryptedRemoteContactId: uuid.data, timestamp: Date(), rssiValues: [], rssiIntervals: [], duration: 1)
            show(title: "Conatact", message: "Dummy contact event recorded.")
            
        case (2, 1):
            let uuid = UUID()
            contactEventPersister.items[uuid] = ContactEvent(encryptedRemoteContactId: uuid.data, timestamp: Date(timeIntervalSinceNow: -2592000), rssiValues: [], rssiIntervals: [], duration: 1)
            show(title: "Expired Conatact", message: "Expired Dummy contact event recorded.")
            
        case (2, 2):
            contactEventRepository.reset()
            show(title: "Cleared", message: "All contact events cleared.")
            
        case (2, 3):
            let notificationCenter = NotificationCenter.default
            notificationCenter.post(name: UIApplication.significantTimeChangeNotification, object: nil)
            show(title: "Cleared", message: "All expired contact events cleared.")
            
        case (2, 4):
            try! contactEventsUploader.upload()
            show(title: "Upload Initiated", message: "Contact events uploading.")

        case (3, 0):
            do {
                guard let registration = persisting.registration else {
                    throw NSError()
                }
                let delay = 15
                let request = TestPushRequest(key: registration.secretKey, remoteEncryptedBroadcastId: registration.id, delay: delay)
                URLSession.shared.execute(request, queue: .main) { result in
                    switch result {
                    case .success:
                        self.show(title: "Push scheduled", message: "Scheduled push with \(delay) second delay")
                    case .failure(let error):
                        self.show(title: "Failed", message: "Failed scheduling push: \(error)")
                    }
                }
            } catch {
                show(title: "Failed", message: "Couldn't get sonarId, has this device completed registration?")
            }

        case (4, 0):
            #if DEBUG
            guard let debugInfo = Environment.debug else {
                show(title: "Failed", message: "Could not find known good registration info. This build was not configured with this feature.")
                return
            }

            let id = debugInfo.registrationId
            let secretKey = debugInfo.registrationSecretKey
            let broadcastKeyS = debugInfo.registrationBroadcastRotationKey
            let broadcastKey = try! BroadcastRotationKeyConverter().fromData(Data(base64Encoded: broadcastKeyS)!)
            persisting.registration = Registration(id: UUID(uuidString: id)!, secretKey: secretKey.data(using: .utf8)!, broadcastRotationKey: broadcastKey)

            #else

            show(title: "Unavailable", message: "This dangerous action is only available in debug builds.")

            #endif

        case (5, 0):
            do {
                let fileManager = FileManager()
                let documentsFolder = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let viewController = UIActivityViewController(activityItems: [documentsFolder], applicationActivities: nil)
                present(viewController, animated: true, completion: nil)
            } catch {
                let viewController = UIAlertController(title: "No data to share yet", message: nil, preferredStyle: .alert)
                viewController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(viewController, animated: true, completion: nil)
            }

        case (6, 0):
            break

        default:
            break
        }
    }

    private func show(title: String, message: String, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default))
        present(alertController, animated: true, completion: completion)
    }

    @IBAction func potentiallyExposedChanged(_ sender: UISwitch) {
        persisting.potentiallyExposed = sender.isOn
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let vc as SetDiagnosisViewController:
            vc.inject(persistence: persisting)
        default:
            break
        }
    }

    @IBAction func unwindFromSetDiagnosis(unwindSegue: UIStoryboardSegue) {
    }

    // MARK: - Bluetooth status animation

    private func setupAnimation() {
        fillLayer = CAShapeLayer()
        fillLayer.path = computeProperCGPath()
        fillLayer.fillRule = .evenOdd;
        fillLayer.fillColor = UIColor.green.cgColor
        fillLayer.opacity = 0.4;
        bluetoothImage.layer.addSublayer(fillLayer)

        let scaleAnimation = CABasicAnimation(keyPath: "transform")
        var tr = CATransform3DIdentity;
        tr = CATransform3DTranslate(tr, bluetoothImage.bounds.size.width / 2, bluetoothImage.bounds.size.height / 2, 0);
        tr = CATransform3DScale(tr, 3, 3, 1);
        tr = CATransform3DTranslate(tr, -bluetoothImage.bounds.size.width / 2, -bluetoothImage.bounds.size.height / 2, 0);
        scaleAnimation.toValue = NSValue(caTransform3D: tr)

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.duration = 1.8
        opacityAnimation.fromValue = 0.4
        opacityAnimation.toValue = 0

        let animations = [
            scaleAnimation,
            opacityAnimation,
        ]

        let animationGroup = CAAnimationGroup()
        animationGroup.duration = 1.8
        animationGroup.repeatCount = .infinity
        animationGroup.animations = animations;

        fillLayer.add(animationGroup, forKey: "pulse")

        bluetoothImage.image = UIImage(named: "bluetooth")
    }

    private func removeAnimation() {
        fillLayer.removeAnimation(forKey: "pulse")
        fillLayer.removeFromSuperlayer()

        if #available(iOS 13.0, *) {
            bluetoothImage.image = UIImage(systemName: "hand.thumbsdown.fill")
        } else {
            bluetoothImage.image = UIImage(named: "hand.thumbsdown.fill")
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == #keyPath(UIView.bounds) else { return }

        fillLayer.path = computeProperCGPath()
    }

    private func computeProperCGPath() -> CGPath {
        let size = 30
        let radius = 25

        let centerX: Int = Int(bluetoothImage.frame.size.width)  / 2 - size / 2
        let centerY: Int = Int(bluetoothImage.frame.size.height) / 2 - size / 2

        let path = UIBezierPath(roundedRect: CGRect(x: centerX,
                                                    y: centerY,
                                                    width: size,
                                                    height: size),
                                                    cornerRadius: CGFloat(radius))
        let circlePath = UIBezierPath(roundedRect: CGRect(x: centerX + size / 2 - radius / 2,
                                                          y: centerY + size / 2 - radius / 2,
                                                          width: radius,
                                                          height: radius),
                                                          cornerRadius: CGFloat(radius))
        path.append(circlePath)
        path.usesEvenOddFillRule = true

        return path.cgPath
    }
}

// MARK: - Testing push notifications

class TestPushRequest: SecureRequest, Request {
    
    typealias ResponseType = Void
                    
    let method: HTTPMethod
    
    let path: String
    
    init(key: Data, remoteEncryptedBroadcastId: UUID, delay: Int = 0) {
        let data = Data()
        method = .post(data: data)
        path = "/api/debug/notification/residents/\(remoteEncryptedBroadcastId.uuidString)?delay=\(delay)"
        
        super.init(key, data, [:])
    }
    
    func parse(_ data: Data) throws -> Void {
    }
}

#endif
