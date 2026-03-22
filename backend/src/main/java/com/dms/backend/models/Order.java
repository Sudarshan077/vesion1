package com.dms.backend.models;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "orders")
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tenant_id", nullable = false)
    private Tenant tenant;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "retailer_id")
    private Retailer retailer; // Null for B2C Consumer orders

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by_id", nullable = false)
    private User createdBy; // The user (Retailer or Consumer) who placed the order

    @Column(nullable = false)
    private String orderStatus; // PENDING, CONFIRMED, DELIVERED, CANCELLED

    @Column(nullable = false)
    private BigDecimal totalAmount;

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<OrderItem> items = new ArrayList<>();

    @CreationTimestamp
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;

    public Order() {}

    public Order(Tenant tenant, Retailer retailer, User createdBy, String orderStatus, BigDecimal totalAmount) {
        this.tenant = tenant;
        this.retailer = retailer;
        this.createdBy = createdBy;
        this.orderStatus = orderStatus;
        this.totalAmount = totalAmount;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Tenant getTenant() { return tenant; }
    public void setTenant(Tenant tenant) { this.tenant = tenant; }

    public Retailer getRetailer() { return retailer; }
    public void setRetailer(Retailer retailer) { this.retailer = retailer; }

    public User getCreatedBy() { return createdBy; }
    public void setCreatedBy(User createdBy) { this.createdBy = createdBy; }

    public String getOrderStatus() { return orderStatus; }
    public void setOrderStatus(String orderStatus) { this.orderStatus = orderStatus; }

    public BigDecimal getTotalAmount() { return totalAmount; }
    public void setTotalAmount(BigDecimal totalAmount) { this.totalAmount = totalAmount; }

    public List<OrderItem> getItems() { return items; }
    public void setItems(List<OrderItem> items) { this.items = items; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    public static OrderBuilder builder() {
        return new OrderBuilder();
    }

    public static class OrderBuilder {
        private Tenant tenant;
        private Retailer retailer;
        private User createdBy;
        private String orderStatus;
        private BigDecimal totalAmount;

        public OrderBuilder tenant(Tenant tenant) { this.tenant = tenant; return this; }
        public OrderBuilder retailer(Retailer retailer) { this.retailer = retailer; return this; }
        public OrderBuilder createdBy(User createdBy) { this.createdBy = createdBy; return this; }
        public OrderBuilder orderStatus(String orderStatus) { this.orderStatus = orderStatus; return this; }
        public OrderBuilder totalAmount(BigDecimal totalAmount) { this.totalAmount = totalAmount; return this; }

        public Order build() {
            return new Order(tenant, retailer, createdBy, orderStatus, totalAmount);
        }
    }
}
