# Create environment files
cat > nodejs/loginscreen/.env.development << 'EOL'
REACT_APP_API_URL=http://localhost:8080/api
REACT_APP_ENV=development
EOL

cat > nodejs/loginscreen/.env.production << 'EOL'
REACT_APP_API_URL=http://shivajshankar1.duckdns.org:8080/api
REACT_APP_ENV=production
EOL

cat > nodejs/loginscreen/.env.example << 'EOL'
# Copy this file to .env.development or .env.production and update the values
REACT_APP_API_URL=http://localhost:8080/api
REACT_APP_ENV=development
EOL
