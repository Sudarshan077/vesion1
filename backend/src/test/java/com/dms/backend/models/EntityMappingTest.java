package com.dms.backend.models;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import java.math.BigDecimal;
import java.util.Set;
import com.dms.backend.models.Retailer;

import static org.assertj.core.api.Assertions.assertThat;

import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.ANY)
public class EntityMappingTest {

    @Autowired
    private TestEntityManager entityManager;

    @Test
    public void testTenantAndUserMapping() {
        // Arrange
        Tenant tenant = Tenant.builder().name("Test Distributor").build();
        tenant = entityManager.persistAndFlush(tenant);

        Role adminRole = Role.builder().name("ROLE_ADMIN").build();
        adminRole = entityManager.persistAndFlush(adminRole);

        User user = User.builder()
                .tenant(tenant)
                .email("admin@test.com")
                .password("hashed_password")
                .fullName("Admin User")
                .roles(Set.of(adminRole))
                .build();
        
        // Act
        user = entityManager.persistAndFlush(user);

        // Assert
        User foundUser = entityManager.find(User.class, user.getId());
        assertThat(foundUser).isNotNull();
        assertThat(foundUser.getTenant().getName()).isEqualTo("Test Distributor");
        assertThat(foundUser.getRoles()).hasSize(1);
        assertThat(foundUser.getRoles().iterator().next().getName()).isEqualTo("ROLE_ADMIN");
        assertThat(foundUser.getCreatedAt()).isNotNull();
    }

    @Test
    public void testOrderAndProductMapping() {
        // Arrange
        Tenant tenant = Tenant.builder().name("Distributor 2").build();
        tenant = entityManager.persistAndFlush(tenant);

        Product product = Product.builder()
                .tenant(tenant)
                .name("Soap")
                .sku("SKU-101")
                .price(new BigDecimal("50.00"))
                .currentStock(100)
                .build();
        product = entityManager.persistAndFlush(product);

        Retailer retailer = Retailer.builder()
                .tenant(tenant)
                .shopName("Kiran Shop")
                .ownerName("Kiran")
                .phone("9999999999")
                .build();
        retailer = entityManager.persistAndFlush(retailer);

        Order order = Order.builder()
                .tenant(tenant)
                .retailer(retailer)
                .orderStatus("PENDING")
                .totalAmount(new BigDecimal("500.00"))
                .build();

        OrderItem item = OrderItem.builder()
                .order(order)
                .product(product)
                .quantity(10)
                .unitPrice(new BigDecimal("50.00"))
                .subTotal(new BigDecimal("500.00"))
                .build();
        
        order.getItems().add(item);

        // Act
        order = entityManager.persistAndFlush(order);

        // Assert
        Order foundOrder = entityManager.find(Order.class, order.getId());
        assertThat(foundOrder).isNotNull();
        assertThat(foundOrder.getItems()).hasSize(1);
        assertThat(foundOrder.getItems().get(0).getProduct().getName()).isEqualTo("Soap");
        assertThat(foundOrder.getRetailer().getShopName()).isEqualTo("Kiran Shop");
    }
}
