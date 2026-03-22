package com.dms.backend.controllers;

import com.dms.backend.models.*;
import com.dms.backend.repositories.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

/**
 * PriceRuleController — Allows distributors to manage custom pricing per buyer.
 *
 * <h2>API Endpoint Reference</h2>
 * <pre>
 *   Base path: /api/v1/price-rules
 *   Security : ROLE_ADMIN (Distributor) only
 *
 *   ┌────────┬──────────────┬────────────────────────────────────────────────────┐
 *   │ Method │ Path         │ Description                                        │
 *   ├────────┼──────────────┼────────────────────────────────────────────────────┤
 *   │ GET    │ /            │ List all price rules for the distributor            │
 *   │ POST   │ /            │ Create a new price rule                             │
 *   │ PUT    │ /{id}        │ Update a price rule                                 │
 *   │ DELETE │ /{id}        │ Delete a price rule                                 │
 *   └────────┴──────────────┴────────────────────────────────────────────────────┘
 *
 *   Additional (any authenticated user):
 *   ┌────────┬───────────────────────────────┬──────────────────────────────────┐
 *   │ Method │ Path                          │ Description                      │
 *   ├────────┼───────────────────────────────┼──────────────────────────────────┤
 *   │ GET    │ /resolved/{productId}         │ Get resolved price for caller    │
 *   └────────┴───────────────────────────────┴──────────────────────────────────┘
 * </pre>
 */
@RestController
@RequestMapping("/api/v1/price-rules")
public class PriceRuleController {

    @Autowired
    private PriceRuleRepository priceRuleRepository;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private UserRepository userRepository;

    /**
     * List all price rules for the distributor's tenant.
     */
    @GetMapping
    public ResponseEntity<?> getAllPriceRules() {
        User admin = getCurrentUser();
        if (admin == null) return ResponseEntity.status(401).body(Map.of("message", "Unauthorized"));

        List<PriceRule> rules = priceRuleRepository.findAllByTenant(admin.getTenant());

        List<Map<String, Object>> response = rules.stream().map(this::buildRuleResponse).collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }

