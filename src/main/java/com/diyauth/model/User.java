package com.diyauth.model;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.core.user.OAuth2User;

import java.util.*;
import java.util.stream.Collectors;

@Data
@Document(collection = "users")
public class User {
    @Id
    private String id;
    private String username;
    private String email;
    private String password;
    private boolean enabled;
    private String[] roles;
    private String provider;
    private String providerId;
    private String imageUrl;

    // OAuth2 specific fields
    private Map<String, Object> attributes;

    public User() {
        this.enabled = true;
        this.roles = new String[]{"ROLE_USER"};
    }

    public User(String username, String email, String password) {
        this();
        this.username = username;
        this.email = email;
        this.password = password;
    }

    // For OAuth2 users
    public User(String provider, String providerId, String name, String email, String imageUrl) {
        this();
        this.provider = provider;
        this.providerId = providerId;
        this.username = name;
        this.email = email;
        this.imageUrl = imageUrl;
        this.password = UUID.randomUUID().toString(); // Random password for OAuth users
    }

    public Map<String, Object> getAttributes() {
        return attributes != null ? attributes : new HashMap<>();
    }

    public void setAttributes(Map<String, Object> attributes) {
        this.attributes = attributes;
    }

    public Collection<? extends GrantedAuthority> getAuthorities() {
        return Arrays.stream(roles)
                .map(SimpleGrantedAuthority::new)
                .collect(Collectors.toList());
    }
}
