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

## telegram plan
add a `Channel` interface (threads(), messages(), send(), events) with SmsChannel (current bridge) and TgChannel (tdlib).
ui only talks to Channel, merges threads sorted by date, HudTag shows SMS/TG.
