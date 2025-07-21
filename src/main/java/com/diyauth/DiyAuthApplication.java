package com.diyauth;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.EnableAspectJAutoProxy;
import org.springframework.data.mongodb.config.EnableMongoAuditing;
import org.springframework.data.mongodb.repository.config.EnableMongoRepositories;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@SpringBootApplication
@EnableMongoRepositories
@EnableMongoAuditing
@EnableAspectJAutoProxy(proxyTargetClass = true)
public class DiyAuthApplication {
    private static final Logger logger = LoggerFactory.getLogger(DiyAuthApplication.class);
    public static void main(String[] args) {
        SpringApplication.run(DiyAuthApplication.class, args);
        logger.info("DIY Auth Application started successfully");
    }
}
