package com.flashsale.orderservice.client;

import com.flashsale.orderservice.dto.CartItemDto;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import java.util.List;

@FeignClient(name = "cart-service", url = "${cart.service.url}")
public interface CartClient {

    @GetMapping("/api/cart/internal/{userId}")
    List<CartItemDto> getCartItems(@PathVariable("userId") Long userId);

    @PostMapping("/api/cart/internal/{userId}/clear")
    void clearCart(@PathVariable("userId") Long userId);
}
