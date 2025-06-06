package com.diyauth.service;

import com.diyauth.model.User;
import com.diyauth.repository.UserRepository;
import com.diyauth.security.UserPrincipal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    @Autowired
    public CustomUserDetailsService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    @Transactional
    public UserDetails loadUserByUsername(String usernameOrEmail) throws UsernameNotFoundException {
        System.out.println("Loading user by username or email: " + usernameOrEmail);
        
        // First try to find by username
        Optional<User> userByUsername = userRepository.findByUsername(usernameOrEmail);
        if (userByUsername.isPresent()) {
            User user = userByUsername.get();
            System.out.println("User found by username: " + user.getUsername() + 
                             ", enabled: " + user.isEnabled() + 
                             ", password: " + user.getPassword().substring(0, 10) + "...");
            return UserPrincipal.create(user);
        }
        
        // If not found by username, try to find by email
        Optional<User> userByEmail = userRepository.findByEmail(usernameOrEmail);
        if (userByEmail.isPresent()) {
            User user = userByEmail.get();
            System.out.println("User found by email: " + user.getEmail() + 
                             ", username: " + user.getUsername() + 
                             ", enabled: " + user.isEnabled() + 
                             ", password: " + user.getPassword().substring(0, 10) + "...");
            return UserPrincipal.create(user);
        }
        
        System.out.println("User not found with username/email: " + usernameOrEmail);
        throw new UsernameNotFoundException("User not found with username/email: " + usernameOrEmail);
    }

    @Transactional
    public UserDetails loadUserById(String id) {
        System.out.println("Loading user by ID: " + id);
        User user = userRepository.findById(id).orElseThrow(
            () -> {
                System.out.println("User not found with ID: " + id);
                return new UsernameNotFoundException("User not found with id: " + id);
            }
        );

        System.out.println("User found by ID: " + user.getUsername() + 
                         ", email: " + user.getEmail() + 
                         ", enabled: " + user.isEnabled());
        return UserPrincipal.create(user);
    }

    @Transactional
    public UserDetails loadUserByEmail(String email) throws UsernameNotFoundException {
        System.out.println("Loading user by email: " + email);
        User user = userRepository.findByEmail(email)
            .orElseThrow(() -> {
                System.out.println("User not found with email: " + email);
                return new UsernameNotFoundException("User not found with email: " + email);
            });

        System.out.println("User found by email: " + user.getEmail() + 
                         ", username: " + user.getUsername() + 
                         ", enabled: " + user.isEnabled());
        return UserPrincipal.create(user);
    }
}
