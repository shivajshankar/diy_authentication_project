#!/bin/bash

# Create main application class
echo "package com.diyauth;" > src/main/java/com/diyauth/DiyAuthApplication.java
cat << EOF >> src/main/java/com/diyauth/DiyAuthApplication.java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class DiyAuthApplication {
    public static void main(String[] args) {
        SpringApplication.run(DiyAuthApplication.class, args);
    }
}
EOF

# Create pom.xml
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > pom.xml
cat << EOF >> pom.xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.diyauth</groupId>
    <artifactId>diy-auth</artifactId>
    <version>1.0.0</version>
    <name>diy-auth</name>
    <description>DIY Authentication Project</description>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.1.0</version>
    </parent>

    <properties>
        <java.version>17</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
            <version>8.0.33</version>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-api</artifactId>
            <version>0.12.3</version>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-impl</artifactId>
            <version>0.12.3</version>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-jackson</artifactId>
            <version>0.12.3</version>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <excludes>
                        <exclude>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                        </exclude>
                    </excludes>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
EOF

# Create application.properties
echo "server.port=8080" > src/main/resources/application.properties
echo "spring.datasource.url=jdbc:mysql://localhost:3306/auth_db" >> src/main/resources/application.properties
echo "spring.datasource.username=root" >> src/main/resources/application.properties
echo "spring.datasource.password=your_password" >> src/main/resources/application.properties
echo "spring.jpa.hibernate.ddl-auto=update" >> src/main/resources/application.properties
echo "spring.jpa.show-sql=true" >> src/main/resources/application.properties
echo "spring.jpa.properties.hibernate.format_sql=true" >> src/main/resources/application.properties
echo "spring.security.jwt.secret=your-secret-key" >> src/main/resources/application.properties

# Create .gitignore
echo "target/" > .gitignore
echo ".DS_Store" >> .gitignore
echo ".idea/" >> .gitignore
echo ".vscode/" >> .gitignore
echo ".mvn/" >> .gitignore
echo "mvnw" >> .gitignore
echo "mvnw.cmd" >> .gitignore
echo "*.iml" >> .gitignore
echo ".m2/repository" >> .gitignore
echo ".gradle" >> .gitignore
echo "build/" >> .gitignore

# Create README.md if it doesn't exist
if [ ! -f README.md ]; then
    echo "# DIY Authentication Project" > README.md
    echo "" >> README.md
    echo "A practical implementation of authentication and authorization techniques using Spring Boot." >> README.md
fi

echo "Basic Spring Boot project setup completed!"