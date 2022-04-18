# Okta iOS Browser Sign In Example

This example shows you how to use the [Okta Auth](https://github.com/okta/okta-sdk-appauth-ios) to adopt Okta Authentication flow in your app. The login is achieved through the [Authorization Code Flow], where the user is redirected to the Okta-Hosted login page.  After the user authenticates, they are redirected back to the application.


## Prerequisites

Before running this sample, you will need the following:

* An Okta Developer Account, you can sign up for one at https://developer.okta.com/signup/.
* An Okta Application, configured for iOS client. This is done from the Okta Developer Console and you can find instructions [here][OIDC Native iOS Application Setup Instructions].  When following the wizard, use the default properties.  They are designed to work with our sample applications.


## Running This Example

To run this application, you first need to clone this repo and then enter into this directory:

```bash
git clone https://github.com/okta/samples-ios.git
cd browser-sign-in/
```

Dependencies in this sample utilizes Swift Package Manager, so dependencies should be installed automatically.

You need to gather the following information from the Okta Developer Console:

- **Client ID**, **Redirect URI**, **Logout redirect URI** - This can be found on the "General" tab of an application, you want to get this for the Web application that you created earlier.
Documentation overview is [here](https://developer.okta.com/docs/guides/find-your-app-credentials/overview/)

- **Issuer** - This is the URL of the authorization server that will perform authentication.  All Developer Accounts have a "default" authorization server.  The issuer is a combination of your Org URL (found in the upper right of the console home page) and `/oauth2/default`. For example, `https://dev-1234.oktapreview.com/oauth2/default`.
Documentation overview is [here](https://developer.okta.com/docs/guides/find-your-domain/overview/)

Now place these values into the file `OktaBrowserSignIn/Okta.plist`:

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
    <key>logoutRedirectUri</key>
    <string>{logoutRedirectUri}</string>
</dict>
</plist>

```

In order to redirect back to your application from a web browser, you must specify a unique URI to your app. To do this, open `Info.plist` in your application bundle and set a **URL Scheme** to the scheme of the redirect URI.

For example, if your **Redirect URI** is `com.okta.example:/callback`, the **URL Scheme** will be `com.okta.example`.

Now you can build and run the application.

If you see a home page that prompts you to login, then things are working!  Clicking the **Log in** button will redirect you to the Okta hosted sign-in page. You will be guided through Okta Authentication flow. After completion you will be redirected back to the app.

You can login with the same account that you created when signing up for your Developer Org, or you can use a known username and password from your Okta Directory.

[OIDC Native iOS Application Setup Instructions]: https://developer.okta.com/quickstart/#/ios/nodejs/express
