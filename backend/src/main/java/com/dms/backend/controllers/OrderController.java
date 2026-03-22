package com.dms.backend.controllers;

import com.dms.backend.models.Order;
import com.dms.backend.models.Tenant;
import com.dms.backend.models.User;
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

    @GetMapping
    public List<Order> getAllOrders() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        User currentUser = userRepository.findByEmail(auth.getName()).get();
        Tenant currentTenant = currentUser.getTenant();

        // If the user is a Consumer, they only see their own orders
        boolean isConsumer = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_CUSTOMER"));
        if (isConsumer) {
            return orderRepository.findByTenant(currentTenant).stream()
                    .filter(o -> o.getCreatedBy() != null && o.getCreatedBy().getId().equals(currentUser.getId()))
                    .toList();
        }

        // Distributor/Retailer logic (could be further refined if retailers should only see theirs)
        boolean isRetailer = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_RETAILER"));
        if (isRetailer) {
            // Assume Retailer has a retailer profile associated via some logic, but for now fallback to createdBy or tenant logic
            return orderRepository.findByTenant(currentTenant).stream()
                    .filter(o -> o.getCreatedBy() != null && o.getCreatedBy().getId().equals(currentUser.getId()))
                    .toList();
        }

        // Admin sees all
        return orderRepository.findByTenant(currentTenant);
    }

    @PostMapping
    public Order createOrder(@RequestBody Order order) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        User currentUser = userRepository.findByEmail(auth.getName()).get();
        order.setCreatedBy(currentUser);
        return orderService.placeOrder(order, currentUser.getTenant());
    }
}
