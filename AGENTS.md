# AI Handoff & Architecture Blueprint - FlashSale Platform

This document serves as the absolute single source of truth for any developer or AI assistant (e.g. Claude Code, Cursor, Copilot) inheriting this repository. It documents the exact technical architecture, package dependencies, codebase map, active database schemas, and critical architectural guardrails required to maintain system integrity.

---

## 1. Project Overview

The **FlashSale Platform** is a containerized, microservices-based, high-concurrency e-commerce application designed to handle extremely high-traffic shopping rushes (flash sales) safely and reliably. 

### Core System Goals
* **Inventory Safety**: Prevent overselling and "Lost Update" anomalies when thousands of users attempt to purchase highly limited stock at the exact same millisecond.
* **Service Decoupling**: Separate high-read inventory search traffic (**Catalog Microservice**) from write-heavy transactional operations (**Order Microservice**).
* **Strict Network Isolation**: Isolate MySQL and Redis data layers from the public host machine, routing database traffic through private virtual bridge networks.
* **Soft-Reservations**: Reserve items temporarily in Redis when added to user carts, dynamically adjusting visible catalog stock, and automatically expiring reservations after 5 minutes.
* **Centralized API Ingress**: Secure and route all frontend client traffic through a central API Gateway (**KrakenD**) that handles CORS and JWT validation at the boundary.
* **Premium Client Experience**: Serve a responsive, real-time React web application with Flipkart-inspired styling, bounds-validated quantity controllers, a soft-reservation countdown timer, and simulated secure checkout loading overlays.

---

## 2. Tech Stack & Dependencies

The project is structured as a multi-directory monorepo containing five primary services and three databases compiled and run inside Docker containers.

### Frontend Layer (`webapp/`)
* **Runtime**: Node.js (`node:18-alpine`) + Vite
* **Web Framework**: React (`^18.3.1`) & React DOM (`^18.3.1`)
* **Icons & Assets**: Lucide React (`^0.378.0`)
* **Styling**: Tailwind CSS (`^3.4.3`) for modern, responsive UI styling
* **Http Client**: Axios (`^1.7.2`) for backend API requests via the KrakenD gateway
* **Production Server**: Express.js (`^4.19.2`) to serve the built static production assets on port `3000`

### API Gateway Layer (`krakend/`)
* **Gateway Engine**: KrakenD API Gateway (`krakend:latest`) listening on host port `8080`
* **Security & Routing**: Configured with CORS access, route forwarding, and JWT validation via `auth/validator`
* **JWT Claims Mapping**: Decodes user JWT signatures using a shared symmetric key, validating claims and propagating them as HTTP headers (`X-User-Id`, `X-User-Email`, `X-User-Role`) to internal services

### Authentication Microservice (`auth-service/`)
* **Runtime**: Python (`python:3.10-slim`)
* **Core Framework**: Django 4.2+ & Gunicorn (`gunicorn>=21.2.0`)
* **Database Driver**: `mysqlclient>=2.2.0`
* **Cryptography**: `bcrypt>=4.0.0` (Django bcrypt password hashing)
* **JWT Library**: PyJWT (`^2.8.0`) for signing token payloads with HS256 signatures

### Cart Microservice (`cart-service/`)
* **Runtime**: Node.js (`node:18-alpine`)
* **Core Framework**: Express.js (`^4.19.2`)
* **Database Client**: `redis` (`^4.6.13`) for fast cart operations and reservation TTL management

### Catalog Microservice (`catalog-service/`)
* **Runtime**: Java 17 (JBR / Alpine `eclipse-temurin:17-jre-alpine`)
* **Core Framework**: Spring Boot 3.2.5 (`spring-boot-starter-web`)
* **Persistence Layer**: Spring Data JPA (`spring-boot-starter-data-jpa`) + Hibernate
* **Database Driver**: MySQL Connector/J (`com.mysql:mysql-connector-j`)

### Order Microservice (`order-service/`)
* **Runtime**: Java 17 (JBR / Alpine `eclipse-temurin:17-jre-alpine`)
* **Core Framework**: Spring Boot 3.2.5 (`spring-boot-starter-web`)
* **Persistence Layer**: Spring Data JPA + Hibernate
* **Remote Clients**: Spring Cloud OpenFeign 2023.0.1 (`spring-cloud-starter-openfeign`) for declarative HTTP calls targeting `catalog-service` and `cart-service`

### Mobile Application Client (`mobile_app/`)
* **Runtime**: Flutter SDK (v3.29.3) & Dart
* **State Management**: Flutter Riverpod (`^2.5.1`) + StateNotifier
* **Navigation**: GoRouter (`^14.0.0`)
* **Http Client**: Dio (`^5.4.0`)
* **Secure Storage**: Flutter Secure Storage (`^9.0.0`) for JWT token and user persistence
* **Local Storage**: Shared Preferences (`^2.2.0`) for developer runtime IP settings
* **UI Icons**: Lucide Icons (`^0.378.0`)

