# Okta iOS Custom Sign In Example

This example shows you how to use the [Okta Auth Swift](https://github.com/okta/okta-auth-swift) to adopt Okta Authentication flow in your app.


## Prerequisites

Before running this sample, you will need the following:

* An Okta Developer Account, you can sign up for one at https://developer.okta.com/signup/.
* An Okta Application, configured for iOS client. This is done from the Okta Developer Console and you can find instructions [here][OIDC Native iOS Application Setup Instructions].  When following the wizard, use the default properties.  They are designed to work with our sample applications.


## Running This Example

To run this application, you first need to clone this repo and then enter into this directory:

```bash
https://github.com/okta/samples-ios.git
cd custom-sign-in/
```

Then install dependencies:

```bash
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

Now specify your Org URL in the place where `AuthenticationClient` is created (see `OktaNativeLogin/NativeSignInViewController.swift`):

```swift
client = AuthenticationClient(oktaDomain: URL(string: "{yourOktaDomain}")!, delegate: self, mfaHandler: self)
```

Now you can build and run the application.

If you see a home page that prompts you to login, then things are working!  Clicking the **Log in** button will prompt you to enter you credential. App will guide you through Okta Authentication flow. If it is configured on your Developer Org, you will be prompted to perfrom  Multi Factor Authentication.

You can login with the same account that you created when signing up for your Developer Org, or you can use a known username and password from your Okta Directory.

After you complete the login flow, you will be able to see details of user's account.

[OIDC Native iOS Application Setup Instructions]: https://developer.okta.com/quickstart/#/ios/nodejs/express
