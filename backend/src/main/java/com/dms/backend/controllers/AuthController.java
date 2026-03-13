package com.dms.backend.controllers;

import com.dms.backend.models.Role;
import com.dms.backend.models.Tenant;
import com.dms.backend.models.User;
import com.dms.backend.repositories.RoleRepository;
import com.dms.backend.repositories.TenantRepository;
import com.dms.backend.repositories.UserRepository;
import com.dms.backend.security.JwtUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
    @Autowired
    AuthenticationManager authenticationManager;

    @Autowired
    UserRepository userRepository;

    @Autowired
    RoleRepository roleRepository;

    @Autowired
    TenantRepository tenantRepository;

    @Autowired
    PasswordEncoder encoder;

    @Autowired
    JwtUtils jwtUtils;

    @PostMapping("/signin")
    public ResponseEntity<?> authenticateUser(@RequestBody Map<String, String> loginRequest) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(loginRequest.get("email"), loginRequest.get("password")));

            SecurityContextHolder.getContext().setAuthentication(authentication);
            String jwt = jwtUtils.generateJwtToken(authentication);

            org.springframework.security.core.userdetails.User userDetails = (org.springframework.security.core.userdetails.User) authentication.getPrincipal();
            List<String> roles = userDetails.getAuthorities().stream()
                    .map(item -> item.getAuthority())
                    .collect(Collectors.toList());

            return ResponseEntity.ok(Map.of(
                    "token", jwt,
                    "email", userDetails.getUsername(),
                    "roles", roles));
        } catch (Exception e) {
            return ResponseEntity.status(401).body(Map.of("message", "Invalid email or password"));
        }
    }

    @PostMapping("/signup")
    public ResponseEntity<?> registerUser(@RequestBody Map<String, Object> signUpRequest) {
        if (userRepository.findByEmail((String) signUpRequest.get("email")).isPresent()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Error: Email is already in use!"));
        }

        // Simplification for Phase 1: Create a tenant if it doesn't exist
        String tenantName = (String) signUpRequest.get("tenantName");
        Tenant tenant = tenantRepository.findByName(tenantName)
                .orElseGet(() -> tenantRepository.save(new Tenant(tenantName)));

        // Create new user's account
        User user = User.builder()
                .email((String) signUpRequest.get("email"))
                .password(encoder.encode((String) signUpRequest.get("password")))
                .fullName((String) signUpRequest.get("fullName"))
                .tenant(tenant)
                .build();

        List<String> strRoles = (List<String>) signUpRequest.get("roles");
        Set<Role> roles = new HashSet<>();

        if (strRoles == null) {
            Role userRole = roleRepository.findByName("ROLE_USER")
                    .orElseGet(() -> roleRepository.save(new Role("ROLE_USER")));
            roles.add(userRole);
        } else {
            strRoles.forEach(role -> {
                Role r = roleRepository.findByName(role)
                        .orElseGet(() -> roleRepository.save(new Role(role)));
                roles.add(r);
            });
        }

        user.setRoles(roles);
        userRepository.save(user);

        return ResponseEntity.ok(Map.of("message", "User registered successfully!"));
    }
}
