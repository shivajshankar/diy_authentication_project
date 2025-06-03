# DIY Authentication Project

A practical implementation of authentication and authorization techniques using modern web technologies.

# Notes on Identity and Access Manaagement (terminologies and introduction)

https://docs.google.com/presentation/d/1sBi5AGHguswuyPuFN94yphvb2Nhwv2qWZI81wZ1dW84

## Features

- User registration and login
- JWT-based authentication
- Role-based access control //@Todo
- Password hashing and security best practices
- Session management
- API authentication endpoints

## Tech Stack

- Backend: Spring Boot
- Frontend: HTML, CSS, JavaScript
- Database: MongoDB
- Authentication: JWT
- Security: Spring Security
- Build Tool: Maven/Gradle

## Getting Started

### Prerequisites

- Java 11 or higher
- Maven or Gradle
- IDE (IntelliJ IDEA, Eclipse, or VS Code)
- [Specify any other prerequisites]

### Installation

1. Clone the repository:
```bash
git clone [repository-url]
cd diy-authentication-project
```

2. Build the project:
```bash
# Using Maven
mvn clean install

# Using Gradle
./gradlew build
```

3. Configure application properties:
Create a `application.properties` file in `src/main/resources` with:
```
spring.datasource.url=jdbc:mysql://localhost:3306/auth_db
spring.datasource.username=root
spring.datasource.password=your_password
spring.security.jwt.secret=your-secret-key
```

4. Run the application:
```bash
# Using Maven
mvn spring-boot:run

# Using Gradle
./gradlew bootRun
```

## Project Structure

```
diy-authentication-project/
├── src/
│   ├── controllers/
│   ├── middleware/
│   ├── models/
│   ├── routes/
│   └── utils/
├── public/
├── config/
└── tests/
```

## Security Features

- Password hashing using bcrypt (Done)
- JWT token validation //@Todo
- CSRF protection //@Todo
- Input validation //@Todo
- Rate limiting //@Todo
- Secure session management //@Todo

## API Endpoints

- POST `/auth/register` - User registration
- POST `/auth/login` - User login
- GET `/auth/profile` - Get user profile (protected)
- POST `/auth/logout` - User logout

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazonFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is open source.

## Acknowledgments

- Inspired by modern authentication best practices
- Thanks to the open-source community for their contributions
