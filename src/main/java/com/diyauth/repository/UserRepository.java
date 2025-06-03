package com.diyauth.repository;

import com.diyauth.model.User;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.Optional;

public interface UserRepository extends MongoRepository<User, String> {
    Optional<User> findByEmail(String email);
    Boolean existsByEmail(String email);
    
    // Add these methods to match UserService requirements
    Optional<User> findByUsername(String username);
    Boolean existsByUsername(String username);
}
