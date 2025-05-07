#!/bin/bash

# Development tools setup script for DentalAI Assistant
# Sets up linting, testing, and CI/CD configurations

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

echo -e "${BLUE}"
echo "======================================================"
echo "      DentalAI Assistant Development Tools Setup      "
echo "======================================================"
echo -e "${NC}"

# Navigate to project directory
cd "$PROJECT_DIR"

# Create .gitignore file for the whole project
echo -e "${GREEN}Creating .gitignore file...${NC}"
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
build/
dist/
out/
coverage/

# Logs
logs/
*.log

# OS
.DS_Store
Thumbs.db

# IDE
.idea/
.vscode/
*.sublime-project
*.sublime-workspace

# MongoDB
database/backup/*
!database/backup/.gitkeep

# Temporary files
.tmp/
temp/
EOL

# Set up ESLint for backend
echo -e "${GREEN}Setting up ESLint for backend...${NC}"
cd "$BACKEND_DIR"

# Create ESLint configuration
cat > .eslintrc.json << EOL
{
  "env": {
    "node": true,
    "es2021": true,
    "jest": true
  },
  "extends": [
    "eslint:recommended"
  ],
  "parserOptions": {
    "ecmaVersion": 12,
    "sourceType": "module"
  },
  "rules": {
    "indent": ["error", 2],
    "linebreak-style": ["error", "unix"],
    "quotes": ["error", "single"],
    "semi": ["error", "always"],
    "no-unused-vars": ["warn", { "argsIgnorePattern": "^_" }],
    "no-console": ["warn", { "allow": ["warn", "error", "info"] }]
  }
}
EOL

# Create Prettier configuration
cat > .prettierrc << EOL
{
  "semi": true,
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2,
  "trailingComma": "es5"
}
EOL

# Create Jest configuration
cat > jest.config.js << EOL
module.exports = {
  testEnvironment: 'node',
  coverageDirectory: 'coverage',
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/server.js',
    '!**/node_modules/**'
  ],
  testPathIgnorePatterns: [
    '/node_modules/'
  ],
  testTimeout: 10000
};
EOL

# Set up Jest testing
mkdir -p tests/unit
mkdir -p tests/integration

# Create sample test
cat > tests/unit/sample.test.js << EOL
/**
 * Sample unit test
 */

describe('Sample Test', () => {
  it('should pass', () => {
    expect(1 + 1).toBe(2);
  });
});
EOL

# Add test scripts to package.json
if ! grep -q "\"test:unit\":" package.json; then
  # Using perl for in-place editing which works on both Linux and macOS
  perl -i -pe 's/"test": "jest"/"test": "jest",\n    "test:unit": "jest tests\\/unit",\n    "test:integration": "jest tests\\/integration",\n    "test:coverage": "jest --coverage"/' package.json
fi

# Setup ESLint for frontend
echo -e "${GREEN}Setting up ESLint for frontend...${NC}"
cd "$FRONTEND_DIR"

# Create ESLint configuration
cat > .eslintrc.json << EOL
{
  "env": {
    "browser": true,
    "es2021": true,
    "jest": true
  },
  "extends": [
    "eslint:recommended",
    "plugin:react/recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:prettier/recommended"
  ],
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "ecmaFeatures": {
      "jsx": true
    },
    "ecmaVersion": 12,
    "sourceType": "module"
  },
  "plugins": [
    "react",
    "@typescript-eslint",
    "prettier"
  ],
  "rules": {
    "prettier/prettier": "error",
    "react/react-in-jsx-scope": "off",
    "react/prop-types": "off",
    "@typescript-eslint/explicit-module-boundary-types": "off",
    "@typescript-eslint/no-explicit-any": "warn"
  },
  "settings": {
    "react": {
      "version": "detect"
    }
  }
}
EOL

# Create Prettier configuration
cat > .prettierrc << EOL
{
  "semi": true,
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2,
  "trailingComma": "es5",
  "jsxBracketSameLine": false
}
EOL

# Create sample test
mkdir -p src/__tests__
cat > src/__tests__/sample.test.tsx << EOL
import { render, screen } from '@testing-library/react';

describe('Sample Test', () => {
  it('should pass', () => {
    expect(1 + 1).toBe(2);
  });
});
EOL

# Set up Husky for git hooks
echo -e "${GREEN}Setting up Husky for git hooks...${NC}"
cd "$PROJECT_DIR"

# Create package.json for the root directory if it doesn't exist
if [ ! -f "package.json" ]; then
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
    "prepare": "husky install"
  },
  "devDependencies": {
    "concurrently": "^7.2.1",
    "husky": "^8.0.1",
    "lint-staged": "^13.0.1"
  },
  "lint-staged": {
    "backend/**/*.js": [
      "eslint --fix",
      "prettier --write"
    ],
    "frontend/**/*.{ts,tsx}": [
      "eslint --fix",
      "prettier --write"
    ]
  }
}
EOL
fi

# Install root dev dependencies
npm install --save-dev concurrently husky lint-staged

# Initialize Husky
npx husky install

# Create pre-commit hook
npx husky add .husky/pre-commit "npx lint-staged"

# Create Docker configuration
echo -e "${GREEN}Setting up Docker configuration...${NC}"

# Create Docker Compose file
cat > docker-compose.yml << EOL
version: '3.8'

