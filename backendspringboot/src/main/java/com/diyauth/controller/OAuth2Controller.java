package com.diyauth.controller;

import com.diyauth.security.JwtTokenProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@RestController
@RequestMapping("/api/oauth2")
@CrossOrigin(origins = "${cors.allowed-origins}", allowCredentials = "true")
public class OAuth2Controller {

    private final JwtTokenProvider tokenProvider;
    
    @Value("${app.frontend-url:http://localhost:3000}")
    private String frontendUrl;

    public OAuth2Controller(JwtTokenProvider tokenProvider) {
        this.tokenProvider = tokenProvider;
    }

    @GetMapping("/success")
    public void oauth2Success(
            @AuthenticationPrincipal OAuth2User oauth2User,
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {
        System.out.println("\n=== OAuth2 Success Handler ===");
        
        if (oauth2User == null) {
            System.out.println("ERROR: OAuth2User is null in success handler");
            response.sendError(HttpStatus.UNAUTHORIZED.value(), "Authentication failed");
            return;
        }

        System.out.println("OAuth2User Name: " + oauth2User.getName());
        System.out.println("OAuth2User Attributes: " + oauth2User.getAttributes().keySet());
        
        // Debug: Print all attributes
        System.out.println("\n=== All OAuth2User Attributes ===");
        oauth2User.getAttributes().forEach((k, v) -> 
            System.out.println(k + ": " + v)
        );

        String email = oauth2User.getAttribute("email");
        if (email == null) {
            System.out.println("ERROR: Email not found in OAuth2 user attributes");
            response.sendError(HttpStatus.BAD_REQUEST.value(), "Email not found in OAuth2 user");
            return;
        }

        // Get the JWT token that was set in CustomOAuth2UserService
        String token = oauth2User.getAttribute("token");
        System.out.println("\n=== Retrieved JWT Token ===");
        System.out.println("Token from attributes: " + token);
        System.out.println("Token class: " + (token != null ? token.getClass().getName() : "null"));

        String name = oauth2User.getAttribute("name");
        if (name == null) {
            name = email.split("@")[0];
        }

        String redirectUrl = String.format(
            "%s/oauth2/redirect?token=%s&email=%s&name=%s",
            frontendUrl,
            token != null ? URLEncoder.encode(token, StandardCharsets.UTF_8) : "",
            URLEncoder.encode(email, StandardCharsets.UTF_8),
            URLEncoder.encode(name, StandardCharsets.UTF_8)
        );

        System.out.println("\n=== Redirecting to Frontend ===");
        System.out.println("Redirect URL: " + redirectUrl);
        
        // Add CORS headers
        response.setHeader("Access-Control-Allow-Origin", request.getHeader("Origin"));
        response.setHeader("Access-Control-Allow-Credentials", "true");
        
        // Redirect to frontend with token
        response.sendRedirect(redirectUrl);
    }

    @GetMapping("/failure")
    public void oauth2Failure(
            @RequestParam(value = "error", required = false) String error,
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {
        String errorMessage = error != null ? error : "OAuth2 login failed";
        String redirectUrl = String.format(
            "%s/login?error=%s",
            frontendUrl,
            URLEncoder.encode(errorMessage, StandardCharsets.UTF_8)
        );
        
        // Add CORS headers
        response.setHeader("Access-Control-Allow-Origin", request.getHeader("Origin"));
        response.setHeader("Access-Control-Allow-Credentials", "true");
        
        response.sendRedirect(redirectUrl);
    }
}
