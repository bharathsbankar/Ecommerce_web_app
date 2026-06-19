# ⚡ FlashDash Deals - High-Concurrency Flash Sale Platform

Welcome to **FlashDash Deals**, a production-grade, containerized microservices platform designed to handle extremely high-traffic shopping rushes (flash sales) safely and reliably.

The system employs advanced database-level concurrency control, strict transactional rollbacks, soft-reservations in Redis, centralized API ingress routing with JWT claim propagation, and a secure multi-subnet private Docker network layout.

---

## 🏗️ High-Level System Architecture

The platform separates microservice concerns into five isolated Docker bridge networks:
1. `auth_net`: Connects Django auth service and `auth-db` privately.
2. `cart_net`: Connects cart service and Redis `cart-db` privately.
3. `catalog_net`: Connects catalog service and `catalog-db` privately.
4. `order_net`: Connects order service and `order-db` privately.
5. `app_net`: Central API gateway and microservice internal communication subnet.

```
                         ┌────────────────────────┐    ┌────────────────────────┐
                         │  Client Browser (Host) │    │  Mobile Client (Phone) │
                         └───────────┬────────────┘    └───────────┬────────────┘
             Port 3000 (Web App)     │                             │ Port 8080 (API Ingress)
             or Port 8080 (API Ingr) ▼                             ▼
                         ====================== app_net ======================
                         │           krakend-gateway (KrakenD)               │
                         │                     │                             │
                         ├──────────────┬──────┴───────┬──────────────┐      │
                         ▼              ▼              ▼              ▼      │
                   ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌──────────┐ │
                   │auth-service│ │cart-service│ │catalog-svc │ │order-svc │ │
                   │  (Django)  │ │ (Node.js)  │ │(SpringBoot)│ │(SpringB.)│ │
                   └─────┬──────┘ └─────┬──────┘ └─────┬──────┘ └─────┬────┘ │
                         │              │              │              │      │
    =====================│==============│==============│==============│=======
       auth_net          ▼    cart_net  ▼  catalog_net ▼    order_net ▼
                   ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌──────────┐
                   │  auth-db   │ │  cart-db   │ │ catalog-db │ │ order-db │
                   │  (MySQL)   │ │  (Redis)   │ │  (MySQL)   │ │ (MySQL)  │
                   └────────────┘ └────────────┘ └────────────┘ └──────────┘
```

---

## 🛠️ Technology Stack

- **Frontend Web Layer (`webapp/`)**: React (Vite) + Tailwind CSS + Lucide Icons. Served on port `3000` via an Express production server wrapper.
- **Mobile Client Layer (`mobile_app/`)**: Flutter + Riverpod + GoRouter + Dio + Flutter Secure Storage. Mobile application offering dynamic developer IP configuration, Flipkart-inspired styling, real-time soft-reservation countdowns, and order/admin features.
- **API Gateway Layer (`krakend/`)**: Central entry-point on port `8080` executing HS256 JWT validation and propagating user claims to internal microservices via headers.
- **Auth Microservice (`auth-service/`)**: Python (Django 4.2+ & Gunicorn), issuing secure JWT tokens with array-encoded roles (`role: ["admin"]`).
- **Cart Microservice (`cart-service/`)**: Node.js & Express, interacting with Redis to manage active shopping carts and 5-minute soft-reservations.
- **Catalog Microservice (`catalog-service/`)**: Java 17 & Spring Boot, fetching soft-reservation metrics from the Cart microservice to dynamically adjust displayed stock quantities, and performing atomic database decrements.
- **Order Microservice (`order-service/`)**: Java 17 & Spring Boot, orchestrating checkouts, interacting with catalog and cart via Spring Cloud OpenFeign, and executing compensating rollback transactions upon catalog errors.

---

## ✨ Core Concurrency & Security Features

1. **Central Ingress Boundary**: Client browsers and mobile clients only interact with the React Webapp (`localhost:3000`), the Flutter mobile client, and the KrakenD Gateway (`localhost:8080`). Backend microservices and databases are isolated on private subnets.
2. **Soft-Reservation Pattern**: Cart items increment product reservation numbers in Redis with a 5-minute TTL. The Catalog service subtracts active reservations from displayed stock (`stockQuantity - reservations`) to give customers immediate, real-time inventory visibility.
3. **Atomic Concurrency Control**: Stock decrements are handled via a thread-safe, database-level update query:
   ```sql
   UPDATE products SET stock_quantity = stock_quantity - :quantity WHERE id = :id AND stock_quantity >= :quantity
   ```
   This prevents overselling (Lost Update anomalies) under high concurrency without using heavy JVM locks.
4. **Saga Compensating Transactions**: If order checkout fails mid-process (e.g. catalog stock runs out for one item in a multi-product cart), the Order service rolls back order saving and triggers HTTP calls to increment back stock for any successfully decremented items in that session.

---

## 🚀 How to Run Locally

### Running the Backend & Web App
You can spin up the entire multi-network microservice stack with a single command:

```bash
# Build and orchestrate all containers and networks
docker compose up -d --build
```

#### Access Endpoints:
- **Customer Dashboard & Admin Panel**: [http://localhost:3000](http://localhost:3000)
- **Central API Gateway**: [http://localhost:8080](http://localhost:8080)
- **Auth DB Web GUI (Adminer)**: [http://localhost:8085](http://localhost:8085)
- **Catalog DB Web GUI (Adminer)**: [http://localhost:8083](http://localhost:8083)
- **Order DB Web GUI (Adminer)**: [http://localhost:8084](http://localhost:8084)

### Running the Flutter Mobile App
To run the mobile app on a physical device (over a Wi-Fi hotspot) or an emulator:

1. **Prerequisites**: Make sure the Flutter SDK is installed and your device is connected/authorized via USB debugging.
2. **Install & Run**:
   ```bash
   cd mobile_app
   flutter pub get
   flutter run
   ```
3. **Configure Gateway IP**:
   - Tap the **Settings icon (cog wheel)** in the top-right of the login screen.
   - Enter your laptop's local IP address (e.g., `192.168.x.x` or `10.100.x.x`) on port `8080` (e.g., `http://192.168.1.10:8080`).
   - Save and proceed to log in.

### Default Credentials:
* **Admin Account**: `admin@gmail.com` / `admin`
* **Customer Account**: Register a new account directly in the app.