services:
  mongodb:
    image: mongo:5.0
    container_name: dental-ai-mongodb
    volumes:
      - mongodb-data:/data/db
    ports:
      - "27017:27017"
    environment:
      - MONGO_INITDB_DATABASE=dental-ai
    networks:
      - dental-ai-network

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: dental-ai-backend
    volumes:
      - ./backend:/app
      - /app/node_modules
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - MONGODB_URI=mongodb://mongodb:27017/dental-ai
      - JWT_SECRET=change_this_to_a_secure_random_string
      - JWT_EXPIRATION=24h
    depends_on:
      - mongodb
    networks:
      - dental-ai-network

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: dental-ai-frontend
    volumes:
      - ./frontend:/app
      - /app/node_modules
    ports:
      - "3001:3001"
    environment:
      - REACT_APP_API_URL=http://localhost:3000/api
      - REACT_APP_SOCKET_URL=http://localhost:3000
    depends_on:
      - backend
    networks:
      - dental-ai-network

networks:
  dental-ai-network:
    driver: bridge

volumes:
  mongodb-data:
EOL

# Create Backend Dockerfile
cat > "$BACKEND_DIR/Dockerfile" << EOL
FROM node:16-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "run", "dev"]
EOL

# Create Frontend Dockerfile
cat > "$FRONTEND_DIR/Dockerfile" << EOL
FROM node:16-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3001

CMD ["npm", "start"]
EOL

# Create GitHub Actions workflow
echo -e "${GREEN}Setting up GitHub Actions workflow...${NC}"
mkdir -p .github/workflows

cat > .github/workflows/ci.yml << EOL
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Use Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '16'
          cache: 'npm'
      - name: Install dependencies
        run: npm ci
      - name: Lint
        run: npm run lint

  test:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v2
      - name: Use Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '16'
          cache: 'npm'
      - name: Install dependencies
        run: npm ci
      - name: Test
        run: npm test

  build:
    runs-on: ubuntu-latest
    needs: test
    if: github.event_name == 'push' && (github.ref == 'refs/heads/main' || github.ref == 'refs/heads/develop')
    steps:
      - uses: actions/checkout@v2
      - name: Use Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '16'
          cache: 'npm'
      - name: Install dependencies
        run: npm ci
      - name: Build backend
        run: cd backend && npm run build
      - name: Build frontend
        run: cd frontend && npm run build
      - name: Upload backend build
        uses: actions/upload-artifact@v2
        with:
          name: backend-build
          path: backend/dist
      - name: Upload frontend build
        uses: actions/upload-artifact@v2
        with:
          name: frontend-build
          path: frontend/build
EOL

# Create VSCode settings
echo -e "${GREEN}Setting up VSCode settings...${NC}"
mkdir -p .vscode

cat > .vscode/settings.json << EOL
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "eslint.validate": [
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact"
  ],
  "files.exclude": {
    "**/.git": true,
    "**/.DS_Store": true,
    "**/node_modules": true,
    "**/build": true,
    "**/dist": true,
    "**/coverage": true
  },
  "javascript.updateImportsOnFileMove.enabled": "always",
  "typescript.updateImportsOnFileMove.enabled": "always",
  "typescript.tsdk": "node_modules/typescript/lib"
}
EOL

# Create launch.json for debugging
cat > .vscode/launch.json << EOL
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Debug Backend",
      "skipFiles": ["<node_internals>/**"],
      "program": "\${workspaceFolder}/backend/src/server.js",
      "envFile": "\${workspaceFolder}/backend/.env",
      "console": "integratedTerminal"
    },
    {
      "name": "Debug Frontend",
      "type": "chrome",
      "request": "launch",
      "url": "http://localhost:3001",
      "webRoot": "\${workspaceFolder}/frontend/src",
      "sourceMapPathOverrides": {
        "webpack:///src/*": "\${webRoot}/*"
      }
    }
  ],
  "compounds": [
    {
      "name": "Debug Full Stack",
      "configurations": ["Debug Backend", "Debug Frontend"]
    }
  ]
}
EOL

# Create README for the project
echo -e "${GREEN}Creating main README...${NC}"
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

## Technology Stack

- **Backend**: Node.js, Express, Socket.io
- **Frontend**: React, TypeScript, Material-UI
- **Database**: MongoDB
- **AI Services**: OpenAI GPT-4, Whisper, Claude
- **DevOps**: Docker, GitHub Actions

## Getting Started

### Prerequisites

- Node.js (v14+)
- MongoDB (v5.0+)
- npm or yarn
- Docker (optional)

### Installation

1. Clone the repository:
   \`\`\`
   git clone https://github.com/yourusername/dental-ai-assistant.git
   cd dental-ai-assistant
   \`\`\`

2. Run the setup script:
   \`\`\`
   bash main-setup.sh
   \`\`\`

3. Start the development servers:
   \`\`\`
   npm run start:dev
   \`\`\`

### Using Docker

Alternatively, you can use Docker Compose:

\`\`\`
docker-compose up
\`\`\`

## Project Structure

- \`/backend\`: Node.js backend server
- \`/frontend\`: React frontend application
- \`/database\`: Database setup and scripts
- \`/docs\`: Documentation files

## Development

### Running Tests

\`\`\`
npm test
\`\`\`

### Linting

\`\`\`
npm run lint
\`\`\`

## License

This project is proprietary and confidential.

## Acknowledgements

- OpenAI for GPT-4 and Whisper APIs
- Anthropic for Claude API
EOL

echo -e "${GREEN}"
echo "======================================================"
echo "   DentalAI Assistant Development Tools Setup Complete  "
echo "======================================================"
echo -e "${NC}"
echo "Development tools have been set up successfully."
echo -e "You can use the following commands:"
echo -e "${YELLOW}npm run lint${NC} - Run linting for both backend and frontend"
echo -e "${YELLOW}npm test${NC} - Run tests for both backend and frontend"
echo -e "${YELLOW}npm run start:dev${NC} - Start both backend and frontend servers"
echo -e "${YELLOW}docker-compose up${NC} - Start the application using Docker"
