package com.diyauth.controller;

import com.diyauth.model.User;
import com.diyauth.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    
    @Autowired
    private UserService userService;
    
    @Autowired
    private PasswordEncoder passwordEncoder;
    
    @PostMapping("/register")
    public String register(@RequestParam String username, @RequestParam String password) {
        userService.registerUser(username, password);
        return "User registered successfully";
    }
    
    @GetMapping("/test")
    public String test() {
        return "Hello, this is a protected endpoint";
    }
    
    @PostMapping("/validateUser")
    public boolean validateUser(@RequestParam String username, @RequestParam String password) {
        User user = userService.findByUsername(username);
        if (user == null) {
            return false;
        }
        return passwordEncoder.matches(password, user.getPassword());
    }
}
