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

@Service
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    @Autowired
    public CustomUserDetailsService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    @Transactional
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        System.out.println("Loading user by username: " + username);
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> {
                    System.out.println("User not found: " + username);
                    return new UsernameNotFoundException("User not found with username: " + username);
                });

        System.out.println("User found, username: " + user.getUsername() + 
                         ", enabled: " + user.isEnabled() + 
                         ", password: " + user.getPassword().substring(0, 10) + "...");
        return UserPrincipal.create(user);
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

        System.out.println("User found by ID: " + user.getUsername());
        return UserPrincipal.create(user);
    }
}
