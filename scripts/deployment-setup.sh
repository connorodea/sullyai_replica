#!/bin/bash

# Deployment setup script for DentalAI Assistant
# Configures production deployment settings

set -e  # Exit on any error

# Define color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f "$HOME/dental-ai-assistant/.env" ]; then
    source "$HOME/dental-ai-assistant/.env"
fi

# Project directories
PROJECT_DIR="$HOME/dental-ai-assistant"
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/frontend"
DEPLOYMENT_DIR="$PROJECT_DIR/deployment"

echo -e "${BLUE}"
echo "======================================================"
echo "       DentalAI Assistant Deployment Setup            "
echo "======================================================"
echo -e "${NC}"

# Create deployment directory
mkdir -p "$DEPLOYMENT_DIR"
mkdir -p "$DEPLOYMENT_DIR/configs"
mkdir -p "$DEPLOYMENT_DIR/scripts"

# Create production Docker Compose file
echo -e "${GREEN}Creating production Docker Compose configuration...${NC}"
cat > "$DEPLOYMENT_DIR/docker-compose.prod.yml" << EOL
version: '3.8'

services:
  mongodb:
    image: mongo:5.0
    container_name: dental-ai-mongodb
    restart: always
    volumes:
      - mongodb-data:/data/db
      - ./configs/mongodb.conf:/etc/mongodb.conf
    ports:
      - "27017:27017"
    command: mongod --config /etc/mongodb.conf
    environment:
      - MONGO_INITDB_ROOT_USERNAME=\${MONGO_USERNAME}
      - MONGO_INITDB_ROOT_PASSWORD=\${MONGO_PASSWORD}
      - MONGO_INITDB_DATABASE=dental-ai
    networks:
      - dental-ai-network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  backend:
    build:
      context: ../backend
      dockerfile: Dockerfile.prod
    container_name: dental-ai-backend
    restart: always
    volumes:
      - ./logs:/app/logs
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - PORT=3000
      - MONGODB_URI=mongodb://\${MONGO_USERNAME}:\${MONGO_PASSWORD}@mongodb:27017/dental-ai?authSource=admin
      - JWT_SECRET=\${JWT_SECRET}
      - JWT_EXPIRATION=\${JWT_EXPIRATION}
      - OPENAI_API_KEY=\${OPENAI_API_KEY}
      - ANTHROPIC_API_KEY=\${ANTHROPIC_API_KEY}
      - PRIMARY_AI_SERVICE=\${PRIMARY_AI_SERVICE}
    depends_on:
      - mongodb
    networks:
      - dental-ai-network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "5"

  frontend:
    build:
      context: ../frontend
      dockerfile: Dockerfile.prod
    container_name: dental-ai-frontend
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./configs/nginx.conf:/etc/nginx/conf.d/default.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - backend
    networks:
      - dental-ai-network
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

networks:
  dental-ai-network:
    driver: bridge

volumes:
  mongodb-data:
EOL

# Create production environment file template
echo -e "${GREEN}Creating production environment file template...${NC}"
cat > "$DEPLOYMENT_DIR/.env.example" << EOL
# Production Environment Variables

# MongoDB
MONGO_USERNAME=dental_admin
MONGO_PASSWORD=change_this_to_secure_password

# JWT
JWT_SECRET=change_this_to_a_secure_random_string
JWT_EXPIRATION=24h

# AI Services
OPENAI_API_KEY=your_openai_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here
PRIMARY_AI_SERVICE=openai
EOL

# Create backend production Dockerfile
echo -e "${GREEN}Creating backend production Dockerfile...${NC}"
cat > "$BACKEND_DIR/Dockerfile.prod" << EOL
FROM node:16-alpine

WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install production dependencies
RUN npm ci --only=production

# Copy app source
COPY . .

# Create logs directory
RUN mkdir -p logs

# Set environment to production
ENV NODE_ENV=production

# Expose port
EXPOSE 3000

# Start the app
CMD ["node", "src/server.js"]
EOL

# Create frontend production Dockerfile
echo -e "${GREEN}Creating frontend production Dockerfile...${NC}"
cat > "$FRONTEND_DIR/Dockerfile.prod" << EOL
# Build stage
FROM node:16-alpine as build

WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy app source
COPY . .

# Build the app
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy build files from build stage
COPY --from=build /app/build /usr/share/nginx/html

# Copy nginx config
COPY deployment/configs/nginx.conf /etc/nginx/conf.d/default.conf

