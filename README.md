# NHS COVID-19 BETA for iOS

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Release: BETA](https://img.shields.io/badge/Release-BETA-orange)

This application runs in the background and identifies other people running the
app within the local area by using low energy bluetooth. While the app is
running permanently in the background, it periodically broadcasts and listens
for other bluetooth-enabled devices (iOS and Android at this time) that also
broadcast the same unique identifier.

## How it works

Our unique identifier is also known as our service characteristic. In the
bluetooth spec, devices can broadcast the availability of services. Each
service can have multiple characteristics. We use a characteristic to uniquely
identify our service and distinguish from all other sorts of bluetooth devices.

For every device we find with a matching characteristic, we record an
identifier for the device we saw, the timestamp, and the rssi of the bluetooth
signal, which will allow a team later on to determine who was in close
proximity to individuals infected with the novel coronavirus.

## Functionality

* Passively collect anonymized ids of other users of the app that the device
  has been in proximity with (stored locally on the device)
* Allow the user to submit their "contact events" to NHS servers
* Receive push notifications from NHS and inform the user of their exposure
  status

## Development

### Setup

```sh
cp Sonar/Environments/Sonar.xcconfig.sample .secret/Sonar.xcconfig
./bin/make-environment < Sonar/Environments/environment.json > .secret/Environment.swift
```

- Fill in the `Environment.swift` file with the appropriate values from another
  developer.
- Get a copy of GoogleService-Info.plist from one of the other developers and
  copy that into the `.secret` directory.
- **If Xcode is open, restart Xcode.** Xcode does not handle configuration
  files being changed out from under it gracefully.

### Notifications

The app currently relies on *remote* (as opposed to *push*) notifications,
which we unfortunately have not been able to trigger on the Simulator. Push
notifications (in the form of `.apns` files) can be dragged onto a Simulator
window or passed into `simctl`, but remote notifications are only delivered on
devices.

There are currently a couple ways to do development with remote notificcations:

- `./bin/pu.sh` is a script forked from [pu.sh](https://github.com/tsif/pu.sh).
  There are instructions there for obtaining credentials from an Apple
  Developer account. However, we are out of available APNs keys, so you'll need
  to obtain that from another developer. Run the script with the path to one of
  the example notifications to send a remote notification through Apple:
  `./bin/pu.sh "Example Notifications/2_potential_diagnosis.apns`. You will
  also need to set the following environment variables to configure the script:
  - `TEAMID`
  - `KEYID`
  - `SECRET` - the fully expanded path to the `.p8` key.
  - `BUNDLEID`
  - `DEVICETOKEN` - retrieved from the console when running the application.

## Releases

Builds are automatically generated from CI. Each two hours, we merge any
changes from `master` into `internal`, bump the version, and cut a build that
gets uploaded to Test Flight.

Please do not merge the `internal` branch or `ci` branch into master.

