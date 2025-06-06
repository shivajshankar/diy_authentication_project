package com.diyauth.security.oauth2.user;

import com.diyauth.model.User;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.oauth2.core.user.OAuth2User;

import java.util.Collection;
import java.util.Map;

public class OAuth2UserPrincipal implements OAuth2User {
    private final Map<String, Object> attributes;
    private final Collection<? extends GrantedAuthority> authorities;
    private final User user;

    public OAuth2UserPrincipal(Map<String, Object> attributes, 
                             Collection<? extends GrantedAuthority> authorities,
                             User user) {
        this.attributes = attributes;
        this.authorities = authorities;
        this.user = user;
    }

    @Override
    public Map<String, Object> getAttributes() {
        return attributes;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override
    public String getName() {
        return user.getUsername();
    }


    public User getUser() {
        return user;
    }
}
