package com.diyauth.repository;

import com.diyauth.model.User;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.Optional;

public interface UserRepository extends MongoRepository<User, String> {
    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);
    Boolean existsByUsername(String username);
    Boolean existsByEmail(String email);
    
    // For OAuth2
    Optional<User> findByProviderAndProviderId(String provider, String providerId);
}
