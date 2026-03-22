package com.dms.backend.controllers;

import com.dms.backend.models.Role;
import com.dms.backend.models.User;
import com.dms.backend.repositories.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import java.util.*;
import java.util.stream.Collectors;

/**
 * ProfileController — Manages user profile operations.
 *
 * <h2>API Endpoint Reference</h2>
 * <pre>
 *   Base path: /api/v1/profile
 *   Security : All endpoints require authentication (any role)
 *
 *   ┌────────┬────────────┬──────────────────────────────────────────────────────┐
 *   │ Method │ Path       │ Description                                          │
 *   ├────────┼────────────┼──────────────────────────────────────────────────────┤
 *   │ GET    │ /          │ Get current user's full profile                      │
 *   │ PUT    │ /          │ Update profile (name, phone, address, etc.)          │
 *   │ PUT    │ /password  │ Change password (requires current password)          │
 *   └────────┴────────────┴──────────────────────────────────────────────────────┘
 * </pre>
 */
@RestController
@RequestMapping("/api/v1/profile")
public class ProfileController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder encoder;

    /**
     * Returns the current authenticated user's full profile.
     */
    @GetMapping
    public ResponseEntity<?> getProfile() {
        User user = getCurrentUser();
        if (user == null) {
            return ResponseEntity.status(401).body(Map.of("message", "User not found"));
        }
        return ResponseEntity.ok(buildProfileResponse(user));
    }

    /**
     * Updates the current user's profile.
     * Accepts: fullName, phone, address, city, state, pincode
     */
    @PutMapping
    public ResponseEntity<?> updateProfile(@RequestBody Map<String, String> profileData) {
        User user = getCurrentUser();
        if (user == null) {
            return ResponseEntity.status(401).body(Map.of("message", "User not found"));
        }

        if (profileData.containsKey("fullName")) {
            String fullName = profileData.get("fullName");
            if (fullName != null && !fullName.trim().isEmpty()) {
                user.setFullName(fullName.trim());
            }
        }
        if (profileData.containsKey("phone")) {
            String phone = profileData.get("phone");
            // Check uniqueness if phone is being changed
            if (phone != null && !phone.trim().isEmpty()) {
                Optional<User> existingUser = userRepository.findByPhone(phone.trim());
                if (existingUser.isPresent() && !existingUser.get().getId().equals(user.getId())) {
                    return ResponseEntity.badRequest().body(Map.of("message", "Phone number already in use"));
                }
                user.setPhone(phone.trim());
            } else {
                user.setPhone(null);
            }
        }
        if (profileData.containsKey("address")) {
            user.setAddress(profileData.get("address"));
        }
        if (profileData.containsKey("city")) {
            user.setCity(profileData.get("city"));
        }
        if (profileData.containsKey("state")) {
            user.setState(profileData.get("state"));
        }
        if (profileData.containsKey("pincode")) {
            user.setPincode(profileData.get("pincode"));
        }

        userRepository.save(user);
        return ResponseEntity.ok(buildProfileResponse(user));
    }

    /**
     * Changes the current user's password.
     * Requires: currentPassword, newPassword
     */
    @PutMapping("/password")
    public ResponseEntity<?> changePassword(@RequestBody Map<String, String> passwordData) {
        User user = getCurrentUser();
        if (user == null) {
            return ResponseEntity.status(401).body(Map.of("message", "User not found"));
        }

        String currentPassword = passwordData.get("currentPassword");
        String newPassword = passwordData.get("newPassword");

        if (currentPassword == null || newPassword == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "Both currentPassword and newPassword are required"));
        }

        if (!encoder.matches(currentPassword, user.getPassword())) {
            return ResponseEntity.badRequest().body(Map.of("message", "Current password is incorrect"));
        }

        if (newPassword.length() < 6) {
            return ResponseEntity.badRequest().body(Map.of("message", "New password must be at least 6 characters"));
        }

        user.setPassword(encoder.encode(newPassword));
        userRepository.save(user);

        return ResponseEntity.ok(Map.of("message", "Password changed successfully"));
    }

    // ─── Helpers ─────────────────────────────────────────────

    private User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return userRepository.findByEmail(auth.getName()).orElse(null);
    }

    private Map<String, Object> buildProfileResponse(User user) {
        List<String> roles = user.getRoles().stream()
                .map(Role::getName)
                .collect(Collectors.toList());

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("id", user.getId());
        response.put("email", user.getEmail());
        response.put("fullName", user.getFullName());
        response.put("phone", user.getPhone());
        response.put("address", user.getAddress());
        response.put("city", user.getCity());
        response.put("state", user.getState());
        response.put("pincode", user.getPincode());
        response.put("profilePicture", user.getProfilePicture());
        response.put("emailVerified", user.isEmailVerified());
        response.put("phoneVerified", user.isPhoneVerified());
        response.put("tenantName", user.getTenant().getName());
        response.put("roles", roles);
        response.put("createdAt", user.getCreatedAt());
        response.put("updatedAt", user.getUpdatedAt());

        return response;
    }
}
