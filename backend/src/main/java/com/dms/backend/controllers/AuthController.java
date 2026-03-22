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
import java.util.*;
import java.util.stream.Collectors;

/**
 * AuthController — Handles user registration, login, and profile retrieval.
 *
 * <h2>API Endpoint Reference</h2>
 * <pre>
 *   Base path: /api/v1/auth
 *   Security : All endpoints are permitAll() (configured in WebSecurityConfig)
 *
 *   ┌────────┬──────────┬──────────────────────────────────────────────────────────┐
 *   │ Method │ Path     │ Description                                              │
 *   ├────────┼──────────┼──────────────────────────────────────────────────────────┤
 *   │ POST   │ /signin  │ Login with email+password → returns JWT + user details   │
 *   │ POST   │ /signup  │ Register new user with role + tenant                     │
 *   │ GET    │ /me      │ Get current user's profile (requires valid JWT)          │
 *   └────────┴──────────┴──────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h2>Role Mapping (Frontend → Backend)</h2>
 * <pre>
 *   ┌─────────────────┬──────────────────┐
 *   │ Frontend Value   │ Internal Role    │
 *   ├─────────────────┼──────────────────┤
 *   │ "DISTRIBUTOR"    │ ROLE_ADMIN       │
 *   │ "RETAILER"       │ ROLE_RETAILER    │
 *   │ "CONSUMER"       │ ROLE_CUSTOMER    │
 *   │ null / unknown  │ ROLE_USER        │
 *   └─────────────────┴──────────────────┘
 * </pre>
 *
 * <h2>Signup Flow</h2>
 * <pre>
 *   Flutter LoginScreen (Sign Up mode)
 *       │
 *       ├─ User selects role (Distributor / Retailer / Consumer)
 *       ├─ Fills email, password, fullName, tenantName
 *       └─ POST /api/v1/auth/signup
 *           │
 *           ├─ Find-or-create Tenant by name
 *           ├─ Create User with mapped role
 *           └─ Return {"message": "User registered successfully!"}
 * </pre>
 *
 * <h2>Signin Response</h2>
 * <pre>
 *   {
 *     "token": "jwt-string",
 *     "email": "user@example.com",
 *     "roles": ["ROLE_ADMIN"],
 *     "fullName": "John Doe",
 *     "tenantName": "Acme Corp"
 *   }
 * </pre>
 *
 * @author DMS Team
 * @since Phase 1 (enhanced in Phase 2 with role mapping, B2C consumer support)
 * @see WebSecurityConfig — auth endpoint security rules
 */
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

    /**
     * Maps human-friendly frontend role selector values to internal ROLE_* names.
     *
     * @param role Frontend role string (e.g., "DISTRIBUTOR", "RETAILER", "CONSUMER")
     * @return Internal role name (e.g., "ROLE_ADMIN", "ROLE_RETAILER", "ROLE_CUSTOMER")
     */
    private String mapRoleName(String role) {
        if (role == null) return "ROLE_USER";
        switch (role.toUpperCase()) {
            case "DISTRIBUTOR": return "ROLE_ADMIN";
            case "RETAILER": return "ROLE_RETAILER";
            case "CONSUMER": return "ROLE_CUSTOMER";
            default:
                // Allow direct ROLE_* names for backward compatibility
                if (role.startsWith("ROLE_")) return role;
                return "ROLE_USER";
        }
    }

    /**
     * Authenticates a user and returns a JWT token along with user details.
     *
     * @param loginRequest Map containing "email" and "password"
     * @return JWT token, email, roles, fullName, tenantName
     */
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

            // Fetch full user details for the response
            User dbUser = userRepository.findByEmail(userDetails.getUsername()).orElse(null);

            Map<String, Object> response = new HashMap<>();
            response.put("token", jwt);
            response.put("email", userDetails.getUsername());
            response.put("roles", roles);
            if (dbUser != null) {
                response.put("fullName", dbUser.getFullName());
                response.put("tenantName", dbUser.getTenant().getName());
            }

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(401).body(Map.of("message", "Invalid email or password"));
        }
    }

    /**
     * Registers a new user with the specified role and tenant.
     *
     * @param signUpRequest Map containing email, password, fullName, tenantName, role
     * @return Success message or error
     */
    @PostMapping("/signup")
    public ResponseEntity<?> registerUser(@RequestBody Map<String, Object> signUpRequest) {
        if (userRepository.findByEmail((String) signUpRequest.get("email")).isPresent()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Error: Email is already in use!"));
        }

        // Create a tenant if it doesn't exist
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

        // Handle role from frontend — accepts "DISTRIBUTOR", "RETAILER", "CONSUMER" or legacy ROLE_* format
        Set<Role> roles = new HashSet<>();
        Object rolesObj = signUpRequest.get("roles");
        String singleRole = (String) signUpRequest.get("role"); // Single role selector

        if (singleRole != null) {
            String roleName = mapRoleName(singleRole);
            Role r = roleRepository.findByName(roleName)
                    .orElseGet(() -> roleRepository.save(new Role(roleName)));
            roles.add(r);
        } else if (rolesObj instanceof List) {
            // Legacy format: list of roles
            List<String> strRoles = (List<String>) rolesObj;
            strRoles.forEach(role -> {
                String roleName = mapRoleName(role);
                Role r = roleRepository.findByName(roleName)
                        .orElseGet(() -> roleRepository.save(new Role(roleName)));
                roles.add(r);
            });
        } else {
            Role userRole = roleRepository.findByName("ROLE_USER")
                    .orElseGet(() -> roleRepository.save(new Role("ROLE_USER")));
            roles.add(userRole);
        }

        user.setRoles(roles);
        userRepository.save(user);

        return ResponseEntity.ok(Map.of("message", "User registered successfully!"));
    }

    /**
     * Returns the current authenticated user's profile.
     *
     * @return User profile with email, fullName, tenantName, and roles
     */
    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        User user = userRepository.findByEmail(auth.getName()).orElse(null);
        if (user == null) {
            return ResponseEntity.status(401).body(Map.of("message", "User not found"));
        }

        List<String> roles = user.getRoles().stream()
                .map(Role::getName)
                .collect(Collectors.toList());

        Map<String, Object> response = new HashMap<>();
        response.put("email", user.getEmail());
        response.put("fullName", user.getFullName());
        response.put("tenantName", user.getTenant().getName());
        response.put("roles", roles);

        return ResponseEntity.ok(response);
    }
}
