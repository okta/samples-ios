# Okta iOS Browser Sign In and Biometric storage Example

This example shows you how to use the [Okta Auth](https://github.com/okta/okta-sdk-appauth-ios) to adopt Okta Authentication flow in your app as well as saving sensitive data behind biometric factor


## Prerequisites

Before running this sample, you will need the following:

* iPhone 6 or higher device with enrolled touchId/faceId factors.
* Open [Okta App Auth readme.md](https://github.com/okta/samples-ios/blob/master/browser-sign-in/README.md) file and follow the instructions how to install dependencies and do required configuration.


## Running This Example

To run this application, you first need to clone this repo and then enter into this directory:

```bash
git clone https://github.com/okta/samples-ios.git
cd browser-sign-in-and-biometric-storage/
```

Dependencies in this sample utilizes Swift Package Manager, so dependencies should be installed automatically.

## Scenarios
1. Sign in with the test user credentials
2. Press **tokens** button
3. Use touchId/faceId to read token's data from keychain

Or

1. Sign in with the test user credentials
2. Restart application
3. Use touchId/faceId to read token's data from keychain

