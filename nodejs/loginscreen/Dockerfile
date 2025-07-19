# Build stage
FROM node:18-alpine as build

# Set working directory
WORKDIR /app

# Copy package files first to leverage Docker cache
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application
COPY . .

# Set production environment variables
ENV REACT_APP_API_URL=http://shivajshankar.duckdns.org:8080/api
ENV REACT_APP_GOOGLE_AUTH_URL=http://shivajshankar.duckdns.org:8080/oauth2/authorization/google
ENV REACT_APP_ENV=production

# Print the environment variables being used
RUN echo "Building with the following environment variables:" && \
    echo "REACT_APP_API_URL=$REACT_APP_API_URL" && \
    echo "REACT_APP_GOOGLE_AUTH_URL=$REACT_APP_GOOGLE_AUTH_URL" && \
    echo "REACT_APP_ENV=$REACT_APP_ENV"

# Build the production build
RUN npm run build

# Production stage
FROM node:18-alpine

WORKDIR /app

# Install serve to serve the build folder
RUN npm install -g serve

# Copy the built app from the build stage
COPY --from=build /app/build ./build

# Expose port 3000 for the production server
EXPOSE 3000

# Start the production server
CMD ["serve", "-s", "build", "-l", "3000"]