# Project Report: Microservices-Driven E-Commerce Application with API-First Design

This document provides a comprehensive, end-to-end technical overview of the **High-Concurrency FlashSale E-Commerce Platform**. It has been designed specifically to serve as a high-fidelity reference file for Gemini and other Large Language Models (LLMs) to ingest and generate complete academic, technical, or architecture reports.

---

## 1. Project Introduction & System Goals

The **FlashSale Platform** is a containerized, microservices-based, high-concurrency e-commerce application designed to handle extremely high-traffic shopping rushes (flash sales) safely and reliably. 

### Core System Goals
* **Inventory Safety (Over-selling Prevention)**: Prevent stock quantities from dropping below zero. When thousands of users attempt to purchase a highly limited item at the exact same millisecond, the system must process requests atomically and reject excess orders.
* **Service Decoupling (High-Read/Write Separation)**: Separate read-intensive catalog operations (searching for products, viewing quantities) from write-intensive checkout transactions (deducting stock, creating order rows).
* **Strict Network Isolation**: Keep databases (MySQL and Redis instances) completely isolated from the host machine and public access. Route all downstream database traffic through private virtual bridge networks.
* **Soft-Reservations (Redis TTL Pattern)**: Temporarily reserve stock in memory (Redis) when added to a shopping cart, which dynamically adjusts visible catalog stock. Automatically expire reservations and restore stock visibility if checkout is not completed within 5 minutes.
* **API-First Ingress (KrakenD Gateway)**: Secure all downstream services by routing client traffic through a central API Gateway. Perform JWT verification, CORS management, and claims propagation at the outer boundary.
* **Premium Client Experience**: Provide unified web and mobile clients (React and Flutter) that mirror the platform's API-first contracts, displaying real-time reservation timers, Flipkart-inspired styles, and bounds-validated quantity adjustments.

---

## 2. Monorepo Directory Layout & Language Stack

The codebase is structured as a multi-directory monorepo:

```
├── docker-compose.yml       # Docker container orchestration & virtual subnet routing
├── auth-db-init/
│   └── init.sql             # SQL Schema & Seed script for the Authentication database
├── catalog-db-init/
│   └── init.sql             # SQL Schema & Seed script for the Catalog database
├── auth-service/            # Django (Python 3.10) Authentication Service
│   ├── Dockerfile           # Multi-stage Python runner (Gunicorn + Django)
│   ├── requirements.txt     # Service dependencies (Django, bcrypt, PyJWT, mysqlclient)
│   └── auth_service/
│       ├── settings.py      # App configurations & environment variables
│       ├── urls.py          # /api/auth/register and /api/auth/login route maps
│       └── views.py         # Bcrypt-hashed registration & HS256 JWT signing views
├── cart-service/            # Node.js Cart & Soft-Reservation Service
│   ├── Dockerfile           # Express container builder
│   ├── package.json         # Node dependencies (express, redis, dotenv)
│   └── server.js            # Redis cart CRUD & reservation TTL tracker
├── catalog-service/         # Spring Boot (Java 17) Catalog & Inventory Service
│   ├── pom.xml              # Maven dependencies (Spring Data JPA, MySQL Connector/J)
│   └── src/main/
│       ├── resources/
│       │   └── application.properties  # Database connection strings & internal URLs
│       └── java/com/flashsale/catalogservice/
│           ├── model/Product.java            # Product JPA Entity (products table)
│           ├── repository/ProductRepository.java  # Thread-safe database update queries
│           └── controller/ProductController.java  # Virtual stock calculations & stock adjustment APIs
├── order-service/           # Spring Boot (Java 17) Order Transaction Service
│   ├── pom.xml              # Maven dependencies (+ Spring Cloud OpenFeign client)
│   └── src/main/
│       └── java/com/flashsale/orderservice/
│           ├── client/CatalogClient.java    # Declarative OpenFeign client targeting catalog-service
│           ├── client/CartClient.java       # Declarative OpenFeign client targeting cart-service
│           ├── model/Order.java             # Order JPA Entity (orders table)
│           ├── model/OrderItem.java         # OrderItem JPA Entity (order_items table)
│           └── controller/OrderController.java # Checkout orchestrator (Saga compensating rollback)
├── krakend/                 # KrakenD API Gateway configurations
│   ├── krakend.json         # CORS policies, route maps, and JWT validation rules
│   └── symmetric.json       # Shared symmetric verification keys
├── webapp/                  # React (Vite/Tailwind) Customer & Admin Web Panel
│   ├── src/
│   │   ├── App.jsx          # Router, Reservation Countdown Timer & Global UI state
│   │   ├── api.js           # Central Axios HTTP client (JWT header interceptors)
│   │   └── components/      # StorePage, CartPage, OrderHistoryPage, AdminDashboard
│   └── server.js            # Express server to serve production Vite build on port 3000
└── mobile_app/              # Flutter (Dart) Android & iOS Mobile Client
    ├── lib/
    │   ├── core/            # Theme, secure storage client, Dio HTTP config, cleartext HTTP setup
    │   ├── features/        # Auth, catalog (store), cart, orders (checkout), admin CRUD
    │   └── main.dart        # Application bootstrap entry point
```

