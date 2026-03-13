package com.dms.backend.models;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "retailers")
public class Retailer {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tenant_id", nullable = false)
    private Tenant tenant;

    @Column(nullable = false)
    private String shopName;

    @Column(nullable = false)
    private String ownerName;

    @Column(nullable = false, unique = true)
    private String phone;

    private String address;
    private String gstNumber; // Important for India

    @CreationTimestamp
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;

    public Retailer() {}

    public Retailer(Tenant tenant, String shopName, String ownerName, String phone, String address, String gstNumber) {
        this.tenant = tenant;
        this.shopName = shopName;
        this.ownerName = ownerName;
        this.phone = phone;
        this.address = address;
        this.gstNumber = gstNumber;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Tenant getTenant() { return tenant; }
    public void setTenant(Tenant tenant) { this.tenant = tenant; }

    public String getShopName() { return shopName; }
    public void setShopName(String shopName) { this.shopName = shopName; }

    public String getOwnerName() { return ownerName; }
    public void setOwnerName(String ownerName) { this.ownerName = ownerName; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public String getGstNumber() { return gstNumber; }
    public void setGstNumber(String gstNumber) { this.gstNumber = gstNumber; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    public static RetailerBuilder builder() {
        return new RetailerBuilder();
    }

    public static class RetailerBuilder {
        private Tenant tenant;
        private String shopName;
        private String ownerName;
        private String phone;
        private String address;
        private String gstNumber;

        public RetailerBuilder tenant(Tenant tenant) { this.tenant = tenant; return this; }
        public RetailerBuilder shopName(String shopName) { this.shopName = shopName; return this; }
        public RetailerBuilder ownerName(String ownerName) { this.ownerName = ownerName; return this; }
        public RetailerBuilder phone(String phone) { this.phone = phone; return this; }
        public RetailerBuilder address(String address) { this.address = address; return this; }
        public RetailerBuilder gstNumber(String gstNumber) { this.gstNumber = gstNumber; return this; }

        public Retailer build() {
            return new Retailer(tenant, shopName, ownerName, phone, address, gstNumber);
        }
    }
}