# Expose ports
EXPOSE 80 443

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
EOL

# Create Nginx configuration
echo -e "${GREEN}Creating Nginx configuration...${NC}"
mkdir -p "$DEPLOYMENT_DIR/configs"
cat > "$DEPLOYMENT_DIR/configs/nginx.conf" << EOL
server {
    listen 80;
    server_name _;
    
    # Redirect all HTTP requests to HTTPS
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name _;
    
    # SSL configuration
    ssl_certificate /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Frontend static files
    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
        try_files \$uri \$uri/ /index.html;
    }
    
    # Backend API
    location /api {
        proxy_pass http://backend:3000/api;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # WebSocket for real-time features
    location /socket.io {
        proxy_pass http://backend:3000/socket.io;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

# Create MongoDB configuration
echo -e "${GREEN}Creating MongoDB configuration...${NC}"
cat > "$DEPLOYMENT_DIR/configs/mongodb.conf" << EOL
# MongoDB configuration file for production

# Where and how to store data
storage:
  dbPath: /data/db
  journal:
    enabled: true

# Where to write logging data
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# Network interfaces
net:
  port: 27017
  bindIp: 0.0.0.0

# Security
security:
  authorization: enabled

# Replica set settings (optional)
#replication:
#  replSetName: rs0
EOL

# Create SSL directory and generate self-signed certificates for development
echo -e "${GREEN}Creating SSL directory and generating self-signed certificates...${NC}"
mkdir -p "$DEPLOYMENT_DIR/ssl"

# Only generate self-signed certificates if they don't exist yet
if [ ! -f "$DEPLOYMENT_DIR/ssl/server.crt" ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$DEPLOYMENT_DIR/ssl/server.key" \
        -out "$DEPLOYMENT_DIR/ssl/server.crt" \
        -subj "/CN=localhost/O=DentalAI Assistant/C=US" \
        -addext "subjectAltName = DNS:localhost,IP:127.0.0.1" \
        2>/dev/null
    
    echo -e "${YELLOW}Self-signed SSL certificates generated for development.${NC}"
    echo -e "${YELLOW}For production, replace with valid certificates from a trusted CA.${NC}"
else
    echo -e "${YELLOW}SSL certificates already exist. Skipping generation.${NC}"
fi

# Create deployment scripts
echo -e "${GREEN}Creating deployment scripts...${NC}"

# Create deploy script
cat > "$DEPLOYMENT_DIR/scripts/deploy.sh" << EOL
#!/bin/bash

# Deployment script for DentalAI Assistant
# Usage: ./deploy.sh [production|staging]

# Set environment
ENV=\${1:-production}
echo "Deploying to \$ENV environment..."

# Change to deployment directory
cd \$(dirname "\$0")/..

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "Error: .env file not found."
    echo "Please create .env file based on .env.example before deploying."
    exit 1
fi

# Load environment variables
source .env

# Deploy with Docker Compose
echo "Starting deployment with Docker Compose..."
docker-compose -f docker-compose.\$ENV.yml down
docker-compose -f docker-compose.\$ENV.yml build
docker-compose -f docker-compose.\$ENV.yml up -d

echo "Deployment completed successfully."
EOL

# Create backup script
cat > "$DEPLOYMENT_DIR/scripts/backup.sh" << EOL
#!/bin/bash

# Backup script for DentalAI Assistant
# Usage: ./backup.sh [backup_name]

# Load environment variables
source .env

# Get backup name from command line argument or use current date
BACKUP_NAME=\${1:-\$(date +"%Y%m%d_%H%M%S")}
BACKUP_DIR="./backups"

# Create backup directory if it doesn't exist
mkdir -p "\$BACKUP_DIR"

# Create MongoDB backup
echo "Creating MongoDB backup..."
docker exec dental-ai-mongodb mongodump --username=\$MONGO_USERNAME --password=\$MONGO_PASSWORD --authenticationDatabase=admin --out=/tmp/backup

# Copy backup from container to host
docker cp dental-ai-mongodb:/tmp/backup "\$BACKUP_DIR/\$BACKUP_NAME"

# Clean up temporary backup in container
docker exec dental-ai-mongodb rm -rf /tmp/backup

# Compress backup
echo "Compressing backup..."
tar -czf "\$BACKUP_DIR/\$BACKUP_NAME.tar.gz" -C "\$BACKUP_DIR" "\$BACKUP_NAME"

# Remove uncompressed backup
rm -rf "\$BACKUP_DIR/\$BACKUP_NAME"

echo "Backup created: \$BACKUP_DIR/\$BACKUP_NAME.tar.gz"
EOL

# Create restore script
cat > "$DEPLOYMENT_DIR/scripts/restore.sh" << EOL
#!/bin/bash

# Restore script for DentalAI Assistant
# Usage: ./restore.sh <backup_file>

# Check if backup file is provided
if [ -z "\$1" ]; then
    echo "Error: Backup file is required."
    echo "Usage: ./restore.sh <backup_file>"
    exit 1
fi

# Load environment variables
source .env

BACKUP_FILE="\$1"
TEMP_DIR="./temp_restore"

# Check if backup file exists
if [ ! -f "\$BACKUP_FILE" ]; then
    echo "Error: Backup file \$BACKUP_FILE not found."
    exit 1
fi

# Create temporary directory
mkdir -p "\$TEMP_DIR"

# Extract backup
echo "Extracting backup..."
tar -xzf "\$BACKUP_FILE" -C "\$TEMP_DIR"

# Get the directory name inside the backup
BACKUP_DIR=\$(ls -d "\$TEMP_DIR"/*/)
BACKUP_DIR=\${BACKUP_DIR%/}

# Copy backup to container
echo "Copying backup to MongoDB container..."
docker cp "\$BACKUP_DIR" dental-ai-mongodb:/tmp/backup

# Restore backup
echo "Restoring MongoDB backup..."
docker exec dental-ai-mongodb mongorestore --username=\$MONGO_USERNAME --password=\$MONGO_PASSWORD --authenticationDatabase=admin --drop /tmp/backup

# Clean up
echo "Cleaning up..."
docker exec dental-ai-mongodb rm -rf /tmp/backup
rm -rf "\$TEMP_DIR"

echo "Restore completed successfully."
EOL

# Create monitoring script
cat > "$DEPLOYMENT_DIR/scripts/monitor.sh" << EOL
#!/bin/bash

# Monitoring script for DentalAI Assistant
# Usage: ./monitor.sh

# Check Docker containers
echo "Checking Docker containers..."
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check disk space
echo "Checking disk space..."
df -h

# Check MongoDB status
echo "Checking MongoDB status..."
docker exec dental-ai-mongodb mongosh --username=\$MONGO_USERNAME --password=\$MONGO_PASSWORD --authenticationDatabase=admin --eval "db.serverStatus()"

# Check backend logs
echo "Checking backend logs (last 20 lines)..."
docker logs dental-ai-backend --tail 20

# Check frontend logs
echo "Checking frontend logs (last 20 lines)..."
docker logs dental-ai-frontend --tail 20
EOL

# Make scripts executable
chmod +x "$DEPLOYMENT_DIR/scripts/"*.sh

# Create a sample staging Docker Compose file
echo -e "${GREEN}Creating staging Docker Compose configuration...${NC}"
cat > "$DEPLOYMENT_DIR/docker-compose.staging.yml" << EOL
version: '3.8'

services:
  mongodb:
    image: mongo:5.0
    container_name: dental-ai-mongodb-staging
    restart: always
    volumes:
      - mongodb-data-staging:/data/db
      - ./configs/mongodb.conf:/etc/mongodb.conf
    ports:
      - "27018:27017"
    command: mongod --config /etc/mongodb.conf
    environment:
      - MONGO_INITDB_ROOT_USERNAME=\${MONGO_USERNAME}
      - MONGO_INITDB_ROOT_PASSWORD=\${MONGO_PASSWORD}
      - MONGO_INITDB_DATABASE=dental-ai-staging
    networks:
      - dental-ai-network-staging
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  backend:
    build:
      context: ../backend
      dockerfile: Dockerfile.prod
    container_name: dental-ai-backend-staging
    restart: always
    volumes:
      - ./logs:/app/logs
    ports:
      - "3001:3000"
    environment:
      - NODE_ENV=staging
      - PORT=3000
      - MONGODB_URI=mongodb://\${MONGO_USERNAME}:\${MONGO_PASSWORD}@mongodb-staging:27017/dental-ai-staging?authSource=admin
      - JWT_SECRET=\${JWT_SECRET}
      - JWT_EXPIRATION=\${JWT_EXPIRATION}
      - OPENAI_API_KEY=\${OPENAI_API_KEY}
      - ANTHROPIC_API_KEY=\${ANTHROPIC_API_KEY}
      - PRIMARY_AI_SERVICE=\${PRIMARY_AI_SERVICE}
    depends_on:
      - mongodb
    networks:
      - dental-ai-network-staging
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "5"

  frontend:
    build:
      context: ../frontend
      dockerfile: Dockerfile.prod
    container_name: dental-ai-frontend-staging
    restart: always
    ports:
      - "8080:80"
      - "8443:443"
    volumes:
      - ./configs/nginx.staging.conf:/etc/nginx/conf.d/default.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - backend
    networks:
      - dental-ai-network-staging
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

networks:
  dental-ai-network-staging:
    driver: bridge

volumes:
  mongodb-data-staging:
EOL

# Create Nginx staging configuration
echo -e "${GREEN}Creating Nginx staging configuration...${NC}"
cat > "$DEPLOYMENT_DIR/configs/nginx.staging.conf" << EOL
server {
    listen 80;
    server_name staging.*;
    
    # Redirect all HTTP requests to HTTPS
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name staging.*;
    
    # SSL configuration
    ssl_certificate /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Frontend static files
    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
        try_files \$uri \$uri/ /index.html;
        
        # Add staging environment banner
        add_header X-Environment "staging";
        sub_filter '<body>' '<body><div style="background-color: #ff9800; color: white; text-align: center; padding: 5px;">STAGING ENVIRONMENT</div>';
        sub_filter_once on;
    }
    
    # Backend API
    location /api {
        proxy_pass http://backend-staging:3000/api;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # WebSocket for real-time features
    location /socket.io {
        proxy_pass http://backend-staging:3000/socket.io;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

# Create deployment README file
echo -e "${GREEN}Creating deployment README...${NC}"
cat > "$DEPLOYMENT_DIR/README.md" << EOL
# DentalAI Assistant - Deployment

This directory contains the deployment configurations and scripts for the DentalAI Assistant application.

## Deployment Environments

- **Production**: Main production environment
- **Staging**: Staging environment for testing before production deployment

## Directory Structure

- \`configs/\`: Configuration files for services (Nginx, MongoDB)
- \`scripts/\`: Deployment, backup, and monitoring scripts
- \`ssl/\`: SSL certificates
- \`docker-compose.prod.yml\`: Production Docker Compose configuration
- \`docker-compose.staging.yml\`: Staging Docker Compose configuration
- \`.env.example\`: Example environment file for deployment

## Deployment Instructions

### Prerequisites

- Docker and Docker Compose
- Access to production server
- SSL certificates (for production)

### Setup

1. Copy the deployment directory to the server:
   \`\`\`
   scp -r deployment/ user@your-server:/path/to/deployment
   \`\`\`

2. Create a \`.env\` file based on \`.env.example\`:
   \`\`\`
   cp .env.example .env
   nano .env  # Edit with your actual values
   \`\`\`

3. For production, replace the self-signed SSL certificates in the \`ssl/\` directory with valid certificates from a trusted CA.

### Deployment

Run the deployment script:

\`\`\`
cd /path/to/deployment
./scripts/deploy.sh production  # For production environment
./scripts/deploy.sh staging     # For staging environment
\`\`\`

### Backup and Restore

To create a backup:

\`\`\`
./scripts/backup.sh [backup_name]
\`\`\`

To restore from a backup:

\`\`\`
./scripts/restore.sh <backup_file>
\`\`\`

### Monitoring

To monitor the application:

\`\`\`
./scripts/monitor.sh
\`\`\`

## Security Considerations

- Keep the \`.env\` file secure and never commit it to version control
- Regularly update SSL certificates before they expire
- Follow security best practices for Docker deployments
- Implement proper firewall rules to restrict access to the server
- Set up proper user management and permissions

## Scaling

For scaling the application:

1. Set up load balancing with multiple backend instances
2. Configure MongoDB replication for database redundancy
3. Use container orchestration like Kubernetes for advanced scaling needs
EOL

echo -e "${GREEN}"
echo "======================================================"
echo "    DentalAI Assistant Deployment Setup Complete      "
echo "======================================================"
echo -e "${NC}"
echo "Deployment configurations have been set up successfully."
echo -e "For production deployment, follow these steps:"
echo -e "1. Copy the deployment directory to your production server"
echo -e "2. Create a .env file based on .env.example"
echo -e "3. Replace self-signed SSL certificates with valid ones"
echo -e "4. Run the deployment script: ${YELLOW}./scripts/deploy.sh production${NC}"