---

## 3. High-Level Architectural Topology

To enforce strict security and network boundaries, the services and databases are isolated across **five virtual private subnets (Docker bridge networks)**:

1. `auth_net`: Restricts `auth-db` (MySQL) to be accessible only by `auth-service`.
2. `cart_net`: Restricts `cart-db` (Redis) to be accessible only by `cart-service`.
3. `catalog_net`: Restricts `catalog-db` (MySQL) to be accessible only by `catalog-service`.
4. `order_net`: Restricts `order-db` (MySQL) to be accessible only by `order-service`.
5. `app_net`: The private application network. Connects `krakend-gateway`, `auth-service`, `cart-service`, `catalog-service`, and `order-service` for internal RPC and API forwarding.

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

*Note: Client browsers and mobile clients only communicate with the KrakenD Gateway (`localhost:8080`) or WebApp (`localhost:3000`). Database ports (3306, 6379) and service ports (8000, 5001, 8081, 8082) are entirely closed to the host machine. Database management is performed securely through container shell access or isolated Adminer GUIs mapping only admin ports (8083, 8084, 8085).*

---

## 4. Database Architecture & Schemas

### 4.1 Authentication Database (`auth_db` MySQL 8.0)
Stores security credentials and user definitions. The schema maps to Django's user engine.

```sql
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL, -- Bcrypt-hashed password string
    role VARCHAR(50) DEFAULT 'customer', -- Role field ('customer' or 'admin')
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email (email)
);
```

### 4.2 Catalog Database (`catalog_db` MySQL 8.0)
Stores product catalogs, pricing, and physical stock counts. Includes a check constraint to prevent negative stock at the database level.

```sql
CREATE TABLE IF NOT EXISTS products (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INT NOT NULL,
    CONSTRAINT chk_stock CHECK (stock_quantity >= 0)
);
```

### 4.3 Order Database (`order_db` MySQL 8.0)
Stores customer order summaries and item line transactions.
* **`orders` Table**:
  - `id`: BIGINT (Primary Key)
  - `user_id`: BIGINT (Indexed reference, no foreign key to decoupled `auth_db`)
  - `grand_total`: DECIMAL(10, 2)
  - `created_at`: TIMESTAMP
* **`order_items` Table**:
  - `id`: BIGINT (Primary Key)
  - `order_id`: BIGINT (Foreign Key referencing `orders.id`)
  - `product_id`: BIGINT (Plain Reference, no JPA Join to decoupled `catalog_db`)
  - `quantity`: INT
  - `price`: DECIMAL(10, 2) (Immutable price snap at checkout time)

---

## 5. Microservices Implementation & Core Codes

### 5.1 KrakenD API Gateway (`krakend/`)
KrakenD serves as the central entry-point (port 8080). It provides CORS headers, maps external routing endpoints to internal service routes, performs JWT authentication validator checks, and injects validated payload fields downstream as headers (`X-User-Id`, `X-User-Email`, `X-User-Role`).

#### Core Gateway Configuration Code (`krakend.json` snippet)
```json
{
  "version": 3,
  "port": 8080,
  "name": "FlashSale API Gateway",
  "extra_config": {
    "security/cors": {
      "allow_origins": ["*"],
      "allow_methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
      "allow_headers": ["Origin", "Authorization", "Content-Type", "X-User-Id", "X-User-Role"]
    }
  },
  "endpoints": [
    {
      "endpoint": "/api/orders/checkout",
      "method": "POST",
      "output_encoding": "no-op",
      "input_headers": ["*"],
      "extra_config": {
        "auth/validator": {
          "alg": "HS256",
          "jwk_local_path": "/etc/krakend/symmetric.json",
          "disable_jwk_security": true,
          "propagate_claims": [
            ["user_id", "X-User-Id"],
            ["email", "X-User-Email"],
            ["role", "X-User-Role"]
          ]
        }
      },
      "backend": [
        {
          "url_pattern": "/api/orders/checkout",
          "encoding": "no-op",
          "host": ["http://order-service:8082"],
          "method": "POST"
        }
      ]
    }
  ]
}
```

