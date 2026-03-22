package com.dms.backend.repositories;

import com.dms.backend.models.PriceRule;
import com.dms.backend.models.Product;
import com.dms.backend.models.Tenant;
import com.dms.backend.models.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PriceRuleRepository extends JpaRepository<PriceRule, UUID> {

    /** Find all price rules for a given distributor (tenant). */
    List<PriceRule> findAllByTenant(Tenant tenant);

    /** Find a specific-buyer price rule for a product. */
    Optional<PriceRule> findByTenantAndProductAndBuyer(Tenant tenant, Product product, User buyer);

    /** Find a buyer-type default price rule for a product. */
    Optional<PriceRule> findByTenantAndProductAndBuyerType(Tenant tenant, Product product, String buyerType);

    /** Find all rules for a specific product. */
    List<PriceRule> findAllByTenantAndProduct(Tenant tenant, Product product);
}
