# IoT Speaker System - Setup & Usage Guide

## Overview

This IoT system allows your travel company to automatically announce tour departures via speakers. When an admin clicks "Khởi hành" (Start Journey) in the mobile app, a signal is sent through Firebase to an ESP32 microcontroller, which then plays an audio announcement through connected speakers.

### System Architecture

```
Mobile App (Admin Panel)
    ↓
[Click "Khởi hành"]
    ↓
Firebase Realtime Database
    ↓ (Update /tours/{tourId}/status)
    ↓
ESP32 Microcontroller
    ↓
Speaker Output (I2S Speaker)
    ↓
Audio Announcement
```

---

## Part 1: ESP32 C++ Setup

### Hardware Requirements

- **ESP32 Development Board** (e.g., ESP32-DEVKIT-V1)
- **I2S Speaker Module** or DAC with speaker (e.g., MAX98357A I2S amplifier)
- **Microphone** (optional, for echo cancellation)
- **USB Cable** for programming
- **5V Power Supply** for speakers
- **Jumper Wires**

### Wiring Diagram

```
ESP32 Pins:
┌─────────────────────────────────────────┐
│ GPIO 25 (DOUT) ──> I2S DAT              │
│ GPIO 26 (WS)   ──> I2S WS               │
│ GPIO 27 (SCK)  ──> I2S CLK              │
│ GND            ──> Speaker GND          │
│ +5V            ──> Speaker +5V (via amp)│
└─────────────────────────────────────────┘

I2S Speaker Amplifier (MAX98357A example):
┌─────────────────────────────────────────┐
│ DIN   ──> ESP32 GPIO 25 (DOUT)          │
│ LRCLK ──> ESP32 GPIO 26 (WS)            │
│ BCLK  ──> ESP32 GPIO 27 (SCK)           │
│ GND   ──> ESP32 GND + Speaker GND       │
│ +5V   ──> 5V Power Supply               │
│ OUT   ──> Speaker (+/- terminals)       │
└─────────────────────────────────────────┘
```

### Installation Steps

1. **Install Arduino IDE**
   - Download from https://www.arduino.cc/en/software
   - Install ESP32 board support:
     - File → Preferences → Additional Boards Manager URLs
     - Add: `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
     - Tools → Boards Manager → Search "ESP32" → Install

2. **Install Required Libraries**
   In Arduino IDE, go to Sketch → Include Library → Manage Libraries:
   - `Firebase Realtime Database` (by Mobizt)
   - `ArduinoJson` (by Benoit Blanchon)
   - `AsyncTCP`
   - `ESPAsyncWebServer` (optional, for web control panel)

3. **Configure ESP32 Sketch**
   - Copy `esp32_announcement_speaker.cpp` content to Arduino IDE
   - Update configuration:
     ```cpp
     #define WIFI_SSID "YOUR_WIFI_SSID"
     #define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"
     #define FIREBASE_HOST "your-project.firebaseio.com"
     #define FIREBASE_AUTH "YOUR_FIREBASE_AUTH_TOKEN"
     ```

4. **Upload to ESP32**
   - Connect ESP32 via USB
   - Select: Tools → Board → ESP32 Dev Module
   - Main on correct COM port
   - Click Upload
   - Open Serial Monitor (115200 baud) to see status

5. **Prepare Audio Files**
   - Convert Vietnamese TTS to WAV format (8kHz, 8-bit PCM)
   - Upload to ESP32 SPIFFS:
     - Tools → ESP32 Sketch Data Upload
     - Place WAV files in `data/` folder

### Testing ESP32

- Open Serial Monitor to see debug logs
- Press test button (GPIO 32) to manually trigger announcement
- Check Firebase connection status in serial output

---

## Part 2: Python Backend Setup

### Requirements

- **Python 3.8+**
- **Firebase Admin SDK**
- **pyttsx3** for text-to-speech (Vietnamese support)
- **Linux/macOS/Windows** with network access

### Installation

1. **Install Python Dependencies**
   ```bash
   cd iot
   pip install -r requirements.txt
   ```

   Or manually:
   ```bash
   pip install firebase-admin pyttsx3 pydub simpleaudio requests
   ```

2. **Set Up Firebase Credentials**
   - Go to Firebase Console → Project Settings → Service Accounts
   - Click "Generate New Private Key"
   - Save as `iot/firebase_credentials.json`
   - Update path in `iot_speaker_controller.py`:
     ```python
     FIREBASE_CREDENTIALS_PATH = './firebase_credentials.json'
     ```

3. **Update Firebase URL**
   - In `iot_speaker_controller.py`, update:
     ```python
     FIREBASE_DATABASE_URL = 'https://your-project.firebaseio.com'
     ```

### Running the Controller

**Start Interactive Admin Menu:**
```bash
python iot/iot_speaker_controller.py
```

**Menu Options:**
1. **View Active Tours** - List all currently active tours
2. **Trigger Announcement** - Manually trigger speaker for a tour
3. **Generate Test Announcement** - Test Vietnamese TTS
4. **Check ESP32 Status** - Verify ESP32 connectivity
5. **View History** - See all past announcements (audit trail)
6. **Start Listening Mode** - Background listener for tour events
7. **Exit** - Close the application

**Programmatic Usage:**
```python
from iot_speaker_controller import trigger_tour_announcement

# Trigger announcement for specific tour
trigger_tour_announcement('tour_001', 'Hạ Long Bay Tour')
```

---

## Part 3: Firebase Setup

### Database Structure

```
/tours
  ├── {tourId1}
  │   ├── title: "Hạ Long Bay Tour"
  │   ├── status: "started"  ← Update this to trigger announcement
  │   ├── announcement_timestamp: "2024-03-30T10:30:00"
  │   └── announced: true
  │
  ├── {tourId2}
  │   └── ...
  │
