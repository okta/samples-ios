# Okta iOS Custom Sign In Example

This example shows you how to use the [Okta Auth Swift](https://github.com/okta/okta-auth-swift) to adopt Okta Authentication flow in your app.


## Prerequisites

Before running this sample, you will need the following:

* An Okta Developer Account, you can sign up for one at https://developer.okta.com/signup/.
* An Okta Application, configured for iOS client. This is done from the Okta Developer Console and you can find instructions [here](https://developer.okta.com/quickstart/#/ios/nodejs/express).  When following the wizard, use the default properties.  They are designed to work with our sample applications.


## Running This Example

To run this application, you first need to clone this repo and then enter into this directory:

```bash
git clone https://github.com/okta/samples-ios.git
cd custom-sign-in/
```

Then install dependencies:

```bash
pod repo update
pod install
```

You need to gather the following information from the Okta Developer Console:

- **Client ID**, **Redirect URI** - This can be found on the "General" tab of an application, you want to get this for the Web application that you created earlier.

- **Issuer** - This is the URL of the authorization server that will perform authentication.  All Developer Accounts have a "default" authorization server.  The issuer is a combination of your Org URL (found in the upper right of the console home page) and `/oauth2/default`. For example, `https://dev-1234.oktapreview.com/oauth2/default`.

Now place these values into the file `OktaNativeLogin/Okta.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>scopes</key>
    <string>openid profile offline_access</string>
    <key>redirectUri</key>
    <string>{redirectUri}</string>
    <key>clientId</key>
    <string>{clientId}</string>
    <key>issuer</key>
    <string>{issuer}</string>
</dict>
</plist>

```

Now assign your Org URL to `urlString` property in `SignInViewController.swift` class (line #24):

```swift
#warning ("Enter your Okta organization domain here")
var urlString = "https://{yourOktaDomain}"
```

Now you can build and run the application.

Enter your credentials and tap the **Sign in** button. App will guide you through Okta Authentication flow. 

You can login with the same account that you created when signing up for your Developer Org, or you can use a known username and password from your Okta Directory.

After you complete the login flow, you will be able to see the details of user's account.

## Features

- Primary authentication
- Change password
- Multi factor verification (sms, call, totp, push, question)
- Getting access token via [Okta OIDC client](https://github.com/okta/okta-oidc-ios)
- Multi factor enrollment
- Self-service unlock
- Forgot password

## Other

- Sample application shows how to implement factors that are not supported by the SDK.  Find `OktaYubiKeyFactor` class in project to check implementation. For simplicity application asks for manual `passCode` input. It is supposed that the real application will use `YubiKey` SDK to automatically fetch `passCode` from the device.
- Sample application shows how to implement custom mocks for the status classes and custom response handler. Mock classes can be found in `MockExample` folder.