    /**
     * Create a new price rule.
     * Body: { productId, buyerId (optional), buyerType (optional), customPrice }
     */
    @PostMapping
    public ResponseEntity<?> createPriceRule(@RequestBody Map<String, Object> request) {
        User admin = getCurrentUser();
        if (admin == null) return ResponseEntity.status(401).body(Map.of("message", "Unauthorized"));

        String productId = (String) request.get("productId");
        String buyerId = (String) request.get("buyerId");
        String buyerType = (String) request.get("buyerType");
        Object priceObj = request.get("customPrice");

        if (productId == null || priceObj == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "productId and customPrice are required"));
        }

        BigDecimal customPrice;
        try {
            customPrice = new BigDecimal(priceObj.toString());
        } catch (NumberFormatException e) {
            return ResponseEntity.badRequest().body(Map.of("message", "Invalid price format"));
        }

        Optional<Product> productOpt = productRepository.findById(UUID.fromString(productId));
        if (productOpt.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Product not found"));
        }

        User buyer = null;
        if (buyerId != null && !buyerId.isEmpty()) {
            buyer = userRepository.findById(UUID.fromString(buyerId)).orElse(null);
            if (buyer == null) {
                return ResponseEntity.badRequest().body(Map.of("message", "Buyer not found"));
            }
            // Check for duplicate specific-buyer rule
            Optional<PriceRule> existing = priceRuleRepository.findByTenantAndProductAndBuyer(
                    admin.getTenant(), productOpt.get(), buyer);
            if (existing.isPresent()) {
                return ResponseEntity.badRequest().body(Map.of("message", "Price rule already exists for this buyer and product. Use PUT to update."));
            }
            buyerType = null; // specific buyer overrides type
        } else if (buyerType != null && !buyerType.isEmpty()) {
            // Check for duplicate type-level rule
            Optional<PriceRule> existing = priceRuleRepository.findByTenantAndProductAndBuyerType(
                    admin.getTenant(), productOpt.get(), buyerType.toUpperCase());
            if (existing.isPresent()) {
                return ResponseEntity.badRequest().body(Map.of("message", "Price rule already exists for this buyer type and product. Use PUT to update."));
            }
            buyerType = buyerType.toUpperCase();
        } else {
            return ResponseEntity.badRequest().body(Map.of("message", "Either buyerId or buyerType is required"));
        }

        PriceRule rule = PriceRule.builder()
                .tenant(admin.getTenant())
                .product(productOpt.get())
                .buyer(buyer)
                .buyerType(buyerType)
                .customPrice(customPrice)
                .build();

        priceRuleRepository.save(rule);
        return ResponseEntity.ok(buildRuleResponse(rule));
    }

    /**
     * Update an existing price rule.
     */
    @PutMapping("/{id}")
    public ResponseEntity<?> updatePriceRule(@PathVariable UUID id, @RequestBody Map<String, Object> request) {
        User admin = getCurrentUser();
        if (admin == null) return ResponseEntity.status(401).body(Map.of("message", "Unauthorized"));

        Optional<PriceRule> ruleOpt = priceRuleRepository.findById(id);
        if (ruleOpt.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Price rule not found"));
        }

        PriceRule rule = ruleOpt.get();
        if (!rule.getTenant().getId().equals(admin.getTenant().getId())) {
            return ResponseEntity.status(403).body(Map.of("message", "Not authorized to modify this rule"));
        }

        Object priceObj = request.get("customPrice");
        if (priceObj != null) {
            try {
                rule.setCustomPrice(new BigDecimal(priceObj.toString()));
            } catch (NumberFormatException e) {
                return ResponseEntity.badRequest().body(Map.of("message", "Invalid price format"));
            }
        }

        priceRuleRepository.save(rule);
        return ResponseEntity.ok(buildRuleResponse(rule));
    }

    /**
     * Delete a price rule.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deletePriceRule(@PathVariable UUID id) {
        User admin = getCurrentUser();
        if (admin == null) return ResponseEntity.status(401).body(Map.of("message", "Unauthorized"));

        Optional<PriceRule> ruleOpt = priceRuleRepository.findById(id);
        if (ruleOpt.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Price rule not found"));
        }

        PriceRule rule = ruleOpt.get();
        if (!rule.getTenant().getId().equals(admin.getTenant().getId())) {
            return ResponseEntity.status(403).body(Map.of("message", "Not authorized to delete this rule"));
        }

        priceRuleRepository.delete(rule);
        return ResponseEntity.ok(Map.of("message", "Price rule deleted successfully"));
    }

    /**
     * Get the resolved price for a product for the current user.
     * Resolution: specific buyer > buyer type > product base price.
     */
    @GetMapping("/resolved/{productId}")
    public ResponseEntity<?> getResolvedPrice(@PathVariable UUID productId) {
        User user = getCurrentUser();
        if (user == null) return ResponseEntity.status(401).body(Map.of("message", "Unauthorized"));

        Optional<Product> productOpt = productRepository.findById(productId);
        if (productOpt.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Product not found"));
        }

        Product product = productOpt.get();
        BigDecimal resolvedPrice = resolvePrice(product, user);

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("productId", product.getId());
        response.put("productName", product.getName());
        response.put("basePrice", product.getPrice());
        response.put("resolvedPrice", resolvedPrice);
        response.put("hasCustomPrice", resolvedPrice.compareTo(product.getPrice()) != 0);

        return ResponseEntity.ok(response);
    }

    // ─── Helpers ─────────────────────────────────────────────

    private BigDecimal resolvePrice(Product product, User buyer) {
        Tenant tenant = product.getTenant();

        // 1. Check specific-buyer price
        Optional<PriceRule> specificRule = priceRuleRepository.findByTenantAndProductAndBuyer(tenant, product, buyer);
        if (specificRule.isPresent()) {
            return specificRule.get().getCustomPrice();
        }

        // 2. Check buyer-type default
        String buyerType = getBuyerType(buyer);
        if (buyerType != null) {
            Optional<PriceRule> typeRule = priceRuleRepository.findByTenantAndProductAndBuyerType(tenant, product, buyerType);
            if (typeRule.isPresent()) {
                return typeRule.get().getCustomPrice();
            }
        }

        // 3. Fall back to product base price
        return product.getPrice();
    }

    private String getBuyerType(User user) {
        if (user.getRoles() == null) return null;
        for (Role role : user.getRoles()) {
            if ("ROLE_RETAILER".equals(role.getName())) return "RETAILER";
            if ("ROLE_CUSTOMER".equals(role.getName())) return "CONSUMER";
        }
        return null;
    }

    private User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return userRepository.findByEmail(auth.getName()).orElse(null);
    }

    private Map<String, Object> buildRuleResponse(PriceRule rule) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", rule.getId());
        map.put("productId", rule.getProduct().getId());
        map.put("productName", rule.getProduct().getName());
        map.put("productSku", rule.getProduct().getSku());
        if (rule.getBuyer() != null) {
            map.put("buyerId", rule.getBuyer().getId());
            map.put("buyerName", rule.getBuyer().getFullName());
            map.put("buyerEmail", rule.getBuyer().getEmail());
        }
        map.put("buyerType", rule.getBuyerType());
        map.put("customPrice", rule.getCustomPrice());
        map.put("basePrice", rule.getProduct().getPrice());
        map.put("createdAt", rule.getCreatedAt());
        map.put("updatedAt", rule.getUpdatedAt());
        return map;
    }
}