---

### 5.2 Authentication Microservice (`auth-service/`)
Built with Python 3.10 and Django. On registration, passwords are encrypted using Django's default bcrypt-hashing algorithm. On successful login, the service issues an HS256 JWT token signed with a shared secret key.
* **Role claims array**: KrakenD's JWT validator requires roles to be structured as a JSON array (e.g., `role: ["admin"]` instead of `role: "admin"`). The login view implements this array format.

#### Login View Implementation (`auth-service/auth_service/views.py` snippet)
```python
@csrf_exempt
def login_view(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)
    try:
        data = json.loads(request.body)
        email = data.get('email')
        password = data.get('password')
        
        user = User.objects.get(email=email)
        if not user.check_password(password):
            return JsonResponse({'error': 'Invalid credentials'}, status=401)
            
        # Structure claims to conform to KrakenD roles configuration
        payload = {
            'user_id': user.id,
            'email': user.email,
            'role': [user.role], # Decoded downstream as ['customer'] or ['admin']
            'exp': datetime.utcnow() + timedelta(hours=24)
        }
        token = jwt.encode(payload, JWT_SECRET, algorithm='HS256', headers={'kid': 'flashsale-key-id'})
        if isinstance(token, bytes):
            token = token.decode('utf-8')
            
        return JsonResponse({
            'token': token,
            'user': {
                'id': user.id,
                'email': user.email,
                'username': user.username,
                'role': user.role
            }
        }, status=200)
    except User.DoesNotExist:
        return JsonResponse({'error': 'Invalid credentials'}, status=401)
```

---

### 5.3 Cart & Soft-Reservation Microservice (`cart-service/`)
Built with Node.js, Express, and Redis. It manages active customer carts and implements the **Soft-Reservation Pattern**.
* **Cart state storage**: Stored as Redis Hashes (`cart:userId` maps `productId` -> `quantity`).
* **Soft-Reservations storage**: Stored as a simple Redis String (`reservation:productId`) tracking the cumulative sum of items currently sitting in active carts. When a customer adds items to their cart:
  1. The cart service computes the delta between the requested quantity and their current cart quantity.
  2. It updates the reservation string count atomically using Redis `incrBy`.
  3. It attaches a 5-minute (300 seconds) Time-To-Live (TTL) on the reservation key via Redis `expire`.

#### Cart & Reservation Manager (`cart-service/server.js` snippet)
```javascript
// Add or update cart item & soft-reservation delta
app.post('/api/cart', async (req, res) => {
    const userId = req.headers['x-user-id']; // Injected by API Gateway
    const { productId, quantity } = req.body;
    const qty = parseInt(quantity, 10);

    try {
        const cartKey = `cart:${userId}`;
        const resKey = `reservation:${productId}`;

        // Fetch current quantity in user cart to compute delta
        const currentQtyStr = await redisClient.hGet(cartKey, productId.toString());
        const currentQty = currentQtyStr ? parseInt(currentQtyStr, 10) : 0;
        const diff = qty - currentQty;

        if (diff > 0) {
            // Increment soft-reservation count in Redis with a 5-minute TTL (300s)
            await redisClient.incrBy(resKey, diff);
            await redisClient.expire(resKey, 300);
        } else if (diff < 0) {
            // Decrement soft-reservation count
            const newVal = await redisClient.incrBy(resKey, diff);
            if (newVal < 0) await redisClient.set(resKey, '0');
        }

        // Save new item quantity to cart hash
        if (qty > 0) {
            await redisClient.hSet(cartKey, productId.toString(), qty.toString());
        } else {
            await redisClient.hDel(cartKey, productId.toString());
        }

        return res.json({ message: 'Cart updated successfully', productId, quantity: qty });
    } catch (err) {
        return res.status(500).json({ error: err.message });
    }
});

// Retrieve active reservation count (Called internally by Catalog Service)
app.get('/api/cart/reservations/:productId', async (req, res) => {
    const { productId } = req.params;
    try {
        const resKey = `reservation:${productId}`;
        const value = await redisClient.get(resKey);
        const count = value ? parseInt(value, 10) : 0;
        
        res.setHeader('Content-Type', 'text/plain');
        return res.send(count.toString());
    } catch (err) {
        return res.status(500).send('0');
    }
});
```

---

