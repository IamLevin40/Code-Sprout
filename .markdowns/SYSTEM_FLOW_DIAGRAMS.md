# System Flow Diagrams

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Code Sprout App                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐      ┌──────────────┐      ┌───────────┐ │
│  │  Login/Home  │─────→│ Firestore    │─────→│ User Data │ │
│  │    Pages     │      │  Service     │      │   Model   │ │
│  └──────────────┘      └──────────────┘      └───────────┘ │
│         │                      │                     │       │
│         │                      ↓                     │       │
│         │              ┌──────────────┐              │       │
│         │              │   Local      │              │       │
│         └─────────────→│  Storage     │←─────────────┘       │
│                        │  Service     │                      │
│                        └──────────────┘                      │
│                               │                              │
└───────────────────────────────┼──────────────────────────────┘
                                ↓
                    ┌──────────────────────┐
                    │ Flutter Secure       │
                    │ Storage              │
                    │ (Encrypted)          │
                    └──────────────────────┘
                                ↓
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
   ┌────▼────┐            ┌────▼────┐            ┌────▼────┐
   │ Android │            │   iOS   │            │ Windows │
   │ Keystore│            │ Keychain│            │  DPAPI  │
   └─────────┘            └─────────┘            └─────────┘
```

## Login & Data Loading Flow

```
User Opens App
      │
      ▼
┌─────────────┐
│ Auth Check  │
└─────┬───────┘
      │
      ├──[Not Logged In]──→ Login Page
      │
      └──[Logged In]────→ Home Page
                              │
                              ▼
                    ┌──────────────────┐
                    │ Load User Data   │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │ Check Local      │
                    │ Cache            │
                    └────────┬─────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
        [Cache Hit]                   [Cache Miss]
              │                             │
              ▼                             ▼
    ┌──────────────────┐          ┌──────────────────┐
    │ Return Cached    │          │ Fetch from       │
    │ Data (~5ms)      │          │ Firestore        │
    └────────┬─────────┘          │ (~500ms)         │
             │                    └────────┬─────────┘
             │                             │
             │                             ▼
             │                    ┌──────────────────┐
             │                    │ Cache Result     │
             │                    └────────┬─────────┘
             │                             │
             └──────────┬──────────────────┘
                        │
                        ▼
              ┌──────────────────┐
              │ Display User     │
              │ Data in UI       │
              └──────────────────┘
```

## Update Data Flow

```
User Updates Data (e.g., Username Change)
              │
              ▼
    ┌──────────────────┐
    │ Create Updated   │
    │ UserData Object  │
    └────────┬─────────┘
             │
             ▼
    ┌──────────────────┐
    │ Call             │
    │ updateUserData() │
    └────────┬─────────┘
             │
      ┌──────┴──────┐
      │             │
      ▼             ▼
┌──────────┐  ┌──────────┐
│ Update   │  │ Update   │
│ Cache    │  │ Firestore│
│ (~5ms)   │  │ (async)  │
└─────┬────┘  └────┬─────┘
      │            │
      ▼            │
┌──────────┐       │
│ Update   │       │
│ UI       │       │
│ Instantly│       │
└──────────┘       │
                   ▼
            ┌──────────┐
            │ Confirm  │
            │ Synced   │
            └──────────┘
```

## Logout & Cache Clear Flow

```
User Clicks Logout
      │
      ▼
┌─────────────────┐
│ Show Confirm    │
│ Dialog          │
└────────┬────────┘
         │
    [Confirmed]
         │
         ▼
┌─────────────────┐
│ AuthService     │
│ signOut()       │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌──────────┐
│ Clear  │ │ Firebase │
│ Local  │ │ Sign Out │
│ Cache  │ └──────────┘
└────┬───┘
     │
     ▼
┌─────────────────┐
│ Navigate to     │
│ Login Page      │
└─────────────────┘
```

## Offline Operation Flow

```
User Opens App (No Internet)
      │
      ▼
┌─────────────────┐
│ Navigate to     │
│ Home Page       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Request User    │
│ Data            │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Check Cache     │
└────────┬────────┘
         │
    [Cache Hit]
         │
         ▼
