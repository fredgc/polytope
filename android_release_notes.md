# BIOS Virtualization & Android Release Continuation Notes

## 1. How to Enable Hardware Virtualization (Intel VT-x) in BIOS on `raven`

-   **Motherboard**: ASUS PRIME Z390-A (American Megatrends UEFI BIOS)

-   **CPU**: Intel Core i7-9700K

### Steps to Enable Intel VT-x:

1.  Reboot directly into the UEFI BIOS setup from Linux (or press **Del** /
    **F2** repeatedly during startup):

    ``` bash
    systemctl reboot --firmware-setup
    ```

2.  Once in the ASUS UEFI BIOS Utility, press **F7** to switch from **EZ Mode**
    to **Advanced Mode** (if not already in Advanced Mode).

3.  Select the **Advanced** tab at the top of the screen.

4.  Open **CPU Configuration**.

5.  Scroll down to **Intel (VMX) Virtualization Technology** and change it from
    **Disabled** to **Enabled**.

6.  *(Optional)* Return to the **Advanced** tab, open **System Agent (SA)
    Configuration**, and set **VT-d** to **Enabled**.

7.  Press **F10** to **Save Changes & Reset** (confirm **OK**), and let the
    machine boot back into Linux.

8.  After logging back in, verify KVM is active:

    ``` bash
    ls -l /dev/kvm
    lscpu | grep -i virt
    ```

    You should see `/dev/kvm` present and `Virtualization: VT-x`.

-------------------------------------------------------------------------------

## 2. Current Progress on TODO `[1]` (`android-build`)

Completed so far:

-   **Gradle / AGP / Kotlin & Release Signing**:

    -   `android/app/build.gradle.kts` is configured to sign release builds
        using `~/.android/upload-keystore.jks` (`alias = "gchouse-upload"`) via
        `KEYSTORE_PW` or `~/.android/key.properties`, with fallback to `debug`.

    -   `Makefile` includes `apk`, `apk-release`, `aab`, and
        `play-store-assets` targets.

-   **Play Store Graphics & Phone Screenshots (`play_store_images/`)**:

    -   `play_store_images/icon_512.png` (`512x512`, 24-bit RGB PNG)

    -   `play_store_images/feature_graphic_1024x500.png` (`1024x500`, 24-bit
        RGB PNG)

    -   `play_store_images/phone_01.png` (`1080x1920`, 24-bit RGB PNG)

    -   `play_store_images/phone_02.png` (`1080x1920`, 24-bit RGB PNG)

-   **Android Emulator System Image**:

    -   Downloaded and unpacked
        `system-images;android-36.1;google_apis_playstore;x86_64` into
        `~/tools/android-sdk/system-images/` for AVD `Medium_Phone_API_36.1`.

-   **Script Fix**:

    -   Fixed `trap` cleanup of `tmp_png` in `~/bin/android-screenshots` under
        `set -u`.

-------------------------------------------------------------------------------

## 3. Remaining Steps After Reboot

### Step A: Start the Emulator and Capture Tablet Screenshots

1.  Start the `Medium_Phone_API_36.1` emulator:

    ``` bash
    ANDROID_SDK_ROOT=$HOME/tools/android-sdk \
      ~/tools/android-sdk/emulator/emulator -avd Medium_Phone_API_36.1 &
    ```

2.  Wait for boot, install the release APK, and set `tablet7` size
    (`1200x1920 @ 320 dpi`):

    ``` bash
    adb -s emulator-5554 wait-for-device
    android-screenshots -s emulator-5554 size tablet7
    android-screenshots -s emulator-5554 demo-on
    adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-release.apk
    adb -s emulator-5554 shell monkey -p org.gchouse.polytope2 \
      -c android.intent.category.LAUNCHER 1
    ```

3.  Position the polytope interactively in the emulator and capture two 7-inch
    tablet screenshots:

    ``` bash
    android-screenshots -s emulator-5554 capture tablet7_01
    android-screenshots -s emulator-5554 capture tablet7_02
    ```

4.  Switch the emulator to `tablet10` size (`1600x2560 @ 320 dpi`) and capture
    two 10-inch tablet screenshots:

    ``` bash
    android-screenshots -s emulator-5554 size tablet10
    android-screenshots -s emulator-5554 capture tablet10_01
    android-screenshots -s emulator-5554 capture tablet10_02
    ```

5.  Reset emulator display size and exit demo mode:

    ``` bash
    android-screenshots -s emulator-5554 size reset
    android-screenshots -s emulator-5554 demo-off
    ```

### Step B: Monotonic `versionCode` for Android / Google Play

-   `roll_build_number.sh --release` resets `+BUILD` in `pubspec.yaml` to `+0`
    (e.g., `2.2.0+9` -\> `2.2.1+0` -\> `2.2.2+0`), which causes Flutter to set
    `flutter.versionCode = 1` and triggers `INSTALL_FAILED_VERSION_DOWNGRADE`
    on devices or Google Play when a previous build had `versionCode = 7`.

-   Before building the release `.aab`, either compute a monotonic
    `versionCode` from `MAJOR.MINOR.PATCH+BUILD` in
    `android/app/build.gradle.kts` or ensure `+BUILD` in `pubspec.yaml` is
    strictly greater than any previously installed or uploaded `versionCode`.

### Step C: Build & Verify Signed Release Bundle (`.aab`)

1.  Build the signed `.aab` and verify its certificate:

    ``` bash
    make aab
    keytool -printcert \
      -jarfile build/app/outputs/bundle/release/app-release.aab \
      | grep -E "Owner:|SHA1:|SHA256:"
    ```

2.  Mark TODO item `[1]` done (`~/bin/todo.py done 1`).
