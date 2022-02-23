# Demo Swift application which uses HAAPI

[![Quality](https://img.shields.io/badge/quality-demo-red)](https://curity.io/resources/code-examples/status/)
[![Availability](https://img.shields.io/badge/availability-source-blue)](https://curity.io/resources/code-examples/status/)

This is an example iOS app which uses the Curity Identity Server's Hypermedia API to perform an
OAuth2 flow with authentication done completely from the app, without the need of an external browser.

This project highlights the usage of the [iOS HAAPI SDK](https://github.com/curityio/ios-idsvr-haapi-sdk-dist).

## Getting started

### Xcode

You need Xcode at least version 12.4 so that it supports iOS 14.

### Swiftlint

If you want to use Swiftlint, you will need at least version 0.43.

```
brew install swiftlint
```

### Docker Automated Setup

The required Curity Identity Server setup and connectivity from devices can be automated via a bash script:

- Copy a license.json file into the code example root folder.
- Run the `./start-idsvr.sh` script to deploy a preconfigured Curity Identity Server via Docker.
- Build and run the mobile app from Xcode using a simulator of your choice.
- There is a preconfigured user account you can sign-in with: `demouser / Password1`. Feel free to create additional accounts.
- Run the `./stop-idsvr.sh` script to free Docker resources.

By default the Curity Identity Server instance runs on localhost.
If you prefer to expose the Server on the Internet (e.g. to test with a real device), you can use the
ngrok tool for that. Edit the `USE_NGROK` variable in `start-server.sh` and `stop-server.sh` scripts.
This [Mobile Setup](https://curity.io/resources/learn/mobile-setup-ngrok/) tutorial further describes
this option.

### Setting up with Your Own Instance of the Curity Identity Server

You can install and run your own instance of the Curity Identity Server by following this tutorial: https://curity.io/resources/getting-started/

Modify *curity-config.xml* by replacing these placeholders:

- $ID$: A unique identifier of the Token Service profile. This identifier would be visible in your identity server. If you haven't changed the default settings of your Curity Identity Service, then this will be `token-service`.
- $APPID$: Your iOS application ID, for example, `ABCD1234.com.myapplication`. `ABCD1234` can be found in your developer / app store account. `com.myapplication` is the bundle identifier configured in your Xcode project and defined in your app store account for of your application. The demo app bundle identifier is `io.curity.cat.ios.client`.

Once installed you can easily configure the server by uploading the provided configuration file.
❗️When applying the provided configuration to your identity server, you will be able to run directly the demo application on the simulator.

To upload the configuration, follow these steps:
1. Login to the admin UI (https://localhost:6749/admin if you're using defaults).
2. Upload `curity-config.xml` through the **Changes**->**Upload** menu at the top. (Make sure to use the `Merge` option)
3. Commit changes through the **Changes**->**Commit** menu.

## Testing the demo app against your identity server

### Simulator

1. Make sure that the Curity Identity Server is running and configured.
2. Run the demo app on a chosen simulator.
3. Tap `Start Authentication`.

### Physical device

1. Make sure that the Curity Identity Server is running and configured to be reachable on the Internet (e.g. by using [ngrok](https://curity.io/resources/learn/expose-local-curity-ngrok/)), or
from another device on the same network (e.g. by setting the base URL to `https://192.168.1.3:8443`, if that's the host's IP on the network).
2. Run the demo app on your device.
4. Tap *Settings* in the tab navigation bar of the app.
5. Tap your active profile (**Default** if no other profile has been created and made active).
6. Change Base URL and the issuer URI to the one configured for your Curity Identity Server. For example, https://192.168.1.3:8443 and https://192.168.1.3:8443/oauth/v2/aouth-anonymous/.
7. Tap **Fetch the latest configuration** to read metadata from the server.
7. Tap *Home* in the tab navigation bar of the app.
8. Tap `Start Authentication`.

### Demo app information

- The demo app will interact with the client "<u>haapi-ios-dev-client</u>", unless changed (see [Configuring the app](#configuring-the-app))
- The Demo application is configured in order to support the redirect-uris. See the /Demo/Info.plist in CFBundleURLTypes
  - CFBundleURLName: io.curity.haapi
  - CFBundleURLSchemes: <u>haapi</u>

## Configuring the App

The application needs a few configuration options set to be able to call the instance of the Curity Identity Server.
Default configuration is set to work with the dockerized version of the Curity Identity Server which
is run with the `start-idsvr.sh` script. Should you need to make the app work with a different environment
(e.g. you have your instance of the Curity Identity Server already working online), then you can adjust
the configuration in two ways:

1. You can edit the default settings in the `Demo/Settings/Profile` file.
   The default settings are defined in the `Constants` enum.

2. You can update settings directly in the running app. When on the home screen of the app you can tap
   the settings icon. There you will be able to create and edit configuration profiles. You can then
   switch the active profile to quickly test between different environments of the Curity Identity Server.

## Troubleshooting

- `IdsvrHaapiSdk.HaapiError error 8`: Your identity server was not configured and the demo app cannot reach it. The identity server needs to be configured and accessible for the device or simulator.
- `IdsvrHaapiSdk.HaapiError error 4.`: If you are running on a simulator and you get this error, it means that Disable Attestation Validation in your client settings is disabled and it should be **<u>enabled</u>**.

## More information

For further details about this code example, see the [Tutorial Walkthrough](https://curity.io/resources/learn/swift-ios-haapi/) on the Curity website.\
Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.

## Licensing

This software is copyright (C) 2021 Curity AB. It is open source software that is licensed under the [Apache 2](https://github.com/curityio/react-assisted-token-website/blob/master/LICENSE).

