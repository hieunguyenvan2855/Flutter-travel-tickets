/*
 * ESP32 IoT Speaker Announcement System
 * Purpose: Listen to Firebase Real-time Database events
 * When Admin clicks "Khởi hành" (Start Journey), the speaker plays audio notification
 * 
 * Required Libraries:
 * - Firebase Realtime Database (firebase-esp32)
 * - WiFi (esp32 built-in)
 * - I2S Audio Output (esp32 built-in)
 * - ArduinoJson for JSON parsing
 * - AsyncTCP
 * - ESPAsyncWebServer (for web interface)
 * 
 * Installation:
 * - Use Arduino IDE Library Manager to add sketches
 * - Or use: #include <Firebase.h>
 */

#include <WiFi.h>
#include <WiFiClient.h>
#include <Firebase.h>
#include <FirebaseAuth.h>
#include <FirebaseDatabase.h>
#include <ArduinoJson.h>
#include <driver/i2s.h>
#include <SPI.h>

// ==================== Configuration ====================
#define WIFI_SSID "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

// Firebase Configuration
#define FIREBASE_HOST "your-project.firebaseio.com"
#define FIREBASE_AUTH "YOUR_FIREBASE_AUTH_TOKEN"

// I2S Audio Configuration (for DAC speaker output)
#define I2S_SD 25      // Data pin
#define I2S_WS 26      // Word Select pin
#define I2S_SCK 27     // Serial Clock pin
#define I2S_DOUT 25    // Data Output pin (GPIO25 for ESP32 internal DAC)

// Button GPIO
#define BUTTON_TEST_PIN 32  // Test button for manual trigger

// ==================== Audio Data ====================
// Sample audio notification (8-bit PCM at 8kHz)
// This should be replaced with your actual audio file
const uint8_t ANNOUNCEMENT_AUDIO[] = {
  // Vietnamese TTS: "Chuyến tour bắt đầu! Xin yêu cầu tất cả hành khách lên xe."
  // Placeholder - Replace with actual audio bytes
  0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80,
};

const size_t AUDIO_LENGTH = sizeof(ANNOUNCEMENT_AUDIO);

// ==================== Global Variables ====================
FirebaseData firebaseData;
FirebaseConfig config;
FirebaseAuth auth;
bool isAnnouncing = false;
unsigned long lastAnnouncementTime = 0;

// ==================== Function Prototypes ====================
void setupWiFi();
void setupFirebase();
void setupI2S();
void playAnnouncement();
void handleTourStarted(String tourId);
void firebaseStreamCallback(MultiPathStream stream);
void onDatabaseChanged(FirebaseStream data);

// ==================== Setup ====================
void setup() {
  Serial.begin(115200);
  delay(2000);
  
  Serial.println("\n\n=== ESP32 IoT Speaker System Initializing ===");
  
  // Setup IO
  pinMode(BUTTON_TEST_PIN, INPUT_PULLUP);
  
  // Setup subsystems
  setupWiFi();
  setupFirebase();
  setupI2S();
  
  Serial.println("✓ System initialization complete!");
  Serial.println("Waiting for Firebase events...\n");
}

// ==================== Main Loop ====================
void loop() {
  // Check for test button press
  if (digitalRead(BUTTON_TEST_PIN) == LOW) {
    delay(50);
    if (digitalRead(BUTTON_TEST_PIN) == LOW) {
      Serial.println("Test button pressed - Triggering announcement");
      playAnnouncement();
      delay(1000);
    }
  }
  
  // Keep Firebase connection alive
  if (!Firebase.isTokenExpired()) {
    delay(100);
  }
}

// ==================== WiFi Setup ====================
void setupWiFi() {
  Serial.print("Connecting to WiFi: ");
  Serial.println(WIFI_SSID);
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✓ WiFi connected!");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n✗ Failed to connect to WiFi");
  }
}

// ==================== Firebase Setup ====================
void setupFirebase() {
  // Configure Firebase
  config.host = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH;
  config.database_url = "https://" + String(FIREBASE_HOST);
  
  // Initialize Firebase
  Firebase.begin(&config, &auth);
  Firebase.reconnectNetwork(true);
  
  Serial.println("✓ Firebase configured");
  
  // Set up stream listener for tour events
  // Listen to: /tours/{tourId}/status
  if (!Firebase.beginStream(firebaseData, "/tours")) {
    Serial.print("✗ Failed to begin stream: ");
    Serial.println(firebaseData.errorReason());
  } else {
    Serial.println("✓ Stream listener started for /tours");
  }
  
  // Set callback for stream changes
  Firebase.setStreamCallback(firebaseData, firebaseStreamCallback, firebaseStreamError);
}

