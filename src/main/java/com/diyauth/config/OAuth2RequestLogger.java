package com.diyauth.config;

import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@Component
@Order(1)
public class OAuth2RequestLogger extends OncePerRequestFilter {
    
    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        
        String path = request.getRequestURI();
        
        if (path.contains("oauth2") || path.contains("login")) {
            System.out.println("\n=== OAuth2 Request ===");
            System.out.println("URL: " + request.getRequestURL());
            System.out.println("Query: " + request.getQueryString());
            System.out.println("Method: " + request.getMethod());
            System.out.println("Session ID: " + (request.getSession(false) != null ? request.getSession().getId() : "No session"));
            
            // Log important headers
            System.out.println("Headers:");
            System.out.println("  Host: " + request.getHeader("Host"));
            System.out.println("  Origin: " + request.getHeader("Origin"));
            System.out.println("  Referer: " + request.getHeader("Referer"));
            System.out.println("  Cookie: " + request.getHeader("Cookie"));
            
            // Log parameters
            System.out.println("Parameters:");
            request.getParameterMap().forEach((key, values) -> {
                System.out.println("  " + key + " = " + String.join(", ", values));
            });
        }
        
        filterChain.doFilter(request, response);
    }
}
