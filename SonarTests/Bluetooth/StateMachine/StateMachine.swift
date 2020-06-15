import Foundation

protocol State {
    var previousState: State? { get }
    var nextStates: [State] { get }
    func execute()
}

extension State {
    var previousState: State? {
        get {
            return nil
        }

    }
    var nextStates: [State] {
        get {
            return []
        }
    }

    func execute() {

    }
}

struct Scan: State {
}

struct DiscoverPeripheral: State {

}

struct Connect: State {

}

struct ReadRSSI: State {

}

struct ScheduleKeepAlive: State {

}

struct SendKeepAlive: State {

}

struct ReceiveKeepAlive: State {

}

struct DiscoverServices: State {

}

struct DiscoverServicesCharacteristics: State {

}

struct EnableCryptogramNotification: State {

}

struct EnableKeepAliveNotification: State {

}

struct ReceiveCryptogram: State {

}

struct SendCryptogram: State {

}

struct ScheduleIdentityRotation: State {

}

struct StateMachine {



}
// Setup/Given
// Scan -> DiscoverPeripheral -> connect -> ReadRssi         -> (3x)
//                                       -> DiscoverServices -> (successful) -> Background

// Assertions
// assert 4 readings of rsssi on disk with expected cryptogram
// assert peripheral is registered

// Scan -> DiscoverPeripheral -> connect -> error
// assert peripherals contain peripheral




