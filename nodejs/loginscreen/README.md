# React Authentication Frontend

This is a React-based frontend application that provides user authentication (login/register) and a protected dashboard. It connects to a Spring Boot backend with JWT authentication.

## Prerequisites

- Node.js (v14 or higher)
- npm (v6 or higher) or yarn
- Backend server running (see [Backend Setup](#backend-setup))

## Getting Started

### 1. Install Dependencies

```bash
# Navigate to the project directory
cd nodejs/loginscreen

# Install dependencies using npm or yarn
npm install
# or
yarn install
```

### 2. Environment Setup

Create a `.env` file in the `nodejs/loginscreen` directory with the following content:

```env
REACT_APP_API_URL=http://localhost:8080/api
```

### 3. Start the Development Server

```bash
# Start the development server
npm start
# or
yarn start
```

The application will open automatically in your default browser at [http://localhost:3000](http://localhost:3000).

## Available Scripts

In the project directory, you can run:

- `npm start` or `yarn start` - Runs the app in development mode
- `npm test` or `yarn test` - Launches the test runner
- `npm run build` or `yarn build` - Builds the app for production
- `npm run eject` - Ejects from Create React App (advanced)

## Project Structure

```
loginscreen/
├── public/                 # Static files
│   ├── index.html          # Main HTML template
│   └── favicon.ico         # Favicon
├── src/
│   ├── components/        # Reusable UI components
│   │   ├── Dashboard.jsx   # Protected dashboard component
│   │   ├── Login.jsx       # Login form
│   │   ├── Register.jsx    # Registration form
│   │   └── PrivateRoute.jsx # Protected route wrapper
│   ├── services/           # API and service files
│   │   └── authService.js  # Authentication service
│   ├── App.jsx             # Main application component
│   ├── index.jsx           # Application entry point
│   └── index.css           # Global styles
├── .gitignore
├── package.json            # Project dependencies and scripts
└── README.md               # This file
```

## Backend Setup

Before running the frontend, make sure the Spring Boot backend is running:

1. Navigate to the root project directory
2. Start the backend server:
   ```bash
   mvn spring-boot:run
   ```
3. The backend will be available at `http://localhost:8080`

## Authentication Flow

1. **Login**: Users can log in with their credentials
2. **JWT Token**: On successful login, a JWT token is stored in localStorage
3. **Protected Routes**: The dashboard is protected and requires authentication
4. **Auto-logout**: Users are automatically logged out when the token expires

## Environment Variables

- `REACT_APP_API_URL`: The base URL of the backend API (default: `http://localhost:8080/api`)

## Deployment

To create a production build:

```bash
npm run build
# or
yarn build
```

This will create an optimized production build in the `build` directory.

## Troubleshooting

- **CORS Issues**: Ensure the backend has the correct CORS configuration
- **Authentication Errors**: Verify the backend is running and the JWT secret matches
- **Build Failures**: Make sure all dependencies are installed

## License

This project is licensed under the MIT License.