┌─────────────────┐
│ Return Cached   │
│ Data            │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Display in UI   │
│ (Offline Mode)  │
└─────────────────┘
```

## First-Time vs Returning User

```
┌──────────────────────────────────────────────────────────┐
│                    First-Time User                        │
├──────────────────────────────────────────────────────────┤
│                                                           │
│ Register → Create Account → Create Firestore Document    │
│              │                      │                     │
│              ▼                      ▼                     │
│         Navigate Home         Fetch & Cache              │
│              │                      │                     │
│              └──────────┬───────────┘                     │
│                         ▼                                 │
│                   Display Data                            │
│                   (~500ms load)                           │
│                                                           │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│                   Returning User                          │
├──────────────────────────────────────────────────────────┤
│                                                           │
│ Login → Auth Success → Navigate Home                     │
│              │              │                             │
│              ▼              ▼                             │
│         Check Cache    Load from Cache                   │
│              │              │                             │
│         [Cache Hit] ────────┘                             │
│              │                                            │
│              ▼                                            │
│         Display Data                                      │
│         (~5ms load) ← 100x Faster!                       │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

## Security Layers

```
┌────────────────────────────────────────────────────────┐
│                     Application Layer                   │
│  ┌──────────────────────────────────────────────────┐  │
│  │         UserData Model (Plain Dart Objects)      │  │
│  └───────────────────┬──────────────────────────────┘  │
│                      │                                  │
├──────────────────────┼──────────────────────────────────┤
│                      ▼                                  │
│              Service Layer                              │
│  ┌──────────────────────────────────────────────────┐  │
│  │   LocalStorageService (Encryption Interface)     │  │
│  └───────────────────┬──────────────────────────────┘  │
│                      │                                  │
├──────────────────────┼──────────────────────────────────┤
│                      ▼                                  │
│         Flutter Secure Storage Layer                    │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Platform Channel + Encryption            │  │
│  └───────────────────┬──────────────────────────────┘  │
│                      │                                  │
├──────────────────────┼──────────────────────────────────┤
│                      ▼                                  │
│              Platform Native Layer                      │
│  ┌─────────────┬──────────────┬─────────────────────┐  │
│  │   Android   │     iOS      │  Windows/Linux      │  │
│  │  Keystore   │   Keychain   │      DPAPI          │  │
│  │   (AES)     │ (Hardware)   │   (System API)      │  │
│  └─────────────┴──────────────┴─────────────────────┘  │
│                      │                                  │
└──────────────────────┼──────────────────────────────────┘
                       ▼
              ┌────────────────┐
              │ Encrypted File │
              │   on Disk      │
              └────────────────┘
```

## Cache Lifecycle

```
User Logs In
     │
     ▼
┌──────────┐
│  Empty   │
│  Cache   │
└────┬─────┘
     │
     ▼ [Fetch Data]
┌──────────┐
│  Cache   │
│ Populated│
└────┬─────┘
     │
     ├───[Read Operations]──→ Return from Cache (Fast!)
     │
     ├───[Update Operations]──→ Update Cache + Firestore
     │
     ├───[Force Refresh]──→ Re-fetch from Firestore
     │
     └───[Logout]──→ Clear Cache
              │
              ▼
         ┌──────────┐
         │  Empty   │
         │  Cache   │
         └──────────┘
```

## Performance Comparison

```
Without Caching:
┌─────────────────────────────────────────────────┐
│ Request → Firestore → Network → Response        │
│                                                  │
│ Time: 100-500ms per request                     │
│ Cost: 1 read per request                        │
│                                                  │
│ Daily: 10 requests × 500ms = 5 seconds          │
│        10 reads per user                        │
└─────────────────────────────────────────────────┘

With Caching:
┌─────────────────────────────────────────────────┐
│ First:   Request → Firestore → Cache → Response │
│          (100-500ms, 1 read)                     │
│                                                  │
│ After:   Request → Cache → Response              │
│          (5-20ms, 0 reads) ← 25-100x Faster!    │
│                                                  │
│ Daily: 1 request × 500ms + 9 requests × 10ms    │
│        = 590ms total (89% faster!)              │
│        1 read per user (90% cost reduction!)    │
└─────────────────────────────────────────────────┘
```

---

## Legend

- `→` : Synchronous flow
- `↓` : Data/control flow
- `┌─┐` : Component/Process
- `[...]` : Condition/State
- `~Xms` : Approximate time
