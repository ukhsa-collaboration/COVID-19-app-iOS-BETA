# Registration Canary

This is a diagnostic tool that helps assess the health of both the entire
registraton system and APNS. It can send and try to receive an APNS remote
notification and/or attempt an actual registration, either on demand or
continuously.
 
Note that Registration Canary necessarily uses the same bundle identifier as
Sonar, so you can't have both apps installed at the same time.
 
## Setup
 
- Create `.secret/RegistrationCanaryEnvironment.swift` with the following
  contents:
```
struct RegistrationCanaryEnvironment {
    static let apnsProxyHostname = "YOUR_HOSTNAME_OR_IP_ADDRESS"
}
```
- If you haven't already done so, set the `TEAMID`, `KEYID`, `SECRET`, and
  `BUNDLEID` environment variables.
  See the comments in `bin/pu.sh` for more information.
- Change to the `servers` directory and run `node apns-canary-proxy.js`. If
  you skip this step, the app can still check registration but will be unable
  to check APNS directly.
- In Xcode, run the `RegistrationCanary` scheme on a physical device.

## Caveats and limitations

- A physical device is required.
- APNS will block or throttle remote notifications if too many are sent to a
  given device in a certain period of time. This threshold isn't well
  understood yet, and the current auto retry interval might be too small.
- Logging is currently only exposed via the Xcode debugger console. Showing
  logs in the app would be a good enhancment.
