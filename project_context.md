# Project Context: TrueLove Socio

## Overview
**TrueLove Socio** is a Flutter-based mobile application designed for restaurant partners (socios) to manage their business within the TrueLove ecosystem. It allows partners to manage their menu, view orders in real-time, handle customer reviews, and monitor their payments/quotas.

## Tech Stack
- **Framework:** Flutter (Mobile)
- **State Management:** GetX (Controllers, Bindings, Dependency Injection)
- **Networking:** Dio & Http
- **Notifications:** Firebase Messaging (FCM) & Flutter Local Notifications
- **Storage:** Shared Preferences & Flutter Secure Storage
- **UI:** Custom components with `animate_do` for animations.

## Architecture
The project follows a **Feature-based architecture** combined with GetX patterns:
- `lib/core`: Contains global utilities, themes, routes, and common widgets.
- `lib/data`: Data sources and API client.
- `lib/features`: Organized by functional module, each containing:
  - `bindings`: Dependency injection configuration.
  - `controllers`: Logic and state management.
  - `presentation`: UI screens and components.

## Key Features
- **Real-time Orders:** Manage new, in-progress, and historic orders (`features/orders`).
- **Menu Management:** Create and update categories and dishes (`features/menu`).
- **Payments (Cuotas):** Track membership quotas and financial status (`features/cuotas`).
- **Reviews:** View and respond to customer feedback (`features/reviews`).
- **Authentication:** Secure login and password management (`features/auth`).

## Project Structure
```
lib/
├── core/
│   ├── api/           # API Configuration & Base Client
│   ├── bindings/      # Initial Global Bindings
│   ├── components/    # Reusable UI Widgets
│   ├── routes/        # App Routes (GetPage)
│   ├── theme/         # Light/Dark Theme definitions
│   └── utils/         # Helpers & Converters
├── data/
│   ├── models/        # Data Transfers Objects
│   └── services/      # Business logic services (e.g., Firebase)
├── features/          # Functional Modules
│   ├── auth/          # Login, Register, Password
│   ├── cuotas/        # Payment tracking
│   ├── home/          # Main Dashboard
│   ├── menu/          # Dish & Category management
│   ├── orders/        # Order handling
│   ├── reviews/       # Customer feedback
│   └── splash/        # Splash screen & Initial logic
└── main.dart          # App Entry point
```

## Related Projects
- **TrueLove Client:** The consumer app where users place orders.
- **TrueLove Biker:** Delivery app for riders.
- **TrueLove Back:** Backend API powering the ecosystem.
