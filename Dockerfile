# Use Node 18 for development and building (supports package-lock v2)
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install system dependencies for Electron and ImageMagick
RUN apk add --no-cache \
    # Electron dependencies
    libc6-compat \
    # ImageMagick for icon building
    imagemagick \
    # Additional dependencies that might be needed
    git \
    python3 \
    make \
    g++ \
    # For building native modules
    build-base

# Copy package files first for better caching
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Create assets directory if it doesn't exist
RUN mkdir -p assets

# Expose port for development server (if needed)
EXPOSE 5173

# Default command
CMD ["npm", "run", "dev"] 