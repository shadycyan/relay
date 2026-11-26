# RELAY — cyberpunk sms client (flutter, android)

## setup
```bash
flutter create --org com.nightcity --project-name msgs relay
cd relay
flutter pub add google_fonts permission_handler
# copy this folder's lib/ and android/ over the generated ones (overwrite)
flutter run            # real phone, not emulator-with-no-sim if you can help it
```
package must end up as `com.nightcity.msgs` (the --org/--project-name above does that).
if gradle can't find `androidx.core`, add `implementation("androidx.core:core-ktx:1.13.1")` to android/app/build.gradle(.kts) dependencies.

## becoming the default sms app
open app -> grant perms -> tap SET in the red banner -> accept the system dialog.
until then it can read + send, but can't receive/store.

## what works
- thread list w/ contact names, unread counts, pull-to-refresh
- chat view, send (multipart ok), mark-as-read
- incoming sms (as default app) -> stored + notification + live ui refresh
- sms:/smsto: links, notification tap -> opens thread, "reply with message" from dialer

## not yet
- mms (receiver is a stub), delivery/failed status, search, delete, dual-sim picker
- group threads show only first address
- fonts via google_fonts need internet on first launch (bundle Rajdhani under assets/ to go offline)

## builds
every push to `master` builds `relay.apk` in github actions (`.github/workflows/build-apk.yml`):
- **permanent link** (no login, open it on the phone):
  `https://github.com/shadycyan/relay/releases/download/latest/relay.apk`
- **per-run artifact**: actions tab -> latest run -> artifacts (needs a github login, expires after 90 days)
- tag a commit (`git tag v1.0.0 && git push --tags`) for a versioned release

every build ships a `SHA256SUMS` file next to the apk; check it with `sha256sum -c SHA256SUMS`.

signing: builds use the throwaway debug key unless you add a real keystore, which
means a new apk won't install over an older one. to fix that once:

```bash
keytool -genkeypair -v -keystore relay-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias relay
base64 -w0 relay-release.jks        # paste into the ANDROID_KEYSTORE_BASE64 secret
```

then add these repo secrets (settings -> secrets and variables -> actions):
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` (`relay`), `ANDROID_KEY_PASSWORD`.
keep `relay-release.jks` backed up — losing it means users must uninstall to upgrade.

## telegram plan
add a `Channel` interface (threads(), messages(), send(), events) with SmsChannel (current bridge) and TgChannel (tdlib).
ui only talks to Channel, merges threads sorted by date, HudTag shows SMS/TG.
