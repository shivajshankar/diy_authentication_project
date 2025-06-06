package com.diyauth.service;

import com.diyauth.model.AuthProvider;
import com.diyauth.model.User;
import com.diyauth.repository.UserRepository;
import com.diyauth.security.JwtTokenProvider;
import com.diyauth.security.UserPrincipal;
import com.diyauth.security.oauth2.user.OAuth2UserInfo;
import com.diyauth.security.oauth2.user.OAuth2UserInfoFactory;
import com.diyauth.exception.OAuth2AuthenticationProcessingException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.InternalAuthenticationServiceException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.oauth2.client.userinfo.DefaultOAuth2UserService;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserRequest;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.*;

@Service
public class CustomOAuth2UserService extends DefaultOAuth2UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtTokenProvider tokenProvider;

    @Override
    public OAuth2User loadUser(OAuth2UserRequest oAuth2UserRequest) throws OAuth2AuthenticationException {
        try {
            OAuth2User oAuth2User = super.loadUser(oAuth2UserRequest);
            return processOAuth2User(oAuth2UserRequest, oAuth2User);
        } catch (OAuth2AuthenticationException ex) {
            throw ex;
        } catch (Exception ex) {
            // Wrap any other exception and include the original exception as the cause
            throw new InternalAuthenticationServiceException("OAuth2 authentication failed: " + ex.getMessage(), ex);
        }
    }

    private OAuth2User processOAuth2User(OAuth2UserRequest oAuth2UserRequest, OAuth2User oAuth2User) {
        try {
            String registrationId = oAuth2UserRequest.getClientRegistration().getRegistrationId();
            
            // Debug: Print OAuth2 user attributes
            System.out.println("\n=== OAuth2 User Attributes ===");
            oAuth2User.getAttributes().forEach((k, v) -> 
                System.out.println(k + ": " + v)
            );
            
            OAuth2UserInfo oAuth2UserInfo = OAuth2UserInfoFactory.getOAuth2UserInfo(
                registrationId, 
                oAuth2User.getAttributes()
            );

            if (oAuth2UserInfo == null) {
                throw new OAuth2AuthenticationProcessingException("Failed to create OAuth2 user info");
            }

            if (!StringUtils.hasText(oAuth2UserInfo.getEmail())) {
                throw new OAuth2AuthenticationProcessingException("Email not found from OAuth2 provider");
            }

            String email = oAuth2UserInfo.getEmail();
            Optional<User> userOptional = userRepository.findByEmail(email);
            
            User user;
            if (userOptional.isPresent()) {
                user = userOptional.get();
                String provider = AuthProvider.valueOf(registrationId).name();
                if (!user.getProvider().equals(provider)) {
                    throw new OAuth2AuthenticationProcessingException(
                        String.format("Looks like you're signed up with %s account. Please use your %s account to login.", 
                        user.getProvider(), user.getProvider())
                    );
                }
                user = updateExistingUser(user, oAuth2UserInfo);
            } else {
                user = registerNewUser(oAuth2UserRequest, oAuth2UserInfo);
            }

            // Generate JWT token
            System.out.println("\n=== Generating JWT Token ===");
            String token = tokenProvider.generateToken(user.getEmail());
            System.out.println("Generated JWT Token: " + token);
            
            // Create a new mutable map with the existing attributes
            Map<String, Object> attributes = new HashMap<>(oAuth2User.getAttributes());
            // Add the token to the attributes
            attributes.put("token", token);
            System.out.println("Added token to user attributes. Attributes size: " + attributes.size());
            
            // Create user principal with the new attributes map
            UserPrincipal userPrincipal = UserPrincipal.create(user, attributes);
            System.out.println("Created UserPrincipal with username: " + userPrincipal.getUsername());
            
            return userPrincipal;
            
        } catch (OAuth2AuthenticationException ex) {
            System.err.println("OAuth2 Authentication Error: " + ex.getMessage());
            throw ex;
        } catch (Exception ex) {
            System.err.println("Error in processOAuth2User: " + ex.getClass().getName() + ": " + ex.getMessage());
            ex.printStackTrace();
            throw new OAuth2AuthenticationProcessingException("Error processing OAuth2 user: " + ex.getMessage(), ex);
        }
    }

    private User registerNewUser(OAuth2UserRequest oAuth2UserRequest, OAuth2UserInfo oAuth2UserInfo) {
        try {
            User user = new User();
            String registrationId = oAuth2UserRequest.getClientRegistration().getRegistrationId();
            
            user.setProvider(AuthProvider.valueOf(registrationId).name());
            user.setProviderId(oAuth2UserInfo.getId());
            user.setUsername(oAuth2UserInfo.getEmail().split("@")[0]);
            user.setEmail(oAuth2UserInfo.getEmail());
            user.setImageUrl(oAuth2UserInfo.getImageUrl());
            
            // Set default role or any other required fields
            // user.setActive(true);  // Removed as it doesn't exist in User class
            
            return userRepository.save(user);
            
        } catch (Exception ex) {
            System.err.println("Error registering new user: " + ex.getMessage());
            throw new OAuth2AuthenticationProcessingException("Failed to register new user: " + ex.getMessage(), ex);
        }
    }

    private User updateExistingUser(User existingUser, OAuth2UserInfo oAuth2UserInfo) {
        try {
            existingUser.setImageUrl(oAuth2UserInfo.getImageUrl());
            return userRepository.save(existingUser);
        } catch (Exception ex) {
            System.err.println("Error updating existing user: " + ex.getMessage());
            throw new OAuth2AuthenticationProcessingException("Failed to update existing user: " + ex.getMessage(), ex);
        }
    }
}
