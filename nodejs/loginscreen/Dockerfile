# Stage 1: Build and serve the React application
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application
COPY . .

# Set environment variables
ARG REACT_APP_API_URL
ARG REACT_APP_ENV=production
ARG REACT_APP_GOOGLE_AUTH_URL

ENV REACT_APP_API_URL=${REACT_APP_API_URL}
ENV REACT_APP_ENV=${REACT_APP_ENV}
ENV REACT_APP_GOOGLE_AUTH_URL=${REACT_APP_GOOGLE_AUTH_URL}

# Expose port 3000
EXPOSE 3000

# Start the React development server
CMD ["npm", "start"]
