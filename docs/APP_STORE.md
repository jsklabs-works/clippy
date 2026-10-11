# Mac App Store submission checklist

## 1. Accounts and identifiers

- [ ] Enroll in the [Apple Developer Program](https://developer.apple.com/programs/)
      ($99/year). You can enroll as an individual or an organization. An
      organization enrollment needs a D-U-N-S number and shows the company
      name as the seller.
- [ ] In **Certificates, Identifiers & Profiles**, register an App ID that
      matches `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml`
      (`com.jsklabs.Clippy`). Xcode's automatic signing can also create it.
- [ ] Put your Team ID in `DEVELOPMENT_TEAM` in `project.yml`.
- [ ] In [App Store Connect](https://appstoreconnect.apple.com), go to
      **My Apps › + › New App**, choose the macOS platform, pick the bundle
      ID, and reserve the name. Names are globally unique, so if "Clippy"
      is taken, change `CFBundleDisplayName` and the product name to match.

## 2. Requirements this project already meets

| Requirement | Where |
|---|---|
| App Sandbox enabled | `project.yml` › entitlements |
| Hardened runtime | `ENABLE_HARDENED_RUNTIME` |
| No network, no tracking | No network entitlement; `PrivacyInfo.xcprivacy` declares nothing collected |
| Privacy manifest with required-reason APIs | `App/Resources/PrivacyInfo.xcprivacy` (UserDefaults: CA92.1) |
| Doesn't launch at login without consent (guideline 2.4.5) | Off by default; toggled by the user in Settings through `SMAppService` |
| Export compliance | `ITSAppUsesNonExemptEncryption = NO` |
| Category | `public.app-category.productivity` |

## 3. Review risks and how to handle them

**Auto-paste uses Accessibility.** Posting a synthetic ⌘V requires the user
to grant Accessibility access. That works in a sandboxed app, and other
clipboard managers on the store use the same approach, but reviewers
sometimes question it. To keep the risk down:

- Keep auto-paste **off by default**. The app is fully usable without it,
  since choosing an item still copies it.
- Request Accessibility only when the user turns auto-paste on (this is
  how the code works now).
- In **App Review Information › Notes**, add something like:

  > Clippy is a clipboard history manager. Accessibility access is
  > optional and is requested only if the user enables "Paste automatically"
  > in Settings. It is used solely to send ⌘V to the frontmost app after the
  > user picks an item from their history. To test: copy a few items, press
  > ⇧⌘C, and choose one. To test auto-paste, enable it in Settings and grant
  > access when prompted.

If review rejects auto-paste, ship without it first and add it in an update.
The toggle and prompt are confined to `SettingsView` and `PasteService`.

**Clipboard privacy.** Newer macOS releases have been adding user controls
over apps that read the pasteboard. Test on the current macOS release and on
any beta before submitting, and if the system asks the user for permission,
show your own explanation first (for example in an onboarding window).

**The name "Clippy".** Many people know it as Microsoft's Office
assistant, and Microsoft has reused it in recent products. App Review can
reject names that suggest an association with another company (guidelines
4.1 and 5.2), and a trademark holder can file a complaint later. To lower
the risk, avoid paperclip artwork and any reference to Microsoft or Office,
and consider a distinct store name such as "Clippy – Clipboard History" or a
different name altogether. The display name lives in `CFBundleDisplayName`
in `project.yml`, so changing it later is a small edit.

**Maccy.** Maccy is MIT-licensed, and this project is an original
implementation. Don't use Maccy's name, icon, or screenshots in your listing.
If you ever copy Maccy source code, keep its MIT copyright notice.

**Minimum functionality (guideline 4.2).** Clipboard managers are an
established category, so stand out with your listing and quality. A
differentiator in a later version (snippets, iCloud sync, paste stack) also
helps.

## 4. Store listing

- [ ] **App icon**: a 1024×1024 master plus all Mac sizes in `AppIcon.appiconset`
- [ ] **Screenshots**: 16:10, at one of 1280×800, 1440×900, 2560×1600 or
      2880×1800. Show the popup over a real app, search, pinned items, and
      Settings. Up to 10.
- [ ] **Subtitle** (30 characters), for example "Clipboard history, instantly"
- [ ] **Description and keywords** (100 characters for keywords), for example
      clipboard, history, paste, copy, manager, snippets, menu bar
- [ ] **Privacy policy URL**, required even though no data is collected. A
      simple page saying "All data stays on your Mac; nothing is collected
      or transmitted" is enough.
- [ ] **Support URL**, which can be a GitHub page or a simple website
- [ ] **App Privacy questionnaire**: answer **Data Not Collected**
- [ ] **Age rating**: complete the questionnaire (likely 4+)
- [ ] **Price**: free, paid, or free with an in-app purchase. Maccy is
      free and open source, so a paid app needs a clear reason to choose it.

## 5. Build, test, and upload

1. Bump `MARKETING_VERSION` (user-facing) and `CURRENT_PROJECT_VERSION`
   (must increase on every upload) in `project.yml`, then run `xcodegen`.
2. In Xcode, choose **Product › Archive**.
3. In **Organizer**, choose **Distribute App › App Store Connect › Upload**.
4. Optionally test through **TestFlight**, which supports macOS apps.
5. In App Store Connect, attach the build to the version, fill in the review
   notes from section 3, and choose **Submit for Review**.

Reviews usually take a day or two. If the app is rejected, the message cites
a guideline number; reply in Resolution Center or fix it and resubmit.
