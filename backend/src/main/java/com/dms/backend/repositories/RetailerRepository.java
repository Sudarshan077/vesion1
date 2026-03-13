package com.dms.backend.repositories;

import com.dms.backend.models.Retailer;
import com.dms.backend.models.Tenant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface RetailerRepository extends JpaRepository<Retailer, UUID> {
    List<Retailer> findByTenant(Tenant tenant);
}
