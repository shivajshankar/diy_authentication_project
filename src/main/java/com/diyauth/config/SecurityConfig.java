package com.diyauth.config;

import com.diyauth.security.JwtAuthenticationFilter;
import com.diyauth.security.JwtTokenProvider;
import com.diyauth.service.CustomOAuth2UserService;
import com.diyauth.service.CustomUserDetailsService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.client.oidc.web.logout.OidcClientInitiatedLogoutSuccessHandler;
import org.springframework.security.oauth2.client.registration.ClientRegistrationRepository;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.util.UriComponents;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Collections;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final CustomUserDetailsService userDetailsService;
    private final JwtTokenProvider tokenProvider;
    private final CustomOAuth2UserService customOAuth2UserService;

    @Value("${cors.allowed-origins}")
    private String[] allowedOrigins;

    @Bean
    public JwtAuthenticationFilter jwtAuthenticationFilter() {
        return new JwtAuthenticationFilter(tokenProvider, userDetailsService);
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration authConfig) throws Exception {
        return authConfig.getAuthenticationManager();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .cors().and()
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.ALWAYS)
                .sessionFixation().migrateSession()
            )
            .authorizeHttpRequests(auth -> auth
                .requestMatchers(
                    "/",
                    "/index.html",
                    "/manifest.json",
                    "/static/**",
                    "/favicon.ico",
                    "/api/auth/**",
                    "/oauth2/**",
                    "/login/oauth2/**",
                    "/api/oauth2/**",
                    "/error"
                ).permitAll()
                .anyRequest().authenticated()
            )
            .oauth2Login(oauth2 -> oauth2
                .authorizationEndpoint(authorization -> authorization
                    .baseUri("/oauth2/authorization")
                )
                .redirectionEndpoint(redirection -> redirection
                    .baseUri("/login/oauth2/code/*")
                )
                .userInfoEndpoint(userInfo -> userInfo
                    .userService(customOAuth2UserService)
                )
                .successHandler((request, response, authentication) -> {
                    String targetUrl = "/api/oauth2/success";
                    request.getRequestDispatcher(targetUrl).forward(request, response);
                })
                .failureHandler((request, response, exception) -> {
                    System.out.println("\n=== OAuth2 Authentication Failure ===");
                    System.out.println("Error: " + exception.getMessage());
                    System.out.println("Request URL: " + request.getRequestURL());
                    System.out.println("Query String: " + request.getQueryString());
                    System.out.println("Session ID: " + (request.getSession(false) != null ? request.getSession().getId() : "No session"));
                    
                    // Print all request parameters
                    System.out.println("Request Parameters:");
                    request.getParameterMap().forEach((key, values) -> {
                        System.out.println("  " + key + " = " + String.join(", ", values));
                    });
                    
                    // Print important headers
                    System.out.println("Headers:");
                    System.out.println("  Host: " + request.getHeader("Host"));
                    System.out.println("  Origin: " + request.getHeader("Origin"));
                    System.out.println("  Referer: " + request.getHeader("Referer"));
                    System.out.println("  Cookie: " + request.getHeader("Cookie"));
                    
                    String targetUrl = "/api/oauth2/failure?error=" + URLEncoder.encode(
                        exception.getMessage() != null ? exception.getMessage() : "OAuth2 login failed",
                        StandardCharsets.UTF_8);
                    response.sendRedirect(targetUrl);
                })
            )
            .logout(logout -> logout
                .logoutSuccessUrl("/")
                .invalidateHttpSession(true)
                .clearAuthentication(true)
                .deleteCookies("JSESSIONID")
            )
            .addFilterBefore(jwtAuthenticationFilter(), UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowCredentials(true);
        config.addAllowedOrigin("http://shivajshankar1.duckdns.org:3000");
        config.addAllowedOrigin("http://shivajshankar1.duckdns.org:81");
        config.addAllowedOrigin("http://shivajshankar1.duckdns.org");
        config.addAllowedOrigin("http://shivajshankar2.duckdns.org:3000");
        config.addAllowedOrigin("http://localhost:3000");
        config.addAllowedOrigin("http://localhost:81");
        config.addAllowedOrigin("http://localhost");
        config.addAllowedHeader("*");
        config.addExposedHeader("Authorization");
        config.addAllowedMethod("*");
        config.setMaxAge(3600L);
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}