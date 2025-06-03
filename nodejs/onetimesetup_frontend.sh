#!/bin/bash

# Create the main directory structure
mkdir -p loginscreen/src/{components,services}
mkdir -p loginscreen/public

# Create empty files
# Root directory
touch loginscreen/package.json
touch loginscreen/.env
touch loginscreen/README.md

# Public directory
touch loginscreen/public/index.html
touch loginscreen/public/favicon.ico

# Source directory
touch loginscreen/src/App.jsx
touch loginscreen/src/index.jsx
touch loginscreen/src/index.css

# Components
touch loginscreen/src/components/Login.jsx
touch loginscreen/src/components/Dashboard.jsx
touch loginscreen/src/components/PrivateRoute.jsx

# Services
touch loginscreen/src/services/authService.js

# Set execute permissions on the script (for Linux/Mac)
chmod +x setup_frontend.sh

echo "React frontend directory structure created successfully in 'loginscreen' directory!"
echo "Run the following commands to set up the project:"
echo "1. cd loginscreen"
echo "2. npm install"
echo "3. Copy the provided file contents into their respective files"
echo "4. npm start"