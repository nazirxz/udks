# UD Keluarga Sehati Application

A Flutter-based management system for "UD Keluarga Sehati", designed to support multiple user roles and cover essential business operations including authentication, inventory tracking, sales/purchase data management, and ordering workflows.

---

## 🚀 Getting Started

This project is a starting point for a Flutter application.

### Resources:
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Flutter Documentation](https://docs.flutter.dev/)

---

## 🔑 Key Features

### ✅ User Authentication
- Secure login & registration
- Auto-login and "remember me"
- Role-based user access

### 🖥️ Role-Based Dashboards

- **Admin Dashboard**  
  Overview of statistics, charts of weekly incoming/outgoing goods, recent transactions, and inventory alerts.

- **Sales Dashboard**  
  - Distribution route tracking using OpenStreetMap  
  - Optimal route suggestion with geolocation  
  - Launch directions via URL Launcher

- **Retailer Dashboard**  
  - Product catalog view  
  - Cart and checkout system  
  - Quantity management

- **Manager Dashboard**  
  - Daily inventory flow  
  - Sales/purchase transactions  
  - Alerts for low stock

### 📊 Data Management
- **Purchases**: Manage and view purchase trends, tables, and weekly statistics.
- **Sales**: Weekly tracking of sales data with graphical views.
- **Returns**: Visualize and monitor goods return.

### 🎨 Custom UI Components
- Reusable widgets for:
  - Cart badges
  - Scrollable/customizable data tables
  - Chart widgets

### 🌟 Splash Screen Animation
- Slide, fade, and scale transitions.

---

## 🛠️ Technologies Used

- **Flutter** – Multi-platform UI framework
- **Dart** – Programming language
- **State Management**: `provider`
- **Local Storage**: `shared_preferences`
- **Maps**: `flutter_map`, `latlong2`
- **Location**: `geolocator`
- **Permissions**: `permission_handler`
- **External Links**: `url_launcher`

---

## 📁 Project Structure

```
udkeluargasehati_application/
├── android/               # Android config
├── assets/
│   ├── data/              # Demo JSON (users.json, etc.)
│   └── images/            # Logo and images
├── ios/                   # iOS config
├── lib/
│   ├── main.dart          # Entry point
│   ├── mixin/             # Common mixins
│   ├── models/            # User, Cart, etc.
│   ├── screens/           # All main screens
│   ├── services/          # Auth, Cart, AdminData, etc.
│   ├── utils/             # Utility functions
│   └── widgets/           # Reusable components
├── linux/
├── macos/
├── test/                  # Unit & widget tests
├── web/
├── pubspec.yaml           # Dependencies
└── README.md              # You are here
```

---

## ⚙️ Installation and Setup

```bash
# Clone the repository
git clone [YOUR_REPOSITORY_URL]
cd udkeluargasehati_application

# Get packages
flutter pub get

# Run the application
flutter run

# To run in browser:
flutter run -d chrome
```

---

## 👥 Demo Login Credentials

| Role     | Username   | Password   |
|----------|------------|------------|
| Admin    | `admin`    | `admin`    |
| Sales    | `sales`    | `sales`    |
| Retailer | `pengecer` | `pengecer` |
| Manager  | `manager`  | `manager`  |

Upon login, you'll be redirected to the appropriate dashboard.

---

## 👨‍💻 Contributors

This project was developed for **UD Keluarga Sehati**.

---
