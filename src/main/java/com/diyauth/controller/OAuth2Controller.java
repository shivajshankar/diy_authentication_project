package com.diyauth.controller;

import com.diyauth.security.JwtTokenProvider;
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
@CrossOrigin(origins = "${app.cors.allowed-origins}", allowCredentials = "true")
public class OAuth2Controller {

    private final JwtTokenProvider tokenProvider;

    public OAuth2Controller(JwtTokenProvider tokenProvider) {
        this.tokenProvider = tokenProvider;
    }

    @GetMapping("/success")
    public void oauth2Success(
            @AuthenticationPrincipal OAuth2User oauth2User,
            HttpServletRequest request,
            HttpServletResponse response
    ) throws IOException {
        if (oauth2User == null) {
            response.sendError(HttpStatus.UNAUTHORIZED.value(), "Authentication failed");
            return;
        }

        String email = oauth2User.getAttribute("email");
        if (email == null) {
            response.sendError(HttpStatus.BAD_REQUEST.value(), "Email not found in OAuth2 user");
            return;
        }

        // Create JWT token
        String token = tokenProvider.generateToken(email);
        String name = oauth2User.getAttribute("name");
        if (name == null) {
            name = email.split("@")[0];
        }

        // Build the redirect URL
        String frontendUrl = "http://localhost:3000";
        String redirectUrl = String.format(
            "%s/oauth2/redirect?token=%s&email=%s&name=%s",
            frontendUrl,
            URLEncoder.encode(token, StandardCharsets.UTF_8),
            URLEncoder.encode(email, StandardCharsets.UTF_8),
            URLEncoder.encode(name, StandardCharsets.UTF_8)
        );

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
        String frontendUrl = "http://localhost:3000";
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