### Database & Administration Layers
* **Database Engines**: 
  - MySQL 8.0: Three distinct, isolated containers (`auth-db`, `catalog-db`, and `order-db`)
  - Redis 7.0: One isolated Redis container (`cart-db`) for cart state and soft-reservations
* **Web GUI Administrators**: Adminer (`adminer:latest` on host ports `8083` (Catalog), `8084` (Order), and `8085` (Auth))

---

## 3. Architecture & Component Map

The platform is segregated across five isolated Docker virtual bridge networks:
1. `auth_net`: Connects `auth-db`, `auth-service`, and `authDB_GUI` privately.
2. `cart_net`: Connects `cart-db` and `cart-service` privately.
3. `catalog_net`: Connects `catalog-db`, `catalog-service`, and `catalogDB_GUI` privately.
4. `order_net`: Connects `order-db`, `order-service`, and `orderDB_GUI` privately.
5. `app_net`: Connects `krakend-gateway`, `auth-service`, `cart-service`, `catalog-service`, and `order-service` for internal microservice routing.

```
├── docker-compose.yml       # Primary Docker orchestration configuration
├── .gitignore               # Clean git exclusion policies (excludes Java target/ and Node node_modules/)
├── AGENTS.md                # AI handoff blueprint (this file)
├── README.md                # Developer onboarding and system architecture document
├── auth-db-init/
│   └── init.sql             # Auth user table schema and admin user seed
├── catalog-db-init/
│   └── init.sql             # Catalog schema definition and product seed data
├── auth-service/            # Django Authentication Microservice
│   ├── Dockerfile           # Python & Django Gunicorn container builder
│   ├── requirements.txt     # Python requirements (Django, bcrypt, PyJWT, mysqlclient)
│   ├── manage.py            # Django admin entry point
│   └── auth_service/
│       ├── settings.py      # App configurations & environment variables
│       ├── urls.py          # /api/auth/register and /api/auth/login routes
│       └── views.py         # Registration & JWT signing views (HS256)
├── cart-service/            # Node.js Cart & Soft-Reservation Microservice
│   ├── Dockerfile           # Express web runner
│   ├── package.json         # Service manifests
│   └── server.js            # Redis cart & active soft-reservation manager
├── catalog-service/         # Product Inventory Microservice
│   ├── Dockerfile           # Multi-stage Maven -> Alpine Temurin builder
│   ├── pom.xml              # Maven dependencies
│   └── src/main/
│       ├── resources/
│       │   └── application.properties  # Port 8081 configurations & MySQL connections
│       └── java/com/flashsale/catalogservice/
│           ├── CatalogServiceApplication.java # Spring Boot entry-point
│           ├── model/Product.java            # Product JPA entity mapping to "products" table
│           ├── repository/ProductRepository.java  # Declares database-level atomic decrements
│           └── controller/ProductController.java  # Product REST APIs & Soft-Reservation checks
├── order-service/           # Order Transaction Microservice
│   ├── Dockerfile           # Multi-stage Maven builder
│   ├── pom.xml              # Maven dependencies + Spring Cloud Feign
│   └── src/main/
│       ├── resources/
│       │   └── application.properties  # Port 8082 configurations & MySQL connections
│       └── java/com/flashsale/orderservice/
│           ├── OrderServiceApplication.java # Spring Boot entry-point with @EnableFeignClients
│           ├── model/Order.java             # Transaction JPA entity mapping to "orders" table
│           ├── repository/OrderRepository.java # Standard JpaRepository
│           ├── client/CatalogClient.java    # OpenFeign mappings targeting http://catalog-service:8081
│           ├── client/CartClient.java       # OpenFeign mappings targeting http://cart-service:5001
│           ├── dto/                         # DTO wrappers (ProductDto, CartItemDto)
│           └── controller/OrderController.java # Transaction controller (Checkout + stock decrement rollback)
├── krakend/                 # API Gateway Configurations
│   ├── krakend.json         # Endpoint configs, CORS, and JWT validation rules
│   └── symmetric.json       # Shared symmetric verification keys
└── webapp/                  # React Frontend client application
    ├── Dockerfile           # Multistage node-builder & express static runner
    ├── package.json         # Front-end packages manifest
    ├── vite.config.js       # Vite build configurations
    ├── index.html           # SPA root HTML template
    ├── server.js            # Express server to run the React production build on port 3000
    └── src/
        ├── App.jsx          # Main application page router, timer, and state manager
        ├── api.js           # Axios client configured with KrakenD base URL & authorization interceptor
        ├── components/      # AdminDashboard, AuthModal, CartPage, Navbar, OrderHistoryPage, StorePage
        └── context/         # AuthContext state provider
├── mobile_app/              # Flutter Mobile Client Application
│   ├── android/             # Android configurations (includes network security specs for local cleartext HTTP)
│   ├── ios/                 # iOS project configuration files
│   ├── lib/                 # Core Flutter sources (Feature-First architecture)
│   │   ├── core/            # App theme, secure storage utilities, Dio configuration, custom exception failures
│   │   ├── features/        # Feature modules: auth, catalog, cart, orders, admin, dev_settings
│   │   └── main.dart        # Flutter application entry point
│   ├── test/                # Test suite containing mock storage & unit verification tests
│   └── pubspec.yaml         # Project dependency manifest
```

