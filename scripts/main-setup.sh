#!/bin/bash

# Main setup script for DentalAI Assistant project
# This script orchestrates the entire setup process

set -e  # Exit on any error

# Define color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project configuration
PROJECT_NAME="dental-ai-assistant"
PROJECT_DIR="$HOME/$PROJECT_NAME"
SCRIPTS_DIR="$PROJECT_DIR/scripts"
LOG_DIR="$PROJECT_DIR/logs"
ENV_FILE="$PROJECT_DIR/.env"

# Print banner
echo -e "${BLUE}"
echo "======================================================"
echo "          DentalAI Assistant Setup Script             "
echo "======================================================"
echo -e "${NC}"

# Create directories
echo -e "${GREEN}Creating project directories...${NC}"
mkdir -p "$PROJECT_DIR"
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$PROJECT_DIR/backend"
mkdir -p "$PROJECT_DIR/frontend"
mkdir -p "$PROJECT_DIR/docs"
mkdir -p "$PROJECT_DIR/config"

# Copy all setup scripts to the scripts directory
echo -e "${GREEN}Copying setup scripts...${NC}"
cp ./environment-setup.sh "$SCRIPTS_DIR"
cp ./backend-setup.sh "$SCRIPTS_DIR"
cp ./frontend-setup.sh "$SCRIPTS_DIR"
cp ./ai-services-setup.sh "$SCRIPTS_DIR"
cp ./database-setup.sh "$SCRIPTS_DIR"
cp ./dev-tools-setup.sh "$SCRIPTS_DIR"
cp ./deployment-setup.sh "$SCRIPTS_DIR"

# Make all scripts executable
chmod +x "$SCRIPTS_DIR"/*.sh

# Create .env file template
echo -e "${GREEN}Creating environment file template...${NC}"
cat > "$ENV_FILE" << EOL
# DentalAI Assistant Environment Variables

# Project configuration
PROJECT_NAME=dental-ai-assistant
NODE_ENV=development

# API Keys (IMPORTANT: Replace these with your actual keys)
OPENAI_API_KEY=your_openai_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# Database configuration
MONGODB_URI=mongodb://localhost:27017/dental-ai
MONGODB_USER=
MONGODB_PASSWORD=

# Server configuration
PORT=3000
FRONTEND_PORT=3001
API_URL=http://localhost:3000/api

# Security
JWT_SECRET=change_this_to_a_secure_random_string
JWT_EXPIRATION=24h
COOKIE_SECRET=change_this_to_another_secure_random_string

# Feature flags
ENABLE_SPEECH_RECOGNITION=true
ENABLE_NOTE_GENERATION=true
ENABLE_DECISION_SUPPORT=true
EOL

echo -e "${YELLOW}Please update the .env file with your actual API keys and secrets before proceeding.${NC}"

# Run the environment setup script
echo -e "${GREEN}Setting up development environment...${NC}"
"$SCRIPTS_DIR/environment-setup.sh" 2>&1 | tee "$LOG_DIR/environment-setup.log"

# Ask user if they want to continue with full setup
read -p "Continue with full setup? (y/n): " CONTINUE
if [ "$CONTINUE" != "y" ]; then
    echo -e "${YELLOW}Setup paused. You can continue later by running the individual scripts in the scripts directory.${NC}"
    exit 0
fi

# Run the backend setup script
echo -e "${GREEN}Setting up backend...${NC}"
"$SCRIPTS_DIR/backend-setup.sh" 2>&1 | tee "$LOG_DIR/backend-setup.log"

# Run the database setup script
echo -e "${GREEN}Setting up database...${NC}"
"$SCRIPTS_DIR/database-setup.sh" 2>&1 | tee "$LOG_DIR/database-setup.log"

# Run the AI services setup script
echo -e "${GREEN}Setting up AI services...${NC}"
"$SCRIPTS_DIR/ai-services-setup.sh" 2>&1 | tee "$LOG_DIR/ai-services-setup.log"

# Run the frontend setup script
echo -e "${GREEN}Setting up frontend...${NC}"
"$SCRIPTS_DIR/frontend-setup.sh" 2>&1 | tee "$LOG_DIR/frontend-setup.log"

# Run the dev tools setup script
echo -e "${GREEN}Setting up development tools...${NC}"
"$SCRIPTS_DIR/dev-tools-setup.sh" 2>&1 | tee "$LOG_DIR/dev-tools-setup.log"

# Run the deployment setup script
echo -e "${GREEN}Setting up deployment configuration...${NC}"
"$SCRIPTS_DIR/deployment-setup.sh" 2>&1 | tee "$LOG_DIR/deployment-setup.log"

# Setup git repository
echo -e "${GREEN}Initializing git repository...${NC}"
cd "$PROJECT_DIR"
git init
cat > .gitignore << EOL
# Node
node_modules/
npm-debug.log
yarn-error.log
.pnpm-debug.log

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Build files
/dist
/build
/out

# IDE
.idea/
.vscode/
*.sublime-project
*.sublime-workspace

# Logs
logs/
*.log

# OS
.DS_Store
Thumbs.db

# Testing
/coverage

# Database dumps
*.dump
EOL

git add .
git commit -m "Initial project setup"

echo -e "${GREEN}"
echo "======================================================"
echo "          DentalAI Assistant Setup Complete           "
echo "======================================================"
echo -e "${NC}"
echo -e "Project has been initialized at: ${BLUE}$PROJECT_DIR${NC}"
echo -e "To start the backend: ${YELLOW}cd $PROJECT_DIR/backend && npm start${NC}"
echo -e "To start the frontend: ${YELLOW}cd $PROJECT_DIR/frontend && npm start${NC}"
echo -e "To view logs: ${YELLOW}cd $PROJECT_DIR/logs${NC}"
echo -e "${GREEN}Happy coding!${NC}"
