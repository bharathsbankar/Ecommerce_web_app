# API Contract: FlashDash Deals Platform

This document describes all the API endpoints exposed by the KrakenD API Gateway (port `8080`) that the Flutter mobile application will integrate with.

---

## 1. Authentication Service (`auth-service`)

All auth endpoints are public.

### `POST /api/auth/register`
*   **Authentication**: None (Public)
*   **Request Body (`application/json`)**:
    ```json
    {
      "email": "user@example.com",
      "username": "user123",
      "password": "mysecretpassword",
      "role": "customer"  // Options: "customer", "admin" (defaults to "customer")
    }
    ```
*   **Response (201 Created)**:
    ```json
    {
      "message": "Registration successful",
      "user": {
        "id": 1,
        "email": "user@example.com",
        "username": "user123",
        "role": "customer"
      }
    }
    ```
*   **Response (400 Bad Request)**:
    ```json
    {
      "error": "Email already registered"  // or "Username already taken"
    }
    ```

### `POST /api/auth/login`
*   **Authentication**: None (Public)
*   **Request Body (`application/json`)**:
    ```json
    {
      "email": "user@example.com",
      "password": "mysecretpassword"
    }
    ```
*   **Response (200 OK)**:
    ```json
    {
      "token": "eyJhbGciOiJIUzI1NiIs...",
      "user": {
        "id": 1,
        "email": "user@example.com",
        "username": "user123",
        "role": "customer"
      }
    }
    ```
*   **Response (401 Unauthorized)**:
    ```json
    {
      "error": "Invalid credentials"
    }
    ```

---

## 2. Product Catalog Service (`catalog-service`)

### `GET /api/products`
*   **Authentication**: None (Public)
*   **Response (200 OK)**:
    ```json
    [
      {
        "id": 1,
        "name": "iPhone 15 Pro",
        "description": "128GB, Blue Titanium",
        "price": 134900.00,
        "stockQuantity": 10  // This value is dynamically adjusted (stockQuantity - activeRedisReservations)
      }
    ]
    ```

### `GET /api/products/{id}`
*   **Authentication**: None (Public)
*   **Response (200 OK)**:
    ```json
    {
      "id": 1,
      "name": "iPhone 15 Pro",
      "description": "128GB, Blue Titanium",
      "price": 134900.00,
      "stockQuantity": 10
    }
    ```
*   **Response (404 Not Found)**:
    ```json
    {
      "timestamp": "2026-06-19T20:00:00Z",
      "status": 404,
      "error": "Not Found",
      "message": "Product not found with ID: 1",
      "path": "/api/products/1"
    }
    ```

### `POST /api/products` (Create Product)
*   **Authentication**: JWT Token Required (Header: `Authorization: Bearer <token>`)
*   **Required Role**: `admin`
*   **Request Body (`application/json`)**:
    ```json
    {
      "name": "New Gaming Mouse",
      "description": "Wireless RGB gaming mouse",
      "price": 4500.00,
      "stockQuantity": 30
    }
    ```
*   **Response (201 Created)**:
    ```json
    {
      "id": 4,
      "name": "New Gaming Mouse",
      "description": "Wireless RGB gaming mouse",
      "price": 4500.00,
      "stockQuantity": 30
    }
    ```

### `PUT /api/products/{id}` (Update Product)
*   **Authentication**: JWT Token Required (Header: `Authorization: Bearer <token>`)
*   **Required Role**: `admin`
*   **Request Body (`application/json`)**:
    ```json
    {
      "name": "New Gaming Mouse v2",
      "description": "Wireless RGB gaming mouse, upgraded sensor",
      "price": 4900.00,
      "stockQuantity": 25
    }
    ```
*   **Response (200 OK)**:
    ```json
    {
      "id": 4,
      "name": "New Gaming Mouse v2",
      "description": "Wireless RGB gaming mouse, upgraded sensor",
      "price": 4900.00,
      "stockQuantity": 25
    }
    ```

### `DELETE /api/products/{id}` (Delete Product)
*   **Authentication**: JWT Token Required (Header: `Authorization: Bearer <token>`)
*   **Required Role**: `admin`
*   **Response (200 OK)**:
    *   **Body**: `Product deleted successfully` (Plain Text)

---

## 3. Cart & Soft-Reservation Service (`cart-service`)

All endpoints in this section require authentication.

### `GET /api/cart`
*   **Authentication**: JWT Token Required (Header: `Authorization: Bearer <token>`)
*   **Response (200 OK)**:
    ```json
    {
      "userId": "1",
      "items": [
        {
          "productId": 1,
          "quantity": 2
        }
      ]
    }
    ```

### `POST /api/cart` (Add/Update Cart Item)
*   **Authentication**: JWT Token Required (Header: `Authorization: Bearer <token>`)
*   **Request Body (`application/json`)**:
    ```json
    {
      "productId": 1,
      "quantity": 3  // Setting to 0 removes the product from the cart
    }
    ```
*   **Response (200 OK)**:
    ```json
    {
      "message": "Cart updated successfully",
      "productId": 1,
      "quantity": 3
    }
    ```
*   **Note**: Incrementing or adding a product triggers a soft-reservation in Redis for 300 seconds (5 minutes). This is managed client-side in the UI via a 5-minute countdown timer that resets when the cart is modified.

### `DELETE /api/cart/{productId}` (Remove Item)
*   **Authentication**: JWT Token Required (Header: `Authorization: Bearer <token>`)
*   **Response (200 OK)**:
    ```json
    {
      "message": "Product removed from cart"
    }
    ```

### `DELETE /api/cart` (Clear Cart)
*   **Authentication**: JWT Token Required (Header: `Authorization: Bearer <token>`)
*   **Response (200 OK)**:
    ```json
    {
      "message": "Cart cleared successfully"
    }
    ```

---

## 4. Order Service (`order-service`)

All endpoints require authentication. The service extracts the user ID from the gateway-forwarded header `X-User-Id`.

### `POST /api/orders/checkout`
*   **Authentication**: JWT Token Required (Header: `Authorization: Bearer <token>`)
*   **Response (201 Created)**:
    ```json
    {
      "id": 12,
      "userId": 1,
      "grandTotal": 269800.00,
      "createdAt": "2026-06-19T20:00:00Z",
      "items": [
        {
          "id": 15,
          "productId": 1,
          "quantity": 2,
          "perUnitPrice": 134900.00,
          "totalPrice": 269800.00
        }
      ]
    }
    ```
*   **Response (400 Bad Request - Concurrency/Stock Failure)**:
    *   **Body**: `Failed to reserve stock for product: iPhone 15 Pro due to parallel checkout. Please try again.` (Plain Text)
    *   **Or (JSON Exception shape if triggered downstream)**:
        ```json
        {
          "timestamp": "2026-06-19T20:00:00Z",
          "status": 400,
          "error": "Bad Request",
          "message": "Insufficient stock for product ID: 1. Available: 0",
          "path": "/api/orders/checkout"
        }
        ```
    *   **Handling**: The client app must be prepared to handle both a plain text error string and the standard Spring JSON exception shape, extracting the `message` to show which item failed.

### `GET /api/orders/history`
*   **Authentication**: JWT Token Required (Header: `Authorization: Bearer <token>`)
*   **Response (200 OK)**:
    ```json
    [
      {
        "id": 12,
        "userId": 1,
        "grandTotal": 269800.00,
        "createdAt": "2026-06-19T20:00:00Z",
        "items": [
          {
            "id": 15,
            "productId": 1,
            "quantity": 2,
            "perUnitPrice": 134900.00,
            "totalPrice": 269800.00
          }
        ]
      }
    ]
    ```
