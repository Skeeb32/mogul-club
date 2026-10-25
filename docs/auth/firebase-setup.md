# Firebase Authentication setup

The signed-out and sign-up views are implemented with Firebase Authentication behind a SwiftUI auth manager. With no Firebase configuration, provider actions remain disabled, the user remains signed out, and the read-only synthetic demo is still available. No credentials or fabricated sessions are bundled.

## Firebase client and providers

1. Create or select the Firebase project that owns the Mogul Club app. Register the iOS app with the unchanged bundle ID `Mogul.Mogul-Club`.
2. Download that app's `GoogleService-Info.plist` into `Mogul Club/GoogleService-Info.plist`. It is git-ignored. The root Xcode target copies it into the app bundle when present.
3. In Firebase Console > Authentication > Sign-in method, enable Email/Password, Apple, and Google. Gmail accounts use Firebase's Google provider; there is no separate Gmail sign-in provider. Configure an approved email verification action URL/template and password policy. Authentication sends reset and verification links through Firebase; the app never stores passwords.
4. In Apple Developer, enable the Sign in with Apple capability for the app identifier. Keep the `Default` entitlement in `Mogul Club/Mogul_Club.entitlements`. Configure the matching Apple provider/service ID, team ID, key ID, and private key in Firebase Console; keep the private key in Firebase, never in this repository. If using Hide My Email, configure Firebase’s sender address with Apple’s private email relay so verification and reset mail can reach relay addresses.
5. In Google Cloud Console, configure the iOS OAuth client for the same bundle ID. Copy the `REVERSED_CLIENT_ID` value from the Firebase plist into the app target's URL Types. The app already forwards callback URLs to Google Sign-In. Use Firebase's web OAuth client as the Firebase Google provider configuration.
6. Set approved Mogul Club privacy and terms destinations before production. The current links point to the Mogul platform's live policy pages; product/legal owners must confirm those policies govern this native app and approve the signup acknowledgment text.

## Backend token verification

The NestJS API uses Firebase Admin SDK on private routes. Set `FIREBASE_PROJECT_ID` to the Firebase project ID and configure Application Default Credentials for the API runtime (for local development, use Google's `gcloud auth application-default login`; in deployment, use the platform's workload identity). Do not put service-account JSON in the iOS app, `.env.example`, or Git. The verifier checks token signature, audience/issuer through Firebase Admin, expiry and revocation, and requires a verified email. Requests without a valid token receive 401. `@Public()` stays limited to health and the synthetic discovery routes. Add explicit server-side resource permissions as private account endpoints are introduced.

The iOS Firebase ID token must be sent as `Authorization: Bearer <ID token>` on future authenticated API calls. The current app has no private investor-data endpoints. Property discovery remains intentionally public and synthetic.

## Account lifecycle

Email signup requires a name, valid email, eight-character minimum password, matching confirmation, and a required legal acknowledgment. Firebase sends verification; unverified email/password users stay on the verification screen. Reset uses Firebase's expiring email action link. Email, Apple (with a random hashed nonce), and Gmail accounts through Google sign-in establish Firebase sessions. The Firebase listener restores sessions; email passwords are not written to local storage. Google/Apple account linking is not exposed.

Account deletion requires explicit confirmation and calls Firebase user deletion; Firebase may require a recent reauthentication, which is surfaced to the user. The current demo stores no per-user application records. Before adding user data, implement a backend deletion workflow that removes or retains records according to approved retention policy, and require provider-specific reauthentication before completing deletion.

## Local testing

Without a Firebase plist or Apple/Google OAuth setup, the app displays setup instructions and keeps all sign-in actions unavailable. Unit and UI tests cover validation, no-fake-session behavior, auth-entry presentation, and the existing public demo navigation. Test real provider callbacks only with a dedicated Firebase development project and its own authorized test accounts.
