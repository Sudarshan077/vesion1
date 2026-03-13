package com.dms.backend.services;

import com.dms.backend.models.*;
import com.dms.backend.repositories.OrderRepository;
import com.dms.backend.repositories.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.UUID;

@Service
public class OrderService {
    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private ProductRepository productRepository;

    @Transactional
    public Order placeOrder(Order order, Tenant tenant) {
        order.setTenant(tenant);
        BigDecimal total = BigDecimal.ZERO;

        for (OrderItem item : order.getItems()) {
            Product product = productRepository.findById(item.getProduct().getId())
                    .orElseThrow(() -> new RuntimeException("Product not found: " + item.getProduct().getId()));

            if (product.getCurrentStock() < item.getQuantity()) {
                throw new RuntimeException("Insufficient stock for product: " + product.getName());
            }

            // Update stock
            product.setCurrentStock(product.getCurrentStock() - item.getQuantity());
            productRepository.save(product);

            // Set prices and totals
            item.setOrder(order);
            item.setUnitPrice(product.getPrice());
            item.setSubTotal(product.getPrice().multiply(new BigDecimal(item.getQuantity())));
            total = total.add(item.getSubTotal());
        }

        order.setTotalAmount(total);
        order.setOrderStatus("PENDING");
        return orderRepository.save(order);
    }
}