---

## 4. Current State & Implementation Progress

All components have been fully coded, validated, compiled, and successfully pushed to the repository:

### Core Workflows Completed
* **API Gateway Ingress Boundary**: Set up KrakenD on port 8080. Client browsers communicate solely with the KrakenD gateway. Downstream internal ports (`8000`, `5001`, `8081`, `8082`) are protected.
* **Shared-Key JWT Security & Role Verification**: Django `auth-service` issues HS256 tokens containing user roles and user IDs. The KrakenD API Gateway validates these tokens cryptographically at the ingress boundary using a shared symmetric key, forwarding user context downstream via headers (`X-User-Id` and `X-User-Role`).
* **JWT Array Structure Adaptation**: Structured the token role claim inside `auth-service` views as a list (JSON array: `"role": ["admin"]`) to satisfy KrakenD's strict role-matching requirements, resolving dashboard 403 authorization issues.
* **Soft-Reservation Pattern**: Implemented Redis-based soft reservations inside `cart-service`. When users add items to their carts, `cart-service` increments the product's reservation count with a 5-minute (300-second) TTL.
* **Virtual Catalog Stock representation**: Modified `catalog-service` to query the active reservation count from the `cart-service` and subtract it from physical database stock, preventing users from adding over-allocated items to their carts.
* **Atomic Concurrency Control**: Written database-level query `UPDATE products SET stock_quantity = stock_quantity - :quantity WHERE id = :id AND stock_quantity >= :quantity` in `ProductRepository` to handle parallel stock subtractions safely at the catalog database.
* **Compensating Transaction Orchestration**: Configured `@Transactional` on `checkout` in `OrderController`. During checkout, the Order service:
  1. Retrieves the user's cart from `cart-service`.
  2. Calls `catalog-service` via OpenFeign to decrement stock item-by-item.
  3. Saves the Order and OrderItems to `order_db`.
  4. Triggers `cart-service` clear cart endpoint.
  If any stock decrement fails (e.g., due to insufficient stock or parallel rush purchases), the transaction catches the error, triggers compensating HTTP calls to increment back stock for any successfully decremented items in that session, and rolls back the order database state.
* **Rupees Translation**: Replaced all USD ($) symbols with Indian Rupees (**₹**).
* **React Single Page App**: Designed a state-of-the-art React web application under `/webapp` with real-time reservation timers, Flipkart layouts, a secure checkout simulation overlay, order history page, and custom administrator CRUD dashboard.
* **Flutter Mobile App Clone**: Built and validated a production-grade Flutter clone under `/mobile_app` mirroring all React client API requests, secure JWT verification headers, 5-minute cart reservation countdown banner mechanics, saga error handling checkout overlays, and admin inventory CRUD actions.
* **Hotspot Cleartext & NDK Resolution**: Configured custom Android network security permission files allowing HTTP communication over local Wi-Fi hotspots, and commented out standard Gradle NDK checks to compile on local machines without C++ NDK toolchains.

---

## 5. Development Guardrails & Rules for Future Agents

Any downstream agent or developer editing this codebase must respect the following architectural guardrails:

> [!CAUTION]
> 1. **No JPA Joins Across Services**: Under no circumstances should `Order` contain a JPA join (`@ManyToOne`, `@OneToMany`, or `@JoinColumn`) pointing to `Product`. They live in separate databases on separate networks. Keep `product_id` as a plain `Long`.
> 2. **Never Expose MySQL or Redis Ports (3306, 6379)**: Keep database ports closed to the host machine. Database administration must only be conducted through the host-exposed Adminer GUIs (8083, 8084, and 8085) or through internal container shell access.
> 3. **High-Concurrency Decoupling**: If modifying stock deduction logic, never subtract stock in Java memory. You must perform deduction using the atomic repository query to prevent race conditions.
> 4. **Keep Prices Immutable**: When saving an order, always snap the unit price from the Catalog service via Feign at the exact millisecond of checkout. Never recalculate pricing on-the-fly from the catalog at a later date, as catalog prices will fluctuate.
> 5. **Gateway Ingress Routing**: The client browser must NEVER communicate directly with internal services. All browser-side AJAX requests must be sent to the KrakenD Gateway (`http://localhost:8080`).
> 6. **Trust Gateway Claims Propagation**: Do not re-verify JWT signatures inside downstream microservices (`cart-service`, `catalog-service`, `order-service`). Trust and extract the `X-User-Id` and `X-User-Role` headers injected by KrakenD.
> 7. **Mock Native Storage in Flutter Tests**: When writing widget or unit tests for the Flutter client, always mock platform-specific channels (e.g. `FlutterSecureStorage` or `SharedPreferences`) to prevent test executor failures due to missing binary messenger channels.
> 8. **Follow Feature-First Directory Layout**: Keep mobile client additions organized by feature module (`mobile_app/lib/features/`). Ensure proper segregation of data repository, domain models, and presentation controllers.