### 5.4 Catalog Microservice (`catalog-service/`)
Built with Java 17 and Spring Boot. It manages the product catalog stored in `catalog_db`. 
* **Virtual stock calculation**: When clients query products (`GET /api/products`), the Catalog service performs a REST call to `cart-service` to retrieve active Redis reservation counts. It subtracts these reservations from physical database stock on-the-fly (`Virtual Stock = Database Stock - Reservations`). This prevents users from adding over-allocated items to their carts.
* **Atomic Concurrency Stock Decrement**: Uses a thread-safe database-level query:
  `UPDATE products SET stock_quantity = stock_quantity - :quantity WHERE id = :id AND stock_quantity >= :quantity`
  This query avoids race conditions (Lost Update anomalies) under multi-thread concurrent requests, relying on MySQL's row-level lock.

#### Atomic Stock Repository (`catalog-service/src/main/java/com/flashsale/catalogservice/repository/ProductRepository.java`)
```java
package com.flashsale.catalogservice.repository;

import com.flashsale.catalogservice.model.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

public interface ProductRepository extends JpaRepository<Product, Long> {

    @Modifying
    @Transactional
    @Query("UPDATE Product p SET p.stockQuantity = p.stockQuantity - :quantity " +
           "WHERE p.id = :id AND p.stockQuantity >= :quantity")
    int decrementStock(@Param("id") Long id, @Param("quantity") Integer quantity);

    @Modifying
    @Transactional
    @Query("UPDATE Product p SET p.stockQuantity = p.stockQuantity + :quantity " +
           "WHERE p.id = :id")
    int incrementStock(@Param("id") Long id, @Param("quantity") Integer quantity);
}
```

#### Virtual Stock Calculation & API endpoints (`catalog-service/src/main/java/com/flashsale/catalogservice/controller/ProductController.java` snippet)
```java
@RestController
@RequestMapping("/api/products")
public class ProductController {

    private final ProductRepository productRepository;
    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${cart.service.url:http://cart-service:5001}")
    private String cartServiceUrl;

    public ProductController(ProductRepository productRepository) {
        this.productRepository = productRepository;
    }

    private int getReservations(Long productId) {
        try {
            String url = cartServiceUrl + "/api/cart/reservations/" + productId;
            String countStr = restTemplate.getForObject(url, String.class);
            return countStr != null ? Integer.parseInt(countStr.trim()) : 0;
        } catch (Exception e) {
            return 0;
        }
    }

    @GetMapping
    public List<Product> getAllProducts() {
        List<Product> products = productRepository.findAll();
        for (Product p : products) {
            int reservations = getReservations(p.getId());
            // Adjust displayed stock on-the-fly based on Redis reservations
            p.setStockQuantity(Math.max(0, p.getStockQuantity() - reservations));
        }
        return products;
    }

    @PutMapping("/{id}/decrement")
    public ResponseEntity<?> decrementStock(@PathVariable Long id, @RequestParam Integer quantity) {
        // Enforce DB safety via atomic decrement Repository query
        int rowsUpdated = productRepository.decrementStock(id, quantity);
        if (rowsUpdated == 0) {
            return ResponseEntity.badRequest().body("Insufficient stock at database level.");
        }
        Product updatedProduct = productRepository.findById(id).orElseThrow();
        return ResponseEntity.ok(updatedProduct);
    }
}
```

---

### 5.5 Order Microservice (`order-service/`)
Built with Java 17, Spring Boot, and Spring Cloud OpenFeign. It manages hard checkout transactions. 
* **Saga Orchestrator with Compensating Transactions**: The checkout method is annotated with `@Transactional`. During checkout, it:
  1. Calls `cart-service` via OpenFeign to fetch the user's cart.
  2. Loops through cart items and issues a Feign call to decrement stock in the `catalog-service`.
  3. If a stock decrement fails (e.g. stock falls below 0, catalog exception, network failure):
     - The transaction catches the exception.
     - **Compensating Transaction**: It rolls back database saves and loops through all products that *were* successfully decremented in that session, calling catalog's increment endpoint to restore stock.
  4. If all decrements succeed, it saves the Order and OrderItem records to `order_db` and triggers a cart-clear HTTP command to `cart-service`.
* **Price Immutability**: Captures the exact catalog unit price at the checkout millisecond and records it in `order_items` rather than reading catalog prices on-the-fly at runtime later.