// ==================== I2S Setup (Audio Output) ====================
void setupI2S() {
  i2s_config_t i2s_config = {
    .mode = I2S_MODE_MASTER | I2S_MODE_TX,         // TX only
    .sample_rate = 8000,                            // 8kHz sample rate
    .bits_per_sample = I2S_BITS_PER_SAMPLE_8BIT,   // 8-bit samples
    .channel_format = I2S_CHANNEL_MONO,             // Mono (1 channel)
    .communication_format = (i2s_comm_format_t)(I2S_COMM_FORMAT_I2S | I2S_COMM_FORMAT_I2S_MSB),
    .intr_alloc_flags = ESP_INTR_FLAG_LEVEL1,
    .dma_buf_count = 8,
    .dma_buf_len = 64,
  };
  
  i2s_pin_config_t pin_config = {
    .bck_io_num = I2S_SCK,
    .ws_io_num = I2S_WS,
    .data_out_num = I2S_DOUT,
    .data_in_num = I2S_PIN_NO_CHANGE,
  };
  
  i2s_driver_install(I2S_NUM_0, &i2s_config, 0, NULL);
  i2s_set_pin(I2S_NUM_0, &pin_config);
  
  Serial.println("✓ I2S audio output configured");
}

// ==================== Firebase Stream Callback ====================
void firebaseStreamCallback(MultiPathStream stream) {
  size_t numChild = stream.payloadLength();
  Serial.print("✓ Firebase event received - ");
  Serial.print(numChild);
  Serial.println(" items");
  
  for (size_t i = 0; i < numChild; i++) {
    FIREBASE_STREAM_CLASS mode = stream.get(i);
    FirebaseStream data = stream.getStream(i);
    
    String path = data.dataPath;
    String value = data.stringValue;
    
    Serial.print("  Path: ");
    Serial.print(path);
    Serial.print(" | Value: ");
    Serial.println(value);
    
    // Check if admin started a tour
    if (path.endsWith("/status") && value == "started") {
      // Extract tour ID from path: /tours/{tourId}/status
      String tourId = path.substring(7);  // Remove "/tours/"
      tourId = tourId.substring(0, tourId.indexOf("/"));  // Remove "/status"
      
      Serial.print("🚌 Tour started: ");
      Serial.println(tourId);
      
      handleTourStarted(tourId);
    }
  }
}

// Firebase stream error handler
void firebaseStreamError(const char* info) {
  Serial.print("✗ Firebase stream error: ");
  Serial.println(info);
}

// ==================== Tour Started Handler ====================
void handleTourStarted(String tourId) {
  // Prevent multiple announcements in short time
  if (millis() - lastAnnouncementTime < 5000) {
    Serial.println("⏳ Announcement in progress, ignoring new request");
    return;
  }
  
  lastAnnouncementTime = millis();
  
  // Get tour details from Firebase
  if (Firebase.getJSON(firebaseData, "/tours/" + tourId)) {
    FirebaseJson &json = firebaseData.jsonObject();
    String tourTitle = json.stringValue();
    
    Serial.print("📢 Playing announcement for tour: ");
    Serial.println(tourTitle);
    
    // Play announcement
    playAnnouncement();
    
    // Optional: Log the announcement to database
    Firebase.setInt(firebaseData, "/tours/" + tourId + "/lastAnnouncement", millis());
  }
}

// ==================== Play Announcement ====================
void playAnnouncement() {
  if (isAnnouncing) {
    Serial.println("⏳ Already announcing, please wait...");
    return;
  }
  
  isAnnouncing = true;
  Serial.println("▶️  Playing announcement...");
  
  // Write audio data to I2S peripheral
  size_t bytes_written = 0;
  i2s_write(I2S_NUM_0, (const void*)ANNOUNCEMENT_AUDIO, AUDIO_LENGTH, &bytes_written, portMAX_DELAY);
  
  Serial.print("✓ Announcement played! Bytes written: ");
  Serial.println(bytes_written);
  
  isAnnouncing = false;
}

// ==================== Utility Functions ====================

/**
 * Alternative: Play audio from SPIFFS file system
 * Requires uploading WAV file to ESP32 using Arduino IDE
 */
void playAnnouncementFromFile(const char* filePath) {
  File audioFile = SPIFFS.open(filePath, "r");
  if (!audioFile) {
    Serial.print("✗ Failed to open audio file: ");
    Serial.println(filePath);
    return;
  }
  
  Serial.print("▶️  Playing: ");
  Serial.println(filePath);
  
  isAnnouncing = true;
  
  const int BUFFER_SIZE = 2048;
  uint8_t buffer[BUFFER_SIZE];
  
  while (audioFile.available()) {
    int bytesRead = audioFile.read(buffer, BUFFER_SIZE);
    size_t bytesWritten = 0;
    i2s_write(I2S_NUM_0, buffer, bytesRead, &bytesWritten, portMAX_DELAY);
  }
  
  audioFile.close();
  isAnnouncing = false;
  Serial.println("✓ Playback complete");
}

/**
 * Reconnect to Firebase when connection is lost
 */
void reconnectFirebase() {
  if (!Firebase.connected()) {
    Serial.println("Reconnecting to Firebase...");
    Firebase.reconnectNetwork(true);
    delay(1000);
  }
}

// ==================== Debug: Test functions ====================
void testPlayAudio() {
  Serial.println("\n=== Testing Audio Playback ===");
  playAnnouncement();
  delay(2000);
  Serial.println("✓ Audio test complete\n");
}

void testFirebaseConnection() {
  Serial.println("\n=== Testing Firebase Connection ===");
  if (Firebase.getInt(firebaseData, "/test")) {
    Serial.print("✓ Firebase connection OK | Value: ");
    Serial.println(firebaseData.intValue());
  } else {
    Serial.print("✗ Firebase connection failed: ");
    Serial.println(firebaseData.errorReason());
  }
  Serial.println();
}
