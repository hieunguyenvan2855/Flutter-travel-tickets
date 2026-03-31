#!/usr/bin/env python3
"""
Firebase IoT Speaker Controller
Purpose: Python backend to trigger speaker announcements via Firebase
When admin clicks "Khởi hành" in mobile app, this script sends signal to ESP32

Requirements:
    pip install firebase-admin pyttsx3 pydub simpleaudio requests

Usage:
    python iot_speaker_controller.py
"""

import firebase_admin
from firebase_admin import credentials, db, storage
import time
import os
import json
import threading
from datetime import datetime
import pyttsx3
import logging

# ==================== Configuration ====================
# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Firebase configuration file path
FIREBASE_CREDENTIALS_PATH = './firebase_credentials.json'

# Firebase database URL
FIREBASE_DATABASE_URL = 'https://your-project.firebaseio.com'

# Audio settings
ANNOUNCEMENT_VOLUME = 0.8
AUDIO_SAMPLE_RATE = 8000  # 8kHz for ESP32

# ==================== Initialize Firebase ====================
def initialize_firebase():
    """Initialize Firebase admin SDK"""
    try:
        # Check if already initialized
        try:
            firebase_admin.get_app()
            logger.info("✓ Firebase already initialized")
            return
        except ValueError:
            pass
        
        # Initialize with service account
        if not os.path.exists(FIREBASE_CREDENTIALS_PATH):
            logger.error(f"✗ Firebase credentials file not found: {FIREBASE_CREDENTIALS_PATH}")
            logger.error("  Download from Firebase Console > Project Settings > Service Accounts")
            return False
        
        cred = credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
        firebase_admin.initialize_app(cred, {
            'databaseURL': FIREBASE_DATABASE_URL
        })
        
        logger.info("✓ Firebase initialized successfully")
        return True
    
    except Exception as e:
        logger.error(f"✗ Failed to initialize Firebase: {e}")
        return False

# ==================== Audio Generation ====================
def generate_announcement_audio(text, output_file='announcement.wav'):
    """
    Convert Vietnamese text to speech using pyttsx3
    
    Args:
        text (str): Vietnamese text to convert
        output_file (str): Output WAV file path
    
    Returns:
        str: Path to generated audio file
    """
    try:
        logger.info(f"🎤 Generating announcement: {text}")
        
        engine = pyttsx3.init()
        engine.setProperty('rate', 150)  # Speed
        engine.setProperty('volume', ANNOUNCEMENT_VOLUME)
        
        # Try to set Vietnamese voice if available
        voices = engine.getProperty('voices')
        for voice in voices:
            if 'vietnamese' in voice.name.lower():
                engine.setProperty('voice', voice.id)
                break
        
        engine.save_to_file(text, output_file)
        engine.runAndWait()
        
        logger.info(f"✓ Audio generated: {output_file}")
        return output_file
    
    except Exception as e:
        logger.error(f"✗ Failed to generate audio: {e}")
        return None

# ==================== Firebase Operations ====================
def trigger_tour_announcement(tour_id, tour_title):
    """
    Trigger speaker announcement for a specific tour
    
    Args:
        tour_id (str): Tour ID
        tour_title (str): Tour title for announcement
    
    Returns:
        bool: Success status
    """
    try:
        ref = db.reference(f'/tours/{tour_id}')
        
        # Set status to 'started' which triggers ESP32
        ref.update({
            'status': 'started',
            'announcement_timestamp': datetime.now().isoformat(),
            'announced': True
        })
        
        logger.info(f"✓ Announcement triggered for tour: {tour_title} ({tour_id})")
        return True
    
    except Exception as e:
        logger.error(f"✗ Failed to trigger announcement: {e}")
        return False

def get_tour_by_id(tour_id):
    """Get tour details from Firebase"""
    try:
        ref = db.reference(f'/tours/{tour_id}')
        tour = ref.get()
        return tour
    except Exception as e:
        logger.error(f"✗ Failed to get tour: {e}")
        return None

def get_all_active_tours():
    """Get all currently active tours"""
    try:
        ref = db.reference('/tours')
        tours = ref.get()
        
        if not tours:
            return []
        
        active_tours = []
        for tour_id, tour_data in tours.items():
            if tour_data.get('status') == 'active':
                active_tours.append({
                    'id': tour_id,
                    'title': tour_data.get('title', 'Unknown'),
                    'data': tour_data
                })
        
        return active_tours
    
    except Exception as e:
        logger.error(f"✗ Failed to get tours: {e}")
        return []

def log_announcement_to_database(tour_id, tour_title, status='success'):
    """Log announcement event to Firebase for audit trail"""
    try:
        ref = db.reference(f'/announcements/{tour_id}')
        ref.push({
            'timestamp': datetime.now().isoformat(),
            'tour_title': tour_title,
            'status': status,
            'triggered_by': 'admin_app'
        })
        
        logger.info(f"✓ Announcement logged for audit trail")
    except Exception as e:
        logger.warning(f"⚠ Failed to log announcement: {e}")

