package com.dms.backend.controllers;

import com.dms.backend.models.Product;
import com.dms.backend.models.Tenant;
import com.dms.backend.repositories.ProductRepository;
import com.dms.backend.repositories.TenantRepository;
import com.dms.backend.repositories.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/products")
public class ProductController {
    @Autowired
    ProductRepository productRepository;

    @Autowired
    UserRepository userRepository;

    @Autowired
    TenantRepository tenantRepository;

    private Tenant getCurrentTenant() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();
        return userRepository.findByEmail(email).get().getTenant();
    }

    @GetMapping
    public List<Product> getAllProducts() {
        return productRepository.findByTenant(getCurrentTenant());
    }

    @PostMapping
    public Product createProduct(@RequestBody Product product) {
        product.setTenant(getCurrentTenant());
        return productRepository.save(product);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Product> getProductById(@PathVariable UUID id) {
        return productRepository.findById(id)
                .filter(p -> p.getTenant().getId().equals(getCurrentTenant().getId()))
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
