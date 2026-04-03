# Navigation and UI Map

## Screens and Routes

The app uses **imperative navigation** (no named routes, no router). All navigation is via `Navigator.push()` or `Navigator.pushReplacement()`.

### Entry Point Flow

```
main() → Firebase.initializeApp() → MyApp()
  └── StreamBuilder(FirebaseAuth.authStateChanges)
        ├── No user → PhoneAuthPage
        └── User exists → FutureBuilder(DatabaseHelper.checkUserStatus)
              ├── errorState    → AlasPage (contact support)
              ├── notRegistered → RegistrationPage
              ├── firstPaymentPending → PaymentGateway(isFirstPayment: true)
              ├── paymentPending → PaymentGateway(isFirstPayment: false)
              ├── active → HomeScreen
              ├── noInternet → AlasInternetPage
              └── apkKilled → AlasPage (update message)
```

### Navigation Graph

```
PhoneAuthPage ──(auto on auth)──► main() re-evaluates StreamBuilder
RegistrationPage ──(pushReplacement)──► PaymentGateway
PaymentGateway ──(pushReplacement)──► HomeScreen
HomeScreen ──(push)──► ProfilePage ──(pop)──► HomeScreen
```

### Deep Links
None implemented.

## Screen Details

### 1. PhoneAuthPage (`lib/UI/auth/phone_auth_page.dart`)

| Element | Detail |
|---|---|
| Purpose | Phone number OTP authentication via Firebase |
| Inputs | Phone number (prefilled with +91), OTP code |
| State | `_codeSent`, `_loading`, `_error`, `_verificationId` |
| Navigation out | Auto-navigates via `StreamBuilder` in `main.dart` on successful sign-in |
| Accessibility | Haptic feedback on button presses; SnackBar messages for success/error |

### 2. RegistrationPage (`lib/UI/RegisterPage/registration_page.dart`)

| Element | Detail |
|---|---|
| Purpose | New user registration |
| Tabs | "Single User" (index 0) and "Organization" (index 1) |
| Fields | Name, Phone (pre-filled), Age, Gender (dropdown), Occupation, Referral Key (org only) |
| Org flow | Enter referral key → "Verify" → `DatabaseHelper.verifyReferralKey()` |
| Submit | `DatabaseHelper.createUser()` → navigate to `PaymentGateway` |
| Accessibility | Haptic feedback on validation errors and successful submission |

### 3. PaymentGateway (`lib/Payment/payment_gatway.dart`)

| Element | Detail |
|---|---|
| Purpose | Subscription payment via Razorpay |
| Plans displayed | First payment: first month free + 3/6/12 months. Renewal: 1 + 3/6/12 months. |
| Prices | Fetched from Firestore `PaymentCost` collection; falls back to hardcoded defaults |
| Razorpay options | UPI, cards, netbanking (EMI/wallet/paylater hidden) |
| On success | `DatabaseHelper.setSubscriptionInformation()` → navigate to `HomeScreen` |
| On ₹1 (free trial) | Directly activates without Razorpay |

### 4. HomeScreen (`lib/UI/home_Screen.dart`)

The main interaction screen. Layout:

```
┌──────────────────────────────────────────┐
│ AppBar: [Logo] "Letsee"      [Settings]  │
├──────────────────────────────────────────┤
│                                          │
│  ┌────┐                          ┌────┐  │
│  │    │                          │    │  │
│  │ R  │    Camera Preview /      │ S  │  │
│  │ e  │    Uploaded Image        │ m  │  │
│  │ a  │                          │ a  │  │
│  │ d  │    (tap to clear image)  │ r  │  │
│  │ e  │                          │ t  │  │
│  │ r  │                          │    │  │
│  │    │                          │ V  │  │
│  │ M  │                          │ i  │  │
│  │ o  │                          │ e  │  │
│  │ d  │                          │ w  │  │
│  │ e  │                          │    │  │
│  └────┘                          └────┘  │
│                                    55%h  │
├──────────────────────────────────────────┤
│                                          │
│  ┌──────────────┐ │ ┌──────────────┐     │
│  │   Green Mic   │ │ │  Yellow Mic  │     │
│  │ (Chat History)│ │ │ (Image Ask)  │     │
│  │               │ │ │  Long-press  │     │
│  │               │ │ │  = Video     │     │
│  └──────────────┘ │ └──────────────┘     │
│                                    ~25%h │
├──────────────────────────────────────────┤
│  [Copy Response] (shown when response)   │
└──────────────────────────────────────────┘
```

| Element | Widget | Behavior |
|---|---|---|
| Camera preview | `ImagePreview` | Shows live camera or uploaded image (green border) |
| Tap on preview | `InkWell` | Clears uploaded image buffer |
| Left sidebar | `SideBarButton` "Reader Mode" | Activates Auto Reading Mode → captures + processes |
| Right sidebar | `SideBarButton` "Smart View Mode" | Activates Smart View Mode → captures + processes |
| Green mic (left) | `MicButton` + `InkWell` | Sets history mode → starts listening |
| Yellow mic (right) | `MicButton` + `GestureDetector` | Tap: unset history → capture image → start listening. Long-press: video recording (max 7s) |
| Copy Response button | `ElevatedButton.icon` | Copies `agentResponse` to clipboard |
| Settings icon | `IconButton` (AppBar) | Navigates to `ProfilePage` |

**Mic Button States:**

| State | Icon | Color |
|---|---|---|
| idle | `Icons.mic` | Base color (green/yellow) |
| listening | `Icons.mic_off` | White |
| processing | `Icons.loop` | White |
| speaking | `Icons.pause` | White |
| videoRecording | `Icons.play_arrow` | White |

### 5. ProfilePage (`lib/UI/profile_page.dart`)

| Element | Detail |
|---|---|
| Purpose | Configure user preferences |
| Fields | Emergency contact, Speech rate (0.25–2.0), Input language, Enable translation, Use front camera |
| Persistence | All saved to `SharedPreferences` |
| Navigation | Push from HomeScreen; pop on save |
| Post-pop | HomeScreen re-initializes camera and re-initializes agent with new settings |

### 6. AlasPage (`lib/UI/RegisterPage/AlasPage.dart`)

| Element | Detail |
|---|---|
| Purpose | Display error messages (contact support, killed APK, generic errors) |
| Style | Gold background (#FCB853), white card with error icon, message |
| Inputs | `title` and `message` strings |

### 7. AlasInternetPage (`lib/UI/RegisterPage/AlasInternet.dart`)

Extends `AlasPage` with fixed title "Internet Connection Error" and message about checking internet.

## Back Navigation Behavior

| Screen | Back Behavior |
|---|---|
| HomeScreen | System back exits app (it's the root for active users) |
| ProfilePage | Pops to HomeScreen |
| RegistrationPage → PaymentGateway | `pushReplacement` — no back to registration |
| PaymentGateway → HomeScreen | `pushReplacement` — no back to payment |
| AlasPage / AlasInternetPage | Terminal — user must restart app |

## Widget Composition

### MicButton
Stateless circle with dynamic icon/color based on `ConversationState`. Wrapped in `Semantics` with dynamic label.

### SideBarButton
Stateless translucent strip on camera preview edges. Uses `ClipRRect` + `BackdropFilter` for blur effect. Text is rotated 90° (`RotatedBox`).

### ImagePreview
Displays either uploaded `Image.memory` (with green border) or live `CameraPreview` (fitted to fill).