/announcements
  ├── {tourId1}
  │   ├── -xxx123
  │   │   ├── timestamp: "2024-03-30T10:30:00"
  │   │   ├── tour_title: "Hạ Long Bay Tour"
  │   │   ├── status: "success"
  │   │   └── triggered_by: "admin_app"
  │
/esp32
  ├── status
  │   ├── connected: true
  │   ├── ip_address: "192.168.1.100"
  │   ├── last_heartbeat: "2024-03-30T10:35:00"
  │   └── battery_level: 100
```

### Firebase Security Rules

```json
{
  "rules": {
    "tours": {
      "$tourId": {
        ".read": true,
        ".write": "root.child('users').child(auth.uid).exists()",
        "status": {
          ".write": "root.child('users').child(auth.uid).child('role').val() === 'admin'"
        }
      }
    },
    "announcements": {
      ".read": "root.child('users').child(auth.uid).exists()",
      ".write": "root.child('users').child(auth.uid).child('role').val() === 'admin'"
    },
    "esp32": {
      ".read": true,
      ".write": "auth.token.type === 'esp32'"
    }
  }
}
```

---

## Part 4: Integration with Mobile App

### Admin Panel Update

When admin clicks "Khởi hành" button, update tour status in database:

```dart
// In Database Service or Admin Screen
Future<void> startTourWithAnnouncement(String tourId, String tourTitle) async {
  try {
    // Update tour status in Firebase
    await _db.collection('tours').doc(tourId).update({
      'status': 'started',
      'announcement_timestamp': FieldValue.serverTimestamp(),
    });
    
    // Alternative: Use Realtime DB for instant announcement
    // This will trigger the Python backend and ESP32
    
    print('✓ Tour started: $tourTitle');
    print('📢 Announcement sent to ESP32 speaker');
  } catch (e) {
    print('Error: $e');
  }
}
```

### Admin Panel UI

Add button in admin tour management screen:

```dart
ElevatedButton.icon(
  icon: const Icon(Icons.volume_up),
  label: const Text('Khởi hành'),
  onPressed: () => startTourWithAnnouncement(tour.id, tour.title),
)
```

---

## Part 5: Audio Configuration

### Generate Vietnamese TTS Audio

**Using Python:**
```python
import pyttsx3

engine = pyttsx3.init()
engine.setProperty('rate', 150)
engine.setProperty('volume', 0.8)

text = "Chuyến tour Hạ Long bắt đầu! Xin yêu cầu tất cả hành khách lên xe."
engine.save_to_file(text, 'announcement.wav')
engine.runAndWait()
```

**Using Online Services:**
- Google Cloud Text-to-Speech: https://cloud.google.com/text-to-speech
- AWS Polly: https://aws.amazon.com/polly/
- Azure Speech Services: https://azure.microsoft.com/en-us/products/cognitive-services/text-to-speech/

### Audio Format Requirements

- **Sample Rate:** 8kHz (for low bandwidth)
- **Bit Depth:** 8-bit PCM
- **Channels:** Mono
- **Format:** WAV file
- **Duration:** 3-10 seconds

---

## Troubleshooting

### ESP32 Not Connecting to WiFi
- Check SSID and password
- Verify WiFi is on 2.4GHz (ESP32 doesn't support 5GHz)
- Look at serial monitor for error messages

### Firebase Connection Errors
- Verify Firebase credentials are correct
- Check database URL
- Ensure Firebase Realtime Database is enabled in console
- Check security rules allow read/write

### No Sound from Speaker
- Verify I2S wiring connections
- Check speaker power supply
- Test with `testPlayAudio()` function in Serial Monitor
- Ensure audio file is valid WAV format
- Check speaker volume levels

### Python Script Crashes
- Verify firebase_credentials.json exists and is valid
- Check Python version (3.8+)
- Install all dependencies: `pip install -r requirements.txt`
- Check Firebase database URL is correct

---

## Production Deployment

### For Small Venue (Single ESP32)
1. Set up ESP32 with WiFi and Firebase
2. Connect to venue's speaker system
3. Run Python controller on admin's computer or server
4. Mobile admin triggers announcements as needed

### For Multiple Venues
1. Deploy multiple ESP32 boards (one per venue)
2. Each ESP32 listens to its own `/tours/{venueId}` path
3. Center Python server coordinates all announcements
4. Database tracks announcements per venue

### Cloud Deployment

**Option 1: Google Cloud Run**
```bash
# Deploy Python controller to Cloud Run
gcloud run deploy iot-speaker-controller --source . --runtime python39
```

**Option 2: AWS Lambda**
- Create Lambda function from Python code
- Trigger via EventBridge on tour update

**Option 3: On-Premises Server**
- Run Python script on always-on server
- Use systemd service for auto-restart
- Monitor with health check endpoints

---

## Security Considerations

1. **Protect Firebase Credentials**
   - Never commit `firebase_credentials.json` to git
   - Use environment variables in production
   - Rotate credentials regularly

2. **ESP32 Security**
   - Use strong WiFi password
   - Implement OTA updates securely
   - Monitor ESP32 activity logs

3. **Database Security**
   - Restrict write access to admin users only
   - Implement approval workflow for tour starts
   - Log all announcements for audit trail

---

## Support & Resources

- **Firebase Documentation:** https://firebase.google.com/docs
- **ESP32 Documentation:** https://docs.espressif.com/projects/esp-idf/
- **Arduino ESP32:** https://github.com/espressif/arduino-esp32
- **Firebase Admin SDK (Python):** https://firebase.google.com/docs/database/admin/start

---

## License

MIT License - Feel free to modify and distribute

## Version

v1.0 - March 2024
