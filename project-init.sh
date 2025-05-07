#!/bin/bash

# Project initialization script for DentalAI Assistant
# This script orchestrates the complete project setup process

set -e  # Exit on any error

# Define color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Source URLs
REPO_URL="https://github.com/yourusername/dental-ai-assistant.git"
SCRIPTS_DIR="$(pwd)/scripts"

echo -e "${BLUE}"
echo "======================================================"
echo "      DentalAI Assistant Project Initialization       "
echo "======================================================"
echo -e "${NC}"

# Create project directory if it doesn't exist
PROJECT_DIR="$HOME/dental-ai-assistant"
mkdir -p "$PROJECT_DIR"

# Function to handle errors
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "${GREEN}Checking prerequisites...${NC}"

# Check Node.js
if ! command_exists node; then
    echo -e "${YELLOW}Node.js not found. Please install Node.js v14+ before proceeding.${NC}"
    exit 1
fi

NODE_VERSION=$(node -v | cut -d 'v' -f 2)
NODE_MAJOR_VERSION=$(echo $NODE_VERSION | cut -d '.' -f 1)
if [ "$NODE_MAJOR_VERSION" -lt 14 ]; then
    echo -e "${YELLOW}Node.js version $NODE_VERSION is too old. Please install Node.js v14+ before proceeding.${NC}"
    exit 1
fi

# Check npm
if ! command_exists npm; then
    echo -e "${YELLOW}npm not found. Please install npm before proceeding.${NC}"
    exit 1
fi

# Check MongoDB
if ! command_exists mongod; then
    echo -e "${YELLOW}MongoDB not found. Please install MongoDB v5.0+ before proceeding.${NC}"
    exit 1
fi

# Check Git
if ! command_exists git; then
    echo -e "${YELLOW}Git not found. Please install Git before proceeding.${NC}"
    exit 1
fi

# Create project structure
echo -e "${GREEN}Creating project structure...${NC}"

# Create the scripts directory
mkdir -p "$SCRIPTS_DIR"

# Copy all setup scripts to the project
cp environment-setup.sh "$SCRIPTS_DIR"
cp backend-setup.sh "$SCRIPTS_DIR"
cp frontend-setup.sh "$SCRIPTS_DIR"
cp ai-services-setup.sh "$SCRIPTS_DIR"
cp database-setup.sh "$SCRIPTS_DIR"
cp dev-tools-setup.sh "$SCRIPTS_DIR"
cp deployment-setup.sh "$SCRIPTS_DIR"
cp documentation-setup.sh "$SCRIPTS_DIR"
cp testing-setup.sh "$SCRIPTS_DIR"
cp main-setup.sh "$SCRIPTS_DIR"