# ==================== Listen for Triggered Announcements ====================
def listen_for_announcements():
    """
    Listen for new tour start events from admin app
    This runs in background and watches for changes in database
    """
    logger.info("👂 Listening for tour start events...")
    
    def on_tour_event(message):
        if not message.data:
            return
        
        logger.info(f"🔔 Event received: {message.path}")
        
        # Check if this is a tour start event
        if 'status' in str(message.data):
            tour_id = message.path.split('/')[-1]
            tour = get_tour_by_id(tour_id)
            
            if tour and tour.get('status') == 'started' and not tour.get('announced'):
                logger.info(f"🚌 Tour departure event: {tour.get('title')}")
                
                # Generate announcement text
                announcement_text = f"Chuyến tour {tour.get('title')} đã khởi hành! Xin yêu cầu tất cả hành khách lên xe."
                
                # Log the announcement
                log_announcement_to_database(tour_id, tour.get('title'))
    
    # Set up stream listener
    try:
        ref = db.reference('/tours')
        ref.listen(on_tour_event)
    except Exception as e:
        logger.error(f"✗ Failed to set up listener: {e}")

# ==================== Admin CLI Interface ====================
def admin_menu():
    """Interactive admin menu for testing and managing announcements"""
    
    while True:
        print("\n" + "="*50)
        print("IoT SPEAKER CONTROLLER - ADMIN MENU")
        print("="*50)
        print("1. View active tours")
        print("2. Trigger announcement for specific tour")
        print("3. Generate test announcement")
        print("4. Check ESP32 connection status")
        print("5. View announcement history")
        print("6. Start listening mode (background)")
        print("0. Exit")
        print("="*50)
        
        choice = input("Select option: ").strip()
        
        if choice == '1':
            view_active_tours()
        elif choice == '2':
            trigger_announcement_interactive()
        elif choice == '3':
            test_announcement()
        elif choice == '4':
            check_esp32_status()
        elif choice == '5':
            view_announcement_history()
        elif choice == '6':
            start_listening_mode()
        elif choice == '0':
            print("Exiting...")
            break
        else:
            print("Invalid option!")

def view_active_tours():
    """Display all active tours"""
    tours = get_all_active_tours()
    
    if not tours:
        print("\n⚠ No active tours found")
        return
    
    print("\n" + "="*50)
    print("ACTIVE TOURS")
    print("="*50)
    
    for i, tour in enumerate(tours, 1):
        print(f"{i}. {tour['title']} (ID: {tour['id']})")
        print(f"   Status: {tour['data'].get('status')}")
        print(f"   Passengers: {tour['data'].get('availableSlots', 0)}")
        print()

def trigger_announcement_interactive():
    """Interactive tour announcement trigger"""
    tours = get_all_active_tours()
    
    if not tours:
        print("\n⚠ No active tours available")
        return
    
    print("\n" + "="*50)
    print("TRIGGER ANNOUNCEMENT")
    print("="*50)
    
    for i, tour in enumerate(tours, 1):
        print(f"{i}. {tour['title']}")
    
    try:
        choice = int(input("Select tour (0 to cancel): "))
        if choice == 0:
            return
        
        if 1 <= choice <= len(tours):
            selected_tour = tours[choice - 1]
            confirm = input(f"\nAnnounce departure for '{selected_tour['title']}'? (y/n): ")
            
            if confirm.lower() == 'y':
                trigger_tour_announcement(selected_tour['id'], selected_tour['title'])
                print("✓ Announcement triggered!")
            else:
                print("Cancelled")
        else:
            print("Invalid selection")
    
    except ValueError:
        print("Invalid input")

def test_announcement():
    """Generate and test announcement audio"""
    text = input("Enter announcement text (or press Enter for default): ").strip()
    
    if not text:
        text = "Chuyến tour bắt đầu! Xin yêu cầu tất cả hành khách lên xe."
    
    logger.info(f"Testing announcement: {text}")
    generate_announcement_audio(text)

def check_esp32_status():
    """Check if ESP32 is connected and responding"""
    try:
        ref = db.reference('/esp32/status')
        status = ref.get()
        
        print("\n✓ ESP32 Status:")
        print(json.dumps(status, indent=2))
    except Exception as e:
        print(f"\n✗ Failed to check status: {e}")

def view_announcement_history():
    """View recent announcement history"""
    try:
        ref = db.reference('/announcements')
        announcements = ref.get()
        
        if not announcements:
            print("\n⚠ No announcement history")
            return
        
        print("\n" + "="*50)
        print("ANNOUNCEMENT HISTORY")
        print("="*50)
        
        for tour_id, events in announcements.items():
            print(f"\nTour: {tour_id}")
            if isinstance(events, dict):
                for event_id, event in events.items():
                    print(f"  {event.get('timestamp')}: {event.get('status')}")
    
    except Exception as e:
        print(f"✗ Failed to view history: {e}")

def start_listening_mode():
    """Start background listening for tour events"""
    print("\n🎧 Starting listener mode...")
    print("Press Ctrl+C to stop\n")
    
    thread = threading.Thread(target=listen_for_announcements, daemon=True)
    thread.start()
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n✓ Listener stopped")

# ==================== Main ====================
def main():
    """Main entry point"""
    logger.info("🎤 IoT Speaker Controller Started")
    
    # Initialize Firebase
    if not initialize_firebase():
        logger.error("Failed to initialize Firebase. Exiting.")
        return
    
    # Start admin menu
    admin_menu()

if __name__ == '__main__':
    main()
