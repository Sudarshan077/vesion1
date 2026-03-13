package com.dms.backend.controllers;

import com.dms.backend.models.Order;
import com.dms.backend.models.Tenant;
import com.dms.backend.repositories.OrderRepository;
import com.dms.backend.repositories.UserRepository;
import com.dms.backend.services.OrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/v1/orders")
public class OrderController {
    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderService orderService;

    @Autowired
    private UserRepository userRepository;

    private Tenant getCurrentTenant() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();
        return userRepository.findByEmail(email).get().getTenant();
    }

    @GetMapping
    public List<Order> getAllOrders() {
        return orderRepository.findByTenant(getCurrentTenant());
    }

    @PostMapping
    public Order createOrder(@RequestBody Order order) {
        return orderService.placeOrder(order, getCurrentTenant());
    }
}
