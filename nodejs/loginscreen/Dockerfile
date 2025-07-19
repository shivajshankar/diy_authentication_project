# Use Node.js 18 Alpine as the base image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application
COPY . .

# Set environment variables with defaults
ENV REACT_APP_API_URL=${REACT_APP_API_URL:-http://localhost:8080/api}
ENV REACT_APP_GOOGLE_AUTH_URL=${REACT_APP_GOOGLE_AUTH_URL:-http://localhost:8080/oauth2/authorization/google}
ENV REACT_APP_ENV=${REACT_APP_ENV:-development}

# Expose port 3000 for the development server
EXPOSE 3000

# Start the React development server
CMD ["npm", "start"]