# Make scripts executable
chmod +x "$SCRIPTS_DIR"/*.sh

# Navigate to project directory
cd "$PROJECT_DIR"

# Initialize Git repository
echo -e "${GREEN}Initializing Git repository...${NC}"
if [ ! -d ".git" ]; then
    git init
    echo -e "${GREEN}Git repository initialized.${NC}"
else
    echo -e "${YELLOW}Git repository already exists. Skipping initialization.${NC}"
fi

# Create initial project structure
mkdir -p backend
mkdir -p frontend
mkdir -p docs
mkdir -p database
mkdir -p deployment
mkdir -p tests

# Create basic README.md
echo -e "${GREEN}Creating README.md...${NC}"
cat > README.md << EOL
# DentalAI Assistant

An AI-powered dental scribe and clinical decision support system.

## Overview

DentalAI Assistant is a comprehensive solution for dental practices that leverages artificial intelligence to streamline clinical documentation and enhance patient care. The system provides real-time transcription of patient-dentist conversations, automatic generation of clinical notes, and intelligent decision support for diagnosis and treatment planning.

## Features

- **Real-time Speech-to-Text Transcription**: Captures dental appointments with high accuracy.
- **AI-Generated Clinical Notes**: Converts conversations into structured SOAP notes.
- **Clinical Decision Support**: Provides differential diagnoses and treatment recommendations.
- **Patient Management**: Complete patient record management system.
- **EHR Integration**: Seamlessly integrates with dental practice management systems.
- **Dental-Specific AI**: Optimized for dental terminology and workflows.

## Getting Started

### Prerequisites

- Node.js (v14+)
- MongoDB (v5.0+)
- npm or yarn
- Docker (optional)

### Installation

Run the setup script:

\`\`\`
bash scripts/main-setup.sh
\`\`\`

This will set up the development environment, backend, frontend, database, and all necessary configurations.

### Development

Start the backend development server:

\`\`\`
cd backend
npm run dev
\`\`\`

Start the frontend development server:

\`\`\`
cd frontend
npm start
\`\`\`

## Documentation

Documentation is available in the \`docs/\` directory.

## Testing

Run tests:

\`\`\`
npm test
\`\`\`

## Deployment

See the deployment instructions in the \`deployment/\` directory.

## License

This project is proprietary and confidential.
EOL

# Create .env file template
echo -e "${GREEN}Creating .env file template...${NC}"
cat > .env.example << EOL
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

# Create actual .env file
cp .env.example .env

# Create .gitignore
echo -e "${GREEN}Creating .gitignore...${NC}"
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

# Temporary files
.tmp/
temp/
EOL

# Create package.json
echo -e "${GREEN}Creating package.json...${NC}"
cat > package.json << EOL
{
  "name": "dental-ai-assistant",
  "version": "0.1.0",
  "private": true,
  "workspaces": [
    "backend",
    "frontend"
  ],
  "scripts": {
    "start:backend": "cd backend && npm start",
    "start:frontend": "cd frontend && npm start",
    "start:dev": "concurrently \"npm run start:backend\" \"npm run start:frontend\"",
    "lint:backend": "cd backend && npm run lint",
    "lint:frontend": "cd frontend && npm run lint",
    "lint": "npm run lint:backend && npm run lint:frontend",
    "test:backend": "cd backend && npm test",
    "test:frontend": "cd frontend && npm test",
    "test": "npm run test:backend && npm run test:frontend",
    "test:e2e": "cypress run",
    "build:backend": "cd backend && npm run build",
    "build:frontend": "cd frontend && npm run build",
    "build": "npm run build:backend && npm run build:frontend",
    "clean": "rm -rf node_modules && rm -rf backend/node_modules && rm -rf frontend/node_modules"
  },
  "devDependencies": {
    "concurrently": "^7.2.1"
  }
}
EOL

# Create LICENSE file
echo -e "${GREEN}Creating LICENSE file...${NC}"
cat > LICENSE << EOL
Proprietary and Confidential

Copyright (c) $(date +"%Y") DentalAI Assistant

All rights reserved.

This software and associated documentation files (the "Software") are the
proprietary information of DentalAI Assistant. The Software is protected by
copyright law and international treaties.

Unauthorized reproduction, distribution, or modification of the Software,
or any portion of it, may result in severe civil and criminal penalties, and
will be prosecuted to the maximum extent possible under the law.

The Software is provided "as is" without warranty of any kind, either express
or implied, including but not limited to the warranties of merchantability,
fitness for a particular purpose, or non-infringement.
EOL

# Run the main setup script to set up all components
echo -e "${GREEN}Running main setup script...${NC}"
"$SCRIPTS_DIR/main-setup.sh"

# Initialize a git repository and make initial commit
echo -e "${GREEN}Making initial git commit...${NC}"
git add .
git commit -m "Initial project setup"

echo -e "${GREEN}"
echo "======================================================"
echo "       DentalAI Assistant Setup Complete!             "
echo "======================================================"
echo -e "${NC}"
echo "The DentalAI Assistant project has been successfully initialized."
echo ""
echo -e "Next steps:"
echo -e "1. ${YELLOW}cd $PROJECT_DIR${NC}"
echo -e "2. Start the backend: ${YELLOW}cd backend && npm run dev${NC}"
echo -e "3. Start the frontend: ${YELLOW}cd frontend && npm start${NC}"
echo ""
echo -e "Access the application at: ${BLUE}http://localhost:3001${NC}"
echo -e "API documentation at: ${BLUE}http://localhost:3000/api-docs${NC}"
echo ""
echo -e "Default development credentials:"
echo -e "- Admin: ${YELLOW}admin@dentalai.com / admin123${NC}"
echo -e "- Dentist: ${YELLOW}dentist@dentalai.com / dentist123${NC}"
echo -e "- Assistant: ${YELLOW}assistant@dentalai.com / assistant123${NC}"
echo ""
echo -e "${RED}IMPORTANT: Update API keys and secrets in .env for production use!${NC}"
echo ""
echo -e "Happy coding! 🚀"
