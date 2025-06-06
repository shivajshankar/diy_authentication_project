package com.diyauth;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.EnableAspectJAutoProxy;
import org.springframework.data.mongodb.config.EnableMongoAuditing;
import org.springframework.data.mongodb.repository.config.EnableMongoRepositories;

@SpringBootApplication
@EnableMongoRepositories
@EnableMongoAuditing
@EnableAspectJAutoProxy(proxyTargetClass = true)
public class DiyAuthApplication {
    public static void main(String[] args) {
        SpringApplication.run(DiyAuthApplication.class, args);
    }
}
