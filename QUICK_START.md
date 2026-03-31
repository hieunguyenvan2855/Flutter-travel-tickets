## 🚀 Quick Start Guide - Maps, GPS & IoT Features

### ⏱️ 5-Minute Setup

#### Step 1: Update pubspec.yaml Dependencies
```bash
cd c:\Cuoiky
flutter pub get
```

#### Step 2: Configure Google Maps API Keys

**Android (android/app/src/main/AndroidManifest.xml):**
```xml
<application>
  <meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_MAPS_API_KEY"/>
</application>
```

**iOS (ios/Runner/Info.plist):**
```xml
<key>com.google.ios.maps.API_KEY</key>
<string>YOUR_iOS_MAPS_API_KEY</string>
```

Get API keys from: https://console.cloud.google.com

#### Step 3: Configure Support Chat URLs

Edit `lib/views/home/tour_detail_screen.dart` lines 128-130:

```dart
// Change these to your company's contact info
if (platform == 'zalo') {
  url = 'https://zalo.me/0123456789?text=$msg';  // ← Replace phone number
} else if (platform == 'messenger') {
  url = 'https://m.me/your_page_id?text=$msg';   // ← Replace page ID
}
```

#### Step 4: Ensure Firebase Has Correct Path

Make sure your tours in Firebase have:
```
/tours/{tourId}
  ├── geoPoint (required for map)
  ├── title
  ├── location
  └── ... (other fields)
```

**Done! 🎉 Maps, GPS Check-in, and Support FAB are ready!**

---

### 🔊 Optional: Set Up IoT Speaker (15-20 minutes)

#### For ESP32 Setup:

1. **Install Arduino IDE** → https://www.arduino.cc/en/software

2. **Install ESP32 Board Support:**
   - File → Preferences → Additional Boards Manager URLs
   - Add: `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
   - Tools → Boards Manager → Search ESP32 → Install

3. **Install Libraries:**
   - Sketch → Include Library → Manage Libraries
   - Search and install:
     - `Firebase Realtime Database` (by Mobizt)
     - `ArduinoJson`
     - `AsyncTCP`

4. **Upload Code:**
   - Copy `iot/esp32_announcement_speaker.cpp` to Arduino IDE
   - Update WiFi settings (lines 19-20)
   - Update Firebase settings (lines 22-24)
   - Tools → Board → ESP32 Dev Module
   - Click Upload

5. **Connect Speaker:**
   - Wire I2S speaker to GPIO pins 25, 26, 27

**Done! Speaker system ready!**

#### For Python Controller:

1. **Install Python 3.8+**

2. **Install Dependencies:**
   ```bash
   cd iot
   pip install -r requirements.txt
   ```

3. **Get Firebase Credentials:**
   - Firebase Console → Project Settings → Service Accounts
   - Generate New Private Key → Save as `firebase_credentials.json`

4. **Run Controller:**
   ```bash
   python iot_speaker_controller.py
   ```

**Done! Now you can trigger announcements via Python!**

---

### 🧪 Quick Testing

#### Test Maps & GPS (In Flutter App):

1. Open tour detail screen
2. Scroll down to "ĐỊA ĐIỂM TOUR" section
3. Verify map displays with blue marker at destination
4. Check "Khoảng cách" shows distance (green = close, orange = far)
5. Click "CHECK-IN GPS" to test location tracking

#### Test Support FAB:

1. Tap the blue support icon (bottom right)
2. Click Zalo or Messenger
3. Should open app/browser with pre-filled message

#### Test ESP32 Speaker:

1. In Arduino IDE Serial Monitor, watch logs
2. In Python controller, select option 2 (Trigger announcement)
3. Select a tour
4. Observe: "✓ Announcement triggered"
5. Listen for speaker announcement

---

### 📊 Sample Test Data

#### Firebase Test Tour:
```json
{
  "tours": {
    "test_tour_001": {
      "id": "test_tour_001",
      "title": "Test Tour",
      "geoPoint": {
        "latitude": 21.0285,
        "longitude": 105.8542
      },
      "location": "Hà Nội",
      "description": "Test tour for GPS features",
      "price": 500000,
      "imageUrl": "https://...",
      "geoPoint": {
        "_lat": 21.0285,
        "_long": 105.8542
      }
    }
  }
}
```

#### GPS Coordinates to Test:
- **Destination:** 21.0285°N, 105.8542°E (Hà Nội)
- **500m away:** 21.0250°N, 105.8500°E
- **10km away:** 20.9500°N, 105.8000°E

---

### 🐛 Troubleshooting Quick Fixes

#### "Maps not showing"
- ✅ Verify API key is correct
- ✅ Check internet connectivity
- ✅ Rerun app: `flutter clean && flutter pub get && flutter run`

#### "GPS shows 0m distance"
- ✅ Make sure geoPoint exists in Firebase
- ✅ Test on real device (not emulator)
- ✅ Allow location permission when prompted

#### "Support buttons don't work"
- ✅ Update Zalo phone number and Messenger page ID
- ✅ Ensure Zalo/Messenger app is installed
- ✅ Check internet connection

#### "Python script won't connect to Firebase"
- ✅ Verify firebase_credentials.json exists
- ✅ Check file is valid JSON
- ✅ Run: `python -m json.tool firebase_credentials.json`

#### "ESP32 won't upload"
- ✅ Select correct COM port
- ✅ Select "ESP32 Dev Module" board
- ✅ Ensure USB cable is connected properly
- ✅ Trust the computer in Arduino IDE (macOS)

---

### 📱 Feature Checklist

- [ ] Maps display on tour detail screen
- [ ] Distance indicator shows real-time distance
- [ ] Check-in button works when within 500m
- [ ] Support FAB buttons open Zalo/Messenger
- [ ] ESP32 connects to Firebase
- [ ] Python controller can trigger announcements
- [ ] Speaker plays audio when tour starts

---

### 📚 Full Documentation

- **Complete IoT Guide:** [iot/README.md](../iot/README.md)
- **Implementation Details:** [IMPLEMENTATION_SUMMARY.md](../IMPLEMENTATION_SUMMARY.md)
- **Database Schema:** [iot/firebase_structure_example.json](../iot/firebase_structure_example.json)

---

### 🎯 What You Can Do Now

After setup:
- ✅ Users see tour location on interactive map
- ✅ Users can check in when they arrive (GPS verified)
- ✅ Users can contact support via Zalo/Messenger instantly
- ✅ Admin can trigger speaker announcements for departures
- ✅ All check-ins logged to Firebase for audit trail

---

### 🔗 Useful Links

- Google Maps API: https://developers.google.com/maps
- Firebase Console: https://console.firebase.google.com
- Geolocator Package: https://pub.dev/packages/geolocator
- URL Launcher Package: https://pub.dev/packages/url_launcher
- ESP32 Documentation: https://docs.espressif.com/projects/esp-idf/
- Firebase Python SDK: https://firebase.google.com/docs/database/admin

---

**Need Help?** Refer to the comprehensive [iot/README.md](../iot/README.md) guide for detailed troubleshooting and setup instructions!

Happy Coding! 🚀
