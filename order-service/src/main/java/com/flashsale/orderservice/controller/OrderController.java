package com.flashsale.orderservice.controller;

import com.flashsale.orderservice.client.CatalogClient;
import com.flashsale.orderservice.client.CartClient;
import com.flashsale.orderservice.dto.CartItemDto;
import com.flashsale.orderservice.dto.ProductDto;
import com.flashsale.orderservice.model.Order;
import com.flashsale.orderservice.model.OrderItem;
import com.flashsale.orderservice.repository.OrderRepository;
import com.flashsale.orderservice.exception.ProductNotFoundException;
import com.flashsale.orderservice.exception.InsufficientStockException;
import feign.FeignException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/orders")
public class OrderController {

    private final OrderRepository orderRepository;
    private final CatalogClient catalogClient;
    private final CartClient cartClient;

    public OrderController(OrderRepository orderRepository, CatalogClient catalogClient, CartClient cartClient) {
        this.orderRepository = orderRepository;
        this.catalogClient = catalogClient;
        this.cartClient = cartClient;
    }

    @PostMapping("/checkout")
    @Transactional
    public ResponseEntity<?> checkout(@RequestHeader(value = "X-User-Id", required = false) String userIdStr) {
        if (userIdStr == null || userIdStr.trim().isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized: Missing User ID header.");
        }

        Long userId;
        try {
            userId = Long.parseLong(userIdStr);
        } catch (NumberFormatException e) {
            return ResponseEntity.badRequest().body("Invalid User ID format.");
        }

        // 1. Fetch cart items
        List<CartItemDto> cartItems;
        try {
            cartItems = cartClient.getCartItems(userId);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Failed to contact Cart Service: " + e.getMessage());
        }

        if (cartItems == null || cartItems.isEmpty()) {
            return ResponseEntity.badRequest().body("Cart is empty. Cannot checkout.");
        }

        // 2. Perform checkout & stock decrement logic
        List<CartItemDto> successfulDecrements = new ArrayList<>();
        BigDecimal grandTotal = BigDecimal.ZERO;
        List<OrderItem> orderItems = new ArrayList<>();

        try {
            for (CartItemDto item : cartItems) {
                Long productId = item.getProductId();
                Integer quantity = item.getQuantity();

                if (quantity == null || quantity <= 0) {
                    continue;
                }

                // 2.1 Fetch product details
                ProductDto product;
                try {
                    product = catalogClient.getProductById(productId);
                } catch (FeignException.NotFound ex) {
                    throw new ProductNotFoundException("Product not found with ID: " + productId);
                }



                // 2.3 Atomically decrement stock in Catalog service
                try {
                    catalogClient.decrementStock(productId, quantity);
                    successfulDecrements.add(item);
                } catch (Exception ex) {
                    throw new InsufficientStockException("Failed to reserve stock for product: " + product.getName() + 
                                                       " due to parallel checkout. Please try again.");
                }

                // 2.4 Construct order item
                BigDecimal itemPrice = product.getPrice();
                OrderItem orderItem = new OrderItem(productId, quantity, itemPrice);
                orderItems.add(orderItem);

                grandTotal = grandTotal.add(orderItem.getTotalPrice());
            }

            if (orderItems.isEmpty()) {
                return ResponseEntity.badRequest().body("No valid items to checkout.");
            }

            // 3. Save Order and Items to database
            Order order = new Order();
            order.setUserId(userId);
            order.setGrandTotal(grandTotal);

            for (OrderItem oItem : orderItems) {
                order.addItem(oItem);
            }

            Order savedOrder = orderRepository.save(order);

            // 4. Clear the user's cart in the Cart service
            try {
                cartClient.clearCart(userId);
            } catch (Exception e) {
                System.err.println("Warning: Order created, but failed to clear cart for user " + userId + ": " + e.getMessage());
            }

            return ResponseEntity.status(HttpStatus.CREATED).body(savedOrder);

        } catch (Exception e) {
            // COMPENSATING TRANSACTION: Roll back all successful decrements
            System.err.println("Checkout failed! Triggering compensating rollback. Reason: " + e.getMessage());
            for (CartItemDto revertedItem : successfulDecrements) {
                try {
                    catalogClient.incrementStock(revertedItem.getProductId(), revertedItem.getQuantity());
                } catch (Exception ex) {
                    System.err.println("CRITICAL: Failed to revert stock decrement for product " + revertedItem.getProductId() + ": " + ex.getMessage());
                }
            }
            
            // Re-throw or handle error
            if (e instanceof InsufficientStockException || e instanceof ProductNotFoundException) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Checkout orchestration failed: " + e.getMessage());
        }
    }

    @GetMapping("/history")
    public ResponseEntity<?> getOrderHistory(@RequestHeader(value = "X-User-Id", required = false) String userIdStr) {
        if (userIdStr == null || userIdStr.trim().isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized: Missing User ID header.");
        }

        Long userId;
        try {
            userId = Long.parseLong(userIdStr);
        } catch (NumberFormatException e) {
            return ResponseEntity.badRequest().body("Invalid User ID format.");
        }

        List<Order> orders = orderRepository.findByUserIdOrderByCreatedAtDesc(userId);
        return ResponseEntity.ok(orders);
    }
}
