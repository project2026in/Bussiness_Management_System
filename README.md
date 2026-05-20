# 📊 Business Management System

A comprehensive, cross-platform Business Management System built with **Flutter** and powered by **Firebase**. Designed to help small and medium-sized enterprises (SMEs) digitize their financial record-keeping, manage staff, and streamline daily operations.

This project includes both a **Mobile Application** for business owners and staff, and a dedicated **Web Admin Dashboard** for high-level administrative control.

---

## ✨ Key Features

### 🏢 Multi-Role Access Control (RBAC)
- **Superadmin**: Full control via a secure, decoupled web dashboard. Manage administrative credentials, monitor overall system health, and oversee all registered businesses.
- **Business Owner**: Access the Owner Dashboard on mobile to track daily financial reports, manage staff permissions, and store important business documents.
- **Staff Member**: Limited access tailored to day-to-day operations like recording sales and expenses.

### 💰 Financial Record-Keeping
- Digitize daily financial reports including **Sales**, **Expenses**, and **Cash Flow**.
- Real-time updates and historical data tracking.

### 👥 Staff & Business Management
- Add, update, and remove staff members.
- Manage multiple businesses under a single owner profile.
- Store detailed business metadata (Name, Address, Country, City, Phone, Email, etc.).

### 📁 Cloud Storage Integration
- Seamlessly upload and manage business-related images and documents.
- Powered by Firebase Cloud Storage with secure image download URLs saved directly in Firestore for optimized database performance.

### 🌐 Cross-Platform Architecture
- **Mobile**: A beautifully crafted, responsive Flutter app for iOS and Android featuring modern navigation (multi-tab bottom navigation bars) and a consistent, premium aesthetic.
- **Web**: A responsive web portal tailored specifically for Superadmins with a sidebar-based navigation system.

---

## 🛠️ Technology Stack

- **Frontend**: [Flutter](https://flutter.dev/) (Dart) for natively compiled applications across Mobile and Web.
- **Backend**: [Firebase](https://firebase.google.com/)
  - **Authentication**: Secure email/password and Google Sign-In.
  - **Cloud Firestore**: NoSQL cloud database to store user, business, and financial data.
  - **Realtime Database**: (Where applicable for real-time state syncing).
  - **Cloud Storage**: For hosting images and user-uploaded documents.
- **State Management / UI**: Material Design & Custom theming.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (v3.11.5 or higher)
- Android Studio / Xcode for mobile compilation
- A Firebase project with Authentication, Firestore, and Storage enabled.

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/project2026in/Bussiness_Management_System.git
   cd Bussiness_Management_System
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration:**
   - Create a project on the [Firebase Console](https://console.firebase.google.com/).
   - Add an Android and/or iOS app to your Firebase project.
   - Download the `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) and place them in their respective directories.
   - Run `flutterfire configure` to generate the `firebase_options.dart` file.
   - Ensure you have added your **SHA-1 and SHA-256 fingerprints** to Firebase if you intend to use Google Sign-In.

4. **Run the App:**
   - **For Mobile:**
     ```bash
     flutter run
     ```
   - **For Web (Admin Dashboard):**
     ```bash
     flutter run -d chrome
     ```

---

## 📱 Screenshots
*(Add screenshots of your Splash Screen, Owner Dashboard, and Web Admin Panel here to make the repository visually appealing)*
- `<img src="link-to-mobile-dashboard.png" width="200" />`
- `<img src="link-to-web-admin.png" width="400" />`

---

## 🤝 Contributing
Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/project2026in/Bussiness_Management_System/issues).

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
