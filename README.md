# Haapi Demo

This project is a demo application that highlights the usage of [ios-idsvr-haapi-sdk-dist](https://github.com/curityio/ios-idsvr-haapi-sdk-dist). 

## Getting started

### Xcode

Version 12.4+ - at least a version that supports iOS 14

### Swiftlint 

Minimum version 0.43

```
brew install swiftlint
```

### Setting up the identity server

Install and run Curity Identity Server: https://curity.io/resources/getting-started/ 

### Configure the identity server to be able to test with the demo app

Modify *curity-config.xml* by replacing these placeholders:

- $ID$: An unique identifier for this profile. This identifier would be visible in your identity server. The demo app is using `haapi-ios-dev-client`. 
- $APPID$: Your iOS application ID, for example, `ABCD1234.com.myapplication`. `ABCD1234` can be found in your developer / app store account. `com.myapplication` is the bundle identifier configured in your Xcode project and defined in your app store account for of your application. The demo app bundle identifier is `io.curity.cat.ios.client`. 

Navigate to your identity server admin page and upload *curity-config.xml* and commit the changes.

## Testing the demo app against your identity server

__Prerequisite__: Configure the identity server to be able to test with the demo app is a <u>prerequiste</u> 

### Simulator

1. In the identity server, check the Base URL. By default, it should be https://localhost:8443
2. In the identiy server, Profiles -> OAuth Dev -> Clients -> `haapi-ios-dev-client` -> Client Application Settings: set _Disable Attestation Validation_ is **true** (it should be disabled when using on a physical device for production)
3. Run the demo app
4. Tap *Settings* in the tab navigation bar of the app
5. Tap your active profile (**Default** if no other profile has been created and made active)
6. Change Base URL and the endpoint URL to the one configured for your Curity Identity Server. 
7. Tap *Home* in the tab navigation bar of the app
8. Tap `Start Authentication`

### Physical device 

1. In the identity server, update your identity server URL to be accessible from another device. For example: https://192.168.1.1:8443
2. In the identiy server, Profiles -> OAuth Dev -> Clients -> `haapi-ios-dev-client` -> Client Application Settings: set _Disable Attestation Validation_ is **false** (for testing, it can be enabled but not for production !)
3. Run the demo app
4. Tap *Settings* in the tab navigation bar of the app
5. Tap your active profile (**Default** if no other profile has been created and made active)
6. Change Base URL and the endpoint URL to the one configured for your Curity Identity Server. For example, https://192.168.1.1:8443
7. Tap *Home* in the tab navigation bar of the app
8. Tap `Start Authentication`

### Demo app information

- The demo app will interact with the client "<u>haapi-ios-dev-client</u>"
- The Demo application is configured in order to support the redirect-uris. See the /Demo/Info.plist in CFBundleURLTypes
  - CFBundleURLName: io.curity.haapi
  - CFBundleURLSchemes: <u>haapi</u>

## Troubleshooting

- `IdsvrHaapiSdk.HaapiError error 8`: Your identity server was not configured and the demo app cannot reach it. The identity server needs to be configured and accessible for the device or simulator.
- `IdsvrHaapiSdk.HaapiError error 4.`: If you are running on a simulator and you get this error, it means that Disable Attestation Validation is disabled and it should be **<u>enabled</u>**. 

## Docker Automated Setup

The above Curity Identity Server setup and connectivity from devices can be automated via a bash script:

- Copy a license.json file into the code example root folder
- Edit the `./start-idsvr.sh` script to use either a local Docker URL on an ngrok internet URL
- Run the script to deploy a preconfigured Curity Identity Server via Docker
- Build and run the mobile app from Xcode
- Sign in with the preconfigured user account `demouser / Password1`
- Edit the `./stop-idsvr.sh` script to use matching ngrok settings to the start script
- Run the script to free Docker resources

The [Mobile Setup](https://curity.io/resources/learn/mobile-setup-ngrok/) article provides further details on this setup.

## More information

For further details about this code example, see the [Tutorial Walkthrough](https://curity.io/resources/learn/swift-ios-haapi/) on the Curity website.\
Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.

## Licensing

This software is copyright (C) 2021 Curity AB. It is open source software that is licensed under the [Apache 2](https://github.com/curityio/react-assisted-token-website/blob/master/LICENSE).