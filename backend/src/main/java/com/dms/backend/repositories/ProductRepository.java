package com.dms.backend.repositories;

import com.dms.backend.models.Product;
import com.dms.backend.models.Tenant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ProductRepository extends JpaRepository<Product, UUID> {
    List<Product> findByTenant(Tenant tenant);
    Optional<Product> findBySkuAndTenant(String sku, Tenant tenant);
}
