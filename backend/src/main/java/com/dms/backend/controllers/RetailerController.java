package com.dms.backend.controllers;

import com.dms.backend.models.Retailer;
import com.dms.backend.models.Tenant;
import com.dms.backend.repositories.RetailerRepository;
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
@RequestMapping("/api/v1/retailers")
public class RetailerController {
    @Autowired
    RetailerRepository retailerRepository;

    @Autowired
    UserRepository userRepository;

    private Tenant getCurrentTenant() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();
        return userRepository.findByEmail(email).get().getTenant();
    }

    @GetMapping
    public List<Retailer> getAllRetailers() {
        return retailerRepository.findByTenant(getCurrentTenant());
    }

    @PostMapping
    public Retailer createRetailer(@RequestBody Retailer retailer) {
        retailer.setTenant(getCurrentTenant());
        return retailerRepository.save(retailer);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Retailer> getRetailerById(@PathVariable UUID id) {
        return retailerRepository.findById(id)
                .filter(r -> r.getTenant().getId().equals(getCurrentTenant().getId()))
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
