package com.flashsale.catalogservice.controller;

import com.flashsale.catalogservice.model.Product;
import com.flashsale.catalogservice.repository.ProductRepository;
import com.flashsale.catalogservice.exception.ProductNotFoundException;
import com.flashsale.catalogservice.exception.InsufficientStockException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.List;

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
            System.err.println("Error fetching reservations for product " + productId + ": " + e.getMessage());
            return 0;
        }
    }

    @GetMapping
    public List<Product> getAllProducts() {
        List<Product> products = productRepository.findAll();
        for (Product p : products) {
            int reservations = getReservations(p.getId());
            p.setStockQuantity(Math.max(0, p.getStockQuantity() - reservations));
        }
        return products;
    }

    @GetMapping("/{id}")
    public Product getProductById(@PathVariable Long id) {
        Product p = productRepository.findById(id)
                .orElseThrow(() -> new ProductNotFoundException("Product not found with ID: " + id));
        int reservations = getReservations(p.getId());
        p.setStockQuantity(Math.max(0, p.getStockQuantity() - reservations));
        return p;
    }

    @PutMapping("/{id}/decrement")
    public ResponseEntity<?> decrementStock(@PathVariable Long id, @RequestParam Integer quantity) {
        if (quantity == null || quantity <= 0) {
            return ResponseEntity.badRequest().body("Quantity must be greater than 0");
        }

        // Verify product existence (queries DB directly)
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ProductNotFoundException("Product not found with ID: " + id));

        // Execute the atomic database decrement
        int rowsUpdated = productRepository.decrementStock(id, quantity);
        if (rowsUpdated == 0) {
            throw new InsufficientStockException("Insufficient stock for product ID: " + id + 
                                               ". Available: " + product.getStockQuantity());
        }

        // Fetch and return the updated state of the product
        Product updatedProduct = productRepository.findById(id)
                .orElseThrow(() -> new ProductNotFoundException("Product not found after updating."));
        return ResponseEntity.ok(updatedProduct);
    }

    @PutMapping("/{id}/increment")
    public ResponseEntity<?> incrementStock(@PathVariable Long id, @RequestParam Integer quantity) {
        if (quantity == null || quantity <= 0) {
            return ResponseEntity.badRequest().body("Quantity must be greater than 0");
        }

        // Verify product existence
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ProductNotFoundException("Product not found with ID: " + id));

        // Execute the database increment
        int rowsUpdated = productRepository.incrementStock(id, quantity);
        if (rowsUpdated == 0) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Failed to update stock");
        }

        Product updatedProduct = productRepository.findById(id)
                .orElseThrow(() -> new ProductNotFoundException("Product not found after updating."));
        return ResponseEntity.ok(updatedProduct);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Product createProduct(@RequestBody Product product) {
        return productRepository.save(product);
    }

    @PutMapping("/{id}")
    public Product updateProduct(@PathVariable Long id, @RequestBody Product productDetails) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ProductNotFoundException("Product not found with ID: " + id));

        product.setName(productDetails.getName());
        product.setDescription(productDetails.getDescription());
        product.setPrice(productDetails.getPrice());
        product.setStockQuantity(productDetails.getStockQuantity());

        return productRepository.save(product);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteProduct(@PathVariable Long id) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ProductNotFoundException("Product not found with ID: " + id));

        productRepository.delete(product);
        return ResponseEntity.ok().body("Product deleted successfully");
    }
}