#### Checkout Transaction Orchestrator (`order-service/src/main/java/com/flashsale/orderservice/controller/OrderController.java` snippet)
```java
@PostMapping("/checkout")
@Transactional
public ResponseEntity<?> checkout(@RequestHeader("X-User-Id") String userIdStr) {
    Long userId = Long.parseLong(userIdStr);

    // 1. Fetch user cart items
    List<CartItemDto> cartItems = cartClient.getCartItems(userId);
    if (cartItems == null || cartItems.isEmpty()) {
        return ResponseEntity.badRequest().body("Cart is empty.");
    }

    List<CartItemDto> successfulDecrements = new ArrayList<>();
    BigDecimal grandTotal = BigDecimal.ZERO;
    List<OrderItem> orderItems = new ArrayList<>();

    try {
        for (CartItemDto item : cartItems) {
            Long productId = item.getProductId();
            Integer quantity = item.getQuantity();

            // Fetch pricing details at exact checkout millisecond
            ProductDto product = catalogClient.getProductById(productId);

            // Execute atomic decrement call to Catalog Service
            try {
                catalogClient.decrementStock(productId, quantity);
                successfulDecrements.add(item); // Track for compensating rollback
            } catch (Exception ex) {
                throw new InsufficientStockException("Insufficient stock for product " + product.getName() + " under parallel rush.");
            }

            // Create immutable order item record
            BigDecimal itemPrice = product.getPrice();
            OrderItem orderItem = new OrderItem(productId, quantity, itemPrice);
            orderItems.add(orderItem);
            grandTotal = grandTotal.add(orderItem.getTotalPrice());
        }

        // Save order and items to Order DB
        Order order = new Order();
        order.setUserId(userId);
        order.setGrandTotal(grandTotal);
        orderItems.forEach(order::addItem);
        Order savedOrder = orderRepository.save(order);

        // Clear cart (soft reservation counts are automatically decremented by Cart Service)
        cartClient.clearCart(userId);

        return ResponseEntity.status(HttpStatus.CREATED).body(savedOrder);

    } catch (Exception e) {
        // COMPENSATING TRANSACTION: Revert all successful stock decrements
        System.err.println("Checkout failed! Triggering compensating rollback. Reason: " + e.getMessage());
        for (CartItemDto revertedItem : successfulDecrements) {
            try {
                catalogClient.incrementStock(revertedItem.getProductId(), revertedItem.getQuantity());
            } catch (Exception ex) {
                System.err.println("CRITICAL: Failed to revert stock decrement for product " + revertedItem.getProductId());
            }
        }
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
    }
}
```

---

## 6. Concurrency Control & Safety Strategy (Summary for LLMs)

To handle thousands of parallel hits safely without crash loops or data anomalies, the platform implements these architectural patterns:

| Concurrency Challenge | Traditional Risk | Our Strategy | Details |
| :--- | :--- | :--- | :--- |
| **Lost Update (Overselling)** | Two threads read stock quantity `1`, both write decrement, stock goes to `-1`. | **Atomic database-level updates** | Row-level locking query (`UPDATE p SET stock = stock - q WHERE id = :id AND stock >= q`). Requires no synchronization locks in JVM memory. |
| **Database Write Lock Bottlenecks** | Adding items to carts requires writing to disk, leading to locking overhead. | **In-memory Soft-Reservations** | Items added to carts increment a Redis count. When querying, the virtual stock is calculated on-the-fly (`Stock - Redis reservations`). |
| **Orphaned Cart Stock Lockups** | Users add items to carts but never complete checkout, locking stock indefinitely. | **Redis TTL Expiration** | Reservation keys have a 5-minute Time-to-Live (TTL). Once expired, stock is automatically released back to the catalog. |
| **Distributed Data Inconsistency** | Decrement succeeds in Catalog, but saving fails in Order, leaving orphaned stock updates. | **Saga Orchestrator + Compensating Transactions** | The Order service catches checkout exceptions and makes HTTP callback requests to increment stock back for any modified items. |

---

## 7. Configuration & Local Execution Guide

### 7.1 Spin up the Infrastructure via Docker Compose
All networks and services build and orchestrate automatically:

```bash
docker compose up -d --build
```

### 7.2 Service Address Reference (Host Mappings)
* **Frontend Dashboard**: [http://localhost:3000](http://localhost:3000)
* **API Gateway Routing Entrypoint**: [http://localhost:8080](http://localhost:8080)
* **Catalog Database GUI (Adminer)**: [http://localhost:8083](http://localhost:8083) (Credentials: Server `catalog-db`, Username `root`, Password `rootpassword`, Database `catalog_db`)
* **Order Database GUI (Adminer)**: [http://localhost:8084](http://localhost:8084) (Credentials: Server `order-db`, Username `root`, Password `rootpassword`, Database `order_db`)
* **Auth Database GUI (Adminer)**: [http://localhost:8085](http://localhost:8085) (Credentials: Server `auth-db`, Username `root`, Password `rootpassword`, Database `auth_db`)

### 7.3 Default Authentication Credentials
* **Admin Login**: Email `admin@gmail.com` / Password `admin` (Initial Admin seeded via `auth-db-init/init.sql`)
* **Customer Login**: Register any new account through the client UI (role defaults to `customer`).
