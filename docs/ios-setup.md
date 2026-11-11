# iOS setup

Module 07. The steps below need a Mac with Xcode, an Apple Developer
account and access to the Firebase console. What could be done from the
repository has been; everything here is left.

## Done in the repository

- `ios/Runner/Info.plist` carries the camera and photo library usage
  strings, and `remote-notification` in `UIBackgroundModes`.
- `ios/Runner/Runner.entitlements` declares `aps-environment`.

## Still to do, on a Mac

1. **`GoogleService-Info.plist`.** Download it from the Firebase console
   (Project settings, the iOS app `com.deepfitness.app`) and save it to
   `ios/Runner/GoogleService-Info.plist`. Then add it to the Runner target
   in Xcode — dropping it in the folder is not enough; it has to be in
   "Copy Bundle Resources" or Firebase will not find it at runtime.

2. **Entitlements on the target.** In Xcode, Runner target, Signing &
   Capabilities, add **Push Notifications**. Check that Build Settings
   points `CODE_SIGN_ENTITLEMENTS` at `Runner/Runner.entitlements` for
   both Debug and Release.

3. **APNs key.** In the Apple Developer portal create an APNs auth key
   (.p8), then upload it in the Firebase console under Project settings,
   Cloud Messaging, with the Key ID and your Team ID. Without this,
   pushes to iOS fail silently — the send succeeds and nothing arrives.

4. **Phone auth reCAPTCHA fallback.** Open the downloaded
   `GoogleService-Info.plist`, copy `REVERSED_CLIENT_ID`, and add it to
   `Info.plist` as a URL scheme:

   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>PASTE_REVERSED_CLIENT_ID_HERE</string>
       </array>
     </dict>
   </array>
   ```

   This is not in the repository because the value is specific to the
   Firebase project and the plist does not exist yet. Phone sign-in on a
   device without silent-push support falls back to a reCAPTCHA in a web
   view, and without the scheme the member never comes back to the app.

5. **Layout check** from iPhone SE through Pro Max, including the notch
   safe areas. Every screen is already inside a `SafeArea`, but this has
   never been run on a device.

6. **Apple sign-in** is only required if another social login is added.
   None is, so nothing to do today.

## Notes

- The Firebase project id is `deepfitess-app`, which is misspelled and
  cannot be renamed. If the project is going to be recreated, do it
  before the APNs key is uploaded, or it has to be done twice.
- `firebase_messaging` needs the iOS deployment target that the current
  Firebase SDK requires; if the Pod install complains, raise
  `IPHONEOS_DEPLOYMENT_TARGET` in the Xcode project and in `Podfile`.
