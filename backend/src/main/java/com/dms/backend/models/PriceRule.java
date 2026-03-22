package com.dms.backend.models;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * PriceRule — Allows distributors to set custom prices per product per buyer (or buyer type).
 *
 * <h2>Price Resolution Order</h2>
 * <pre>
 *   1. Specific buyer price  (product + buyer user)
 *   2. Buyer-type default    (product + buyerType "RETAILER" or "CONSUMER")
 *   3. Product base price    (product.price)
 * </pre>
 *
 * <h2>Usage</h2>
 * <pre>
 *   - Distributor sets a custom price of ₹45 for Product "Soap" for Retailer "Kiran Shop"
 *   - Distributor sets a default price of ₹48 for all Retailers on "Soap"
 *   - Consumer sees ₹50 (product base price) unless a rule exists for them
 * </pre>
 */
@Entity
@Table(name = "price_rules", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"tenant_id", "product_id", "buyer_id"}),
    @UniqueConstraint(columnNames = {"tenant_id", "product_id", "buyer_type"})
})
public class PriceRule {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tenant_id", nullable = false)
    private Tenant tenant;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;

    /**
     * Specific buyer (retailer or consumer user). Null when this is a type-level default.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "buyer_id")
    private User buyer;

    /**
     * Buyer type: "RETAILER" or "CONSUMER". Used for type-level defaults.
     * Null when this is a specific-buyer rule.
     */
    private String buyerType;

    @Column(nullable = false)
    private BigDecimal customPrice;

    @CreationTimestamp
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;

    public PriceRule() {}

    public PriceRule(Tenant tenant, Product product, User buyer, String buyerType, BigDecimal customPrice) {
        this.tenant = tenant;
        this.product = product;
        this.buyer = buyer;
        this.buyerType = buyerType;
        this.customPrice = customPrice;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Tenant getTenant() { return tenant; }
    public void setTenant(Tenant tenant) { this.tenant = tenant; }

    public Product getProduct() { return product; }
    public void setProduct(Product product) { this.product = product; }

    public User getBuyer() { return buyer; }
    public void setBuyer(User buyer) { this.buyer = buyer; }

    public String getBuyerType() { return buyerType; }
    public void setBuyerType(String buyerType) { this.buyerType = buyerType; }

    public BigDecimal getCustomPrice() { return customPrice; }
    public void setCustomPrice(BigDecimal customPrice) { this.customPrice = customPrice; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    public static PriceRuleBuilder builder() {
        return new PriceRuleBuilder();
    }

    public static class PriceRuleBuilder {
        private Tenant tenant;
        private Product product;
        private User buyer;
        private String buyerType;
        private BigDecimal customPrice;

        public PriceRuleBuilder tenant(Tenant tenant) { this.tenant = tenant; return this; }
        public PriceRuleBuilder product(Product product) { this.product = product; return this; }
        public PriceRuleBuilder buyer(User buyer) { this.buyer = buyer; return this; }
        public PriceRuleBuilder buyerType(String buyerType) { this.buyerType = buyerType; return this; }
        public PriceRuleBuilder customPrice(BigDecimal customPrice) { this.customPrice = customPrice; return this; }

        public PriceRule build() {
            return new PriceRule(tenant, product, buyer, buyerType, customPrice);
        }
    }
}
