# NHS COVID-19

![ci](https://github.com/nhsx/sonar-ios/workflows/ci/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Release: BETA](https://img.shields.io/badge/Release-BETA-orange)

This application runs in the background and identifies other people running the
app within the local area by using low energy Bluetooth. While the app is
running permanently in the background, it periodically broadcasts and listens
for other Bluetooth-enabled devices (iOS and Android at this time) that also
broadcast the same unique identifier.

## How it works

Our unique identifier is also known as our service characteristic. In the
Bluetooth spec, devices can broadcast the availability of services. Each
service can have multiple characteristics. We use a characteristic to uniquely
identify our service and distinguish from all other sorts of Bluetooth devices.

For every device we find with a matching characteristic, we record an
identifier for the device we saw, the timestamp, and the RSSI of the Bluetooth
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
- Create `.secret/RegistrationCanaryEnvironment.swift` with the following contents:
```
struct RegistrationCanaryEnvironment {
    static let apnsProxyHostname = "YOUR_HOSTNAME_OR_IP_ADDRESS"
}
```
- **If Xcode is open, restart Xcode.** Xcode does not handle configuration
  files being changed out from under it gracefully.

### MoreStatusStateMachineTests

TODO
https://nshipster.com/swift-gyb/
- why do blocks?

### Registration Canary

The registration canary is a diagnostic tool that helps assess the health of
both the entire registraton system and APNS. See `RegistrationCanary/README.md`
for more information.

### Setup for Pact Testing
Run `bin/pact/setup` to install all necessary libraries, and install Sonar CA and trust it on all 
running Simulator devices.

You can then proceed as indicated in the README of the [Swift Pact Consumer library](https://github.com/DiUS/pact-consumer-swift)
to create pact tests. A mock service will be spun up for you before tests on `https://localhost:1234`
using a build step before action, and torn down afterwards.

If you get an SSL or ATS error when running the tests, re-run `bin/pact/setup` to ensure that all 
devices have the Sonar CA setup correctly.

#### Pact Setup Context
Contract testing requires a mock server to be running that we can verify contracts against.
This is done by `pact-mock-service` which is installed as a Ruby library (gem). Once the 
contract is defined, it is then uploaded to the pact broker, which is done via `pact-broker`,
also installed as a Ruby gem.

In order to satisfy App Transport Security (ATS) requirements, the setup involves a certificate 
for localhost that is issued by a Certificate Authority (CA) created for this project, Sonar CA.
This is necessary since self-signed certificates are not accepted by ATS.

The certificate has a TTL of 2 years. When it expires, you will need to create a new Sonar CA,
export the keys and generate a new certificate since we won't be including the CA private key here.
This is to avoid any devices being used for testing accidentally becoming vulnerable to MitM.

The setup then installs the certificates in the simulator's SQLite trust store database using 
the [ADVTrustStore](https://github.com/ADVTOOLS/ADVTrustStore) library. It has been vendored and 
modified in order to not require user input so we're able to run it in CI.

We're then using the UI testing framework, specifically TrustSonarCARootCertTest to trust the 
Sonar CA root certificate on all booted simulator devices.

Pact tests are in a separate scheme since we do need to inject `https://localhost:1234` as the API
endpoint. This is done via script in pre-action (`bin/pact/setup-build-environment`). We want 
to avoid rewriting the file for other debug builds such as the ones you push to your phone.

### Notifications

The app currently relies on **remote** (as opposed to **push**) notifications,
which we unfortunately have not been able to trigger on the Simulator. Push
notifications (in the form of `.apns` files) can be dragged onto a Simulator
window or passed into `simctl`, but remote notifications are only delivered on
devices.

There are currently a couple ways to do development with remote notifications:

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

**Code is truth.** See the [GitHub Actions configuration](.github/workflows)
for the current behavior of the system. (And please update this documentation
if it's wrong!)

### Continuous Delivery

All pushes get built (for both simulator and device) and tested (on iOS 12 and
13). The `TestResult.xcresult` file is archived for future reference.
Successful pushes on `master` get promoted to `internal`. Every hour, if the
tip of `internal` hasn't been deployed, we bump the build number and trigger a
deployment to the internal and beta apps, which will cut a release build and
upload it to Apple.

Once the builds are uploaded, they go through App Store processing. Once that
finishes, there are some **manual steps** that need to be done by someone with
App Manager+ permissions in App Store Connect in order to release the build to
testers:

1. Add Export Compliance Information to the build
  - This will release the build to App Store Connect Users
2. Add the build to the appropriate test groups

### Branches and Versions and Build Numbers, Oh My!

The release process caters for our normal use case, since with trunk-based
development and continuous delivery, we can select a specific commit to promote
as a production release.

However, this optimization means that the process for creating a release that
is not based off trunk (`internal` for releases, as `master` is trunk for
development) requires more manual intervention. For example, cutting a hotfix
release from a previous release commit will generally require a branch with the
necessary changes and a manual build number bump. The release process then
continues as normal, by deploying from the commit to a specified environment.

### Deploying to Production

To trigger a release manually, set the following environment variables:

```shell
DEPLOYMENT_TOKEN="" # obtain one from here: https://github.com/settings/tokens
GITHUB_REPOSITORY="nhsx/<repository-name-here>"
DEPLOYMENT_SHA="<sha of commit you want to release>"
```

Run the following command:

```shell
./bin/create-deployment <beta/internal/production>
```

### Setup/Configuration

The app's configuration is driven through three files in the `.secret` directory:

- `Sonar.xcconfig` 
  - This is a pointer at one of the app configurations in
    [Sonar/Environments](Sonar/Environments). These mostly capture the
    differences for our separate applications in App Store Connect.
- `Environment.swift`
  - Configuration that gets injected in at build time in CI. Developers should
    generate a copy that points at the test environment for local development.
  - There's a [script](bin/make-environment) that takes a JSON file
    ([example][env-json]) and the [template][env-erb] and generates a valid
    `Environment.swift` file for the build.
- `GoogleService-Info.plist`
  - Needed for Firebase.

[env-json]: Sonar/Environments/environment.json
[env-erb]: Sonar/Environments/Environment.swift.erb

CI configuration requires the following secrets:

- `apple_username`, `apple_password`
  - Used for uploading to App Store Connect.
- `deployment_token`
  - Used for yo-dawg-ing CI. (Sensibly, GitHub Actions doesn't allow recursive
    triggering of CI workflows from other CI workflows via the built-in token,
    so we need to use our own for this purpose.)
- `environment_json_{environment}`,`google_service_info_{environment}`
  - Per-environment app configuration.
- `match`, `match_password`
  - Used by [fastlane](https://fastlane.tools) to set up credentials for
    building a distributable version of the app. See below for the gory, gory
    details.
- `pivotal_tracker_api_token`, `pivotal_tracker_project_id`,
  `tracker_api_token`
  - For automatically updating the backlog from story IDs in commits.
- `slack_bot_token`
  - Lets us know when we've broken CI in Slack.

#### Fastlane Match

Since we don't want to manually upload builds to App Store Connect and we don't
want to write that automation ourselves, that pretty much leaves us with
fastlane's [upload\_to\_testflight][upload-to-testflight] action.

[upload-to-testflight]: https://docs.fastlane.tools/actions/upload_to_testflight/

Long story short, we need to have a certificate and provisioning profile set up
to build the app. These are secrets, and we do not want to expose them to the
world. The path of least resistance with Fastlane is to use [match][match], but
this conflicts somewhat with our team and development structure - we don't want
to force other dev teams to use fastlane or match, so we can't have match
manage the setup, and we also don't have a separate repo to use for match[1].
We also want to continue using Xcode's "automatically manage signing" option
for development.

[match]: http://docs.fastlane.tools/actions/match/

[1] In hindsight, I wish we had explored this option further, but we have what
we have now and it works, although in an unnecessarily complicated manner.

In theory, we should be able to use [cert][cert] and [sigh][sigh] to manage the
credentials as secrets, but I was unable to get that to work in CI. (This would
really be the ideal way to handle this.) Instead, what we have is a monstrous
hack around [match][match], where we keep a stub of the match repo in
[source](ci/match) and a tar of the certs and profiles as a secret in CI, and
then [create the match repo](bin/setup-match) in CI.

[cert]: http://docs.fastlane.tools/actions/cert/#cert
[sigh]: http://docs.fastlane.tools/actions/sigh/#sigh

That might not seem too bad, but it's the setup of the match repository that
gets hairy. There's undoubtedly a better way to do this, but this works. Here
it is from memory, unfortunately, since I didn't write this down either time I
set it up:

1. Create a git repository for match locally that matches the stub in this
   repository (`ci/match`).
1. Switch to a branch that's not `master` so that match can use `master`.
1. Initialize match (`fastlane match init`) pointed at the local repo.
1. Get certs and profiles via match (`fastlane match appstore`). This should
   store the secrets in the local repository, encrypted.
1. Tar up the certs and profiles into a secrets-compatible format. Something
   like `tar cvz ci/match/certs ci/match/profiles | base64 > match.b64`, but I
   don't remember the exact command. Regardless, you should be able to dump it
   into a `MATCH` environment variable and then run `./bin/setup-match` in the
   root of this repo and see the certs and profiles get populated into
   `ci/match`. If this didn't work, these steps should be enough to mostly
   point you in the right direction and hopefully you'll come back and update
   these steps to be accurate when you do figure it out.
