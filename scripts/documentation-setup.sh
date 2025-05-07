#!/bin/bash

# Documentation setup script for DentalAI Assistant
# Generates project documentation using JSDoc and Markdown

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
DOCS_DIR="$PROJECT_DIR/docs"

echo -e "${BLUE}"
echo "======================================================"
echo "      DentalAI Assistant Documentation Setup          "
echo "======================================================"
echo -e "${NC}"

# Create documentation directory structure
mkdir -p "$DOCS_DIR"
mkdir -p "$DOCS_DIR/api"
mkdir -p "$DOCS_DIR/user-guide"
mkdir -p "$DOCS_DIR/developer-guide"
mkdir -p "$DOCS_DIR/architecture"
mkdir -p "$DOCS_DIR/screenshots"
mkdir -p "$DOCS_DIR/assets"

# Install documentation tools
echo -e "${GREEN}Installing documentation tools...${NC}"
cd "$PROJECT_DIR"
npm install --save-dev jsdoc docdash markdownlint-cli swagger-jsdoc swagger-ui-express typedoc

# Create JSDoc configuration
echo -e "${GREEN}Creating JSDoc configuration...${NC}"
cat > "$BACKEND_DIR/jsdoc.json" << EOL
{
  "tags": {
    "allowUnknownTags": true,
    "dictionaries": ["jsdoc", "closure"]
  },
  "source": {
    "include": ["src"],
    "includePattern": ".+\\.js(doc|x)?$",
    "excludePattern": "(^|\\/|\\\\)_"
  },
  "plugins": [
    "plugins/markdown",
    "node_modules/jsdoc-http-plugin"
  ],
  "templates": {
    "cleverLinks": false,
    "monospaceLinks": false,
    "default": {
      "outputSourceFiles": true,
      "includeDate": true
    }
  },
  "opts": {
    "destination": "../docs/api/backend",
    "recurse": true,
    "readme": "README.md",
    "template": "node_modules/docdash"
  }
}
EOL

# Create TypeDoc configuration for frontend
echo -e "${GREEN}Creating TypeDoc configuration...${NC}"
cat > "$FRONTEND_DIR/typedoc.json" << EOL
{
  "entryPoints": ["src"],
  "entryPointStrategy": "expand",
  "out": "../docs/api/frontend",
  "excludePrivate": true,
  "excludeProtected": true,
  "excludeExternals": true,
  "hideGenerator": true,
  "readme": "README.md",
  "name": "DentalAI Assistant Frontend Documentation",
  "includeVersion": true,
  "categorizeByGroup": true,
  "searchInComments": true,
  "defaultCategory": "Components"
}
EOL

# Create Swagger configuration for API documentation
echo -e "${GREEN}Creating Swagger configuration...${NC}"
cat > "$BACKEND_DIR/src/config/swagger.js" << EOL
const swaggerJsDoc = require('swagger-jsdoc');

const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'DentalAI Assistant API',
      version: '1.0.0',
      description: 'API documentation for DentalAI Assistant',
      license: {
        name: 'Private',
        url: 'https://example.com/license'
      },
      contact: {
        name: 'API Support',
        url: 'https://dental-ai-assistant.com/support',
        email: 'support@dental-ai-assistant.com'
      }
    },
    servers: [
      {
        url: 'http://localhost:3000/api',
        description: 'Development server'
      },
      {
        url: 'https://dental-ai-assistant.com/api',
        description: 'Production server'
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT'
        }
      }
    },
    security: [
      {
        bearerAuth: []
      }
    ]
  },
  apis: ['./src/routes/*.js', './src/models/*.js']
};

const swaggerDocs = swaggerJsDoc(swaggerOptions);

module.exports = swaggerDocs;
EOL

# Update backend server.js to include Swagger UI
echo -e "${GREEN}Updating server.js to include Swagger UI...${NC}"
cat >> "$BACKEND_DIR/src/server.js" << EOL

// Swagger Documentation
const swaggerUi = require('swagger-ui-express');
const swaggerDocs = require('./config/swagger');

// Swagger UI route
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocs));
EOL

# Create documentation generator script
echo -e "${GREEN}Creating documentation generator script...${NC}"
cat > "$DOCS_DIR/generate-docs.sh" << EOL
#!/bin/bash

# Documentation generator script
# This script generates API documentation and builds the static docs site

echo "Generating backend API documentation with JSDoc..."
cd ../backend
npx jsdoc -c jsdoc.json

echo "Generating frontend documentation with TypeDoc..."
cd ../frontend
npx typedoc --options typedoc.json

echo "Generating Swagger API documentation..."
echo "Swagger documentation is available at http://localhost:3000/api-docs when the server is running."

echo "Running Markdown linting..."
cd ..
npx markdownlint "**/*.md" --ignore node_modules

echo "Documentation generation complete."
echo "Backend API documentation: docs/api/backend/index.html"
echo "Frontend documentation: docs/api/frontend/index.html"
echo "Swagger API documentation: http://localhost:3000/api-docs (when server is running)"
EOL

# Make the script executable
chmod +x "$DOCS_DIR/generate-docs.sh"

# Create main documentation index file
echo -e "${GREEN}Creating main documentation index...${NC}"
cat > "$DOCS_DIR/index.md" << EOL
# DentalAI Assistant Documentation

Welcome to the DentalAI Assistant documentation. This guide provides comprehensive information about the DentalAI Assistant application, its features, architecture, and how to use and extend it.

## Documentation Sections

- [User Guide](user-guide/index.md) - Guides for end users
- [Developer Guide](developer-guide/index.md) - Documentation for developers
- [API Documentation](api/index.md) - API reference documentation
- [Architecture](architecture/index.md) - System architecture documentation

## Quick Links

- [Installation Guide](developer-guide/installation.md)
- [Getting Started](user-guide/getting-started.md)
- [Feature Overview](user-guide/features.md)
- [API Reference](api/index.md)
- [Troubleshooting](user-guide/troubleshooting.md)

## About DentalAI Assistant

DentalAI Assistant is an AI-powered dental scribe and clinical decision support system designed to streamline clinical documentation and enhance patient care in dental practices. The system provides real-time transcription of patient-dentist conversations, automatic generation of clinical notes, and intelligent decision support for diagnosis and treatment planning.
EOL

# Create User Guide index
echo -e "${GREEN}Creating User Guide...${NC}"
mkdir -p "$DOCS_DIR/user-guide"
cat > "$DOCS_DIR/user-guide/index.md" << EOL
# DentalAI Assistant User Guide

This user guide provides detailed instructions on how to use the DentalAI Assistant application effectively.

## Contents

- [Getting Started](getting-started.md)
- [Dashboard Overview](dashboard.md)
- [Patient Management](patients.md)
- [Transcription](transcription.md)
- [Clinical Notes](notes.md)
- [Decision Support](decision-support.md)
- [Settings and Configuration](settings.md)
- [Troubleshooting](troubleshooting.md)

## Getting Started

To get started with DentalAI Assistant, see the [Getting Started](getting-started.md) guide.
EOL

# Create Getting Started guide
cat > "$DOCS_DIR/user-guide/getting-started.md" << EOL
# Getting Started with DentalAI Assistant

This guide will help you get started with DentalAI Assistant and understand its basic features.

## First-time Setup

1. **Login**: Access the DentalAI Assistant application using your provided credentials.
2. **Profile Setup**: Complete your profile by adding your professional information.
3. **Practice Configuration**: Configure your practice settings, including working hours and appointment types.

## Basic Navigation

The DentalAI Assistant has a user-friendly interface with the following main sections:

- **Dashboard**: Overview of your schedule, recent patients, and pending tasks.
- **Patients**: Patient management, records, and history.
- **Transcription**: Real-time transcription tool for patient appointments.
- **Notes**: Access and manage clinical notes.
- **Decision Support**: AI-powered diagnostic and treatment recommendations.
- **Settings**: Application and user settings.

## Your First Appointment

1. **Patient Selection**: Select an existing patient or add a new one.
2. **Start Transcription**: Click "Start Transcription" to begin recording the appointment.
3. **Review Notes**: After the appointment, review the AI-generated notes.
4. **Edit if Necessary**: Make any needed adjustments to the notes.
5. **Finalize**: Finalize the notes when ready.

## Next Steps

Once you're familiar with the basic workflow, explore the more advanced features:

- [Patient Management](patients.md)
- [Transcription Features](transcription.md)
- [Clinical Notes Management](notes.md)
- [Decision Support Tools](decision-support.md)
EOL

# Create Developer Guide index
echo -e "${GREEN}Creating Developer Guide...${NC}"
mkdir -p "$DOCS_DIR/developer-guide"
cat > "$DOCS_DIR/developer-guide/index.md" << EOL
# DentalAI Assistant Developer Guide

This developer guide provides information on developing, extending, and maintaining the DentalAI Assistant application.

## Contents

- [Installation](installation.md)
- [Project Structure](project-structure.md)
- [Backend Development](backend-development.md)
- [Frontend Development](frontend-development.md)
- [AI Service Integration](ai-service-integration.md)
- [API Documentation](../api/index.md)
- [Testing](testing.md)
- [Deployment](deployment.md)
- [Contributing Guidelines](contributing.md)

## Quick Start

To set up the development environment, see the [Installation](installation.md) guide.
EOL

# Create Installation guide
cat > "$DOCS_DIR/developer-guide/installation.md" << EOL
# Installation Guide

This guide provides instructions for setting up the DentalAI Assistant development environment.

## Prerequisites

- Node.js (v14+)
- MongoDB (v5.0+)
- npm or yarn
- Git

## Clone the Repository

```bash
git clone https://github.com/yourusername/dental-ai-assistant.git
cd dental-ai-assistant
```

## Setup Script

The easiest way to set up the development environment is to use the provided setup script:

```bash
bash main-setup.sh
```

This script will:
- Install necessary dependencies
- Set up the project directory structure
- Configure the backend and frontend applications
- Set up the database
- Configure development tools

## Manual Setup

If you prefer to set up manually or if the setup script fails, follow these steps:

### 1. Environment Setup

```bash
# Install global dependencies
npm install -g nodemon typescript ts-node
```

### 2. Backend Setup

```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your configuration
```

### 3. Frontend Setup

```bash
cd ../frontend
npm install
cp .env.example .env
# Edit .env with your configuration
```

### 4. Database Setup

```bash
# Start MongoDB
mongod --dbpath=/path/to/data/directory
# In another terminal
mongosh
# Inside MongoDB shell
use dental-ai
```

### 5. Start the Application

```bash
# In the backend directory
npm run dev

# In the frontend directory (in another terminal)
npm start
```

## AI Service Configuration

To use the AI features, you need to set up API keys for OpenAI and/or Anthropic:

1. Get API keys from [OpenAI](https://platform.openai.com/) and [Anthropic](https://console.anthropic.com/)
2. Add the API keys to your `.env` file:
   ```
   OPENAI_API_KEY=your_openai_api_key_here
   ANTHROPIC_API_KEY=your_anthropic_api_key_here
   ```

## Troubleshooting

If you encounter issues during installation, check these common problems:

- **MongoDB Connection Error**: Ensure MongoDB is running and accessible
- **Node Version Mismatch**: Ensure you're using Node.js v14 or higher
- **Port Conflicts**: Check if ports 3000 (backend) and 3001 (frontend) are available

For more detailed troubleshooting, see the [Troubleshooting](troubleshooting.md) page.
EOL

# Create Project Structure guide
cat > "$DOCS_DIR/developer-guide/project-structure.md" << EOL
# Project Structure

This document outlines the structure of the DentalAI Assistant codebase.

## Root Directory

- **backend/**: Node.js backend server
- **frontend/**: React frontend application
- **docs/**: Documentation
- **database/**: Database setup and scripts
- **deployment/**: Deployment configurations and scripts

## Backend Structure

```
backend/
├── src/                # Source code
│   ├── ai/             # AI service integrations
│   ├── config/         # Configuration files
│   ├── controllers/    # Request handlers
│   ├── middleware/     # Express middleware
│   ├── models/         # MongoDB models
│   ├── routes/         # API routes
│   ├── services/       # Business logic
│   ├── utils/          # Utility functions
│   └── server.js       # Entry point
├── tests/              # Test files
│   ├── integration/    # Integration tests
│   └── unit/           # Unit tests
├── .env                # Environment variables
└── package.json        # Dependencies and scripts
```

## Frontend Structure

```
frontend/
├── public/             # Static files
├── src/                # Source code
│   ├── assets/         # Images, fonts, etc.
│   ├── components/     # React components
│   │   ├── common/     # Shared components
│   │   ├── auth/       # Authentication components
│   │   ├── dashboard/  # Dashboard components
│   │   └── ...         # Feature-specific components
│   ├── contexts/       # React contexts
│   ├── hooks/          # Custom React hooks
│   ├── pages/          # Page components
│   ├── services/       # API service functions
│   ├── types/          # TypeScript type definitions
│   ├── utils/          # Utility functions
│   ├── App.tsx         # Main App component
│   └── index.tsx       # Entry point
├── .env                # Environment variables
└── package.json        # Dependencies and scripts
```

## Database Structure

```
database/
├── scripts/            # Database scripts
│   ├── init.js         # Initialization script
│   ├── seed.js         # Seed data script
│   ├── backup.sh       # Backup script
│   └── restore.sh      # Restore script
└── backup/             # Backup files
```

## Deployment Structure

```
deployment/
├── configs/            # Configuration files
│   ├── nginx.conf      # Nginx configuration
│   └── mongodb.conf    # MongoDB configuration
├── scripts/            # Deployment scripts
│   ├── deploy.sh       # Deployment script
│   ├── backup.sh       # Backup script
│   └── monitor.sh      # Monitoring script
├── ssl/                # SSL certificates
├── docker-compose.prod.yml  # Production Docker Compose
└── docker-compose.staging.yml  # Staging Docker Compose
```

## Documentation Structure

```
docs/
├── api/                # API documentation
│   ├── backend/        # Backend API docs
│   └── frontend/       # Frontend API docs
├── user-guide/         # User documentation
├── developer-guide/    # Developer documentation
├── architecture/       # Architecture documentation
├── screenshots/        # Application screenshots
└── assets/             # Documentation assets
```

## Main Dependencies

- **Backend**:
  - Express: Web framework
  - Mongoose: MongoDB object modeling
  - Socket.io: Real-time communication
  - OpenAI/Anthropic: AI service APIs
  - JWT: Authentication

- **Frontend**:
  - React: UI library
  - Material-UI: Component library
  - React Router: Navigation
  - Axios: HTTP client
  - Socket.io-client: Real-time communication
EOL

# Create API Documentation index
echo -e "${GREEN}Creating API Documentation index...${NC}"
mkdir -p "$DOCS_DIR/api"
cat > "$DOCS_DIR/api/index.md" << EOL
# API Documentation

This section provides detailed documentation for the DentalAI Assistant APIs.

## Backend API

The backend API documentation is generated using JSDoc and Swagger:

- [Backend API Documentation](backend/index.html)
- [Swagger API Documentation](http://localhost:3000/api-docs) (when server is running)

## Frontend API

The frontend API documentation is generated using TypeDoc:

- [Frontend Documentation](frontend/index.html)

## API Endpoints

### Authentication

- **POST /api/auth/register**: Register a new user
- **POST /api/auth/login**: Authenticate user
- **GET /api/auth/me**: Get current user

### Users

- **GET /api/users**: Get all users
- **GET /api/users/:id**: Get a specific user
- **PUT /api/users/:id**: Update a user
- **DELETE /api/users/:id**: Delete a user

### Patients

- **GET /api/patients**: Get all patients
- **POST /api/patients**: Create a new patient
- **GET /api/patients/:id**: Get a specific patient
- **PUT /api/patients/:id**: Update a patient
- **DELETE /api/patients/:id**: Delete a patient
- **GET /api/patients/search**: Search patients

### Transcription

- **POST /api/transcription**: Transcribe audio to text
- **POST /api/transcription/process**: Process transcription to structured note

### Notes

- **GET /api/notes**: Get all notes
- **POST /api/notes**: Create a new note
- **GET /api/notes/:id**: Get a specific note
- **PUT /api/notes/:id**: Update a note
- **DELETE /api/notes/:id**: Delete a note
- **PUT /api/notes/:id/finalize**: Finalize a note
- **PUT /api/notes/:id/sign**: Sign a note

### Decision Support

- **POST /api/decision-support/differential**: Generate differential diagnoses
- **POST /api/decision-support/treatment**: Generate treatment recommendations

## WebSocket Events

- **connection**: Client connection
- **disconnect**: Client disconnection
- **start-transcription**: Start real-time transcription
- **transcription-update**: Real-time transcription updates
- **update-note**: Note updates
- **note-updated**: Broadcast note updates to clients
EOL

# Create Architecture Documentation
echo -e "${GREEN}Creating Architecture Documentation...${NC}"
mkdir -p "$DOCS_DIR/architecture"
cat > "$DOCS_DIR/architecture/index.md" << EOL
# System Architecture

This document provides an overview of the DentalAI Assistant system architecture.

## High-Level Architecture

DentalAI Assistant follows a modern microservices architecture pattern, with the following main components:

1. **Frontend Application**: React-based user interface
2. **Backend API Server**: Node.js/Express REST API
3. **MongoDB Database**: Persistent data storage
4. **AI Services**: Integration with OpenAI/Anthropic APIs
5. **Real-time Communication**: WebSocket server for real-time features

## Architecture Diagram

```
┌─────────────────┐       ┌─────────────────┐
│                 │       │                 │
│  Frontend App   │◄──────┤  Backend API    │
│  (React/TS)     │       │  (Node.js)      │
│                 │──────►│                 │
└─────────────────┘       └────────┬────────┘
                                   │
                                   │
                          ┌────────▼────────┐
                          │                 │
                          │   MongoDB       │
                          │   Database      │
                          │                 │
                          └────────┬────────┘
                                   │
                          ┌────────▼────────┐
                          │                 │
                          │   AI Services   │
                          │   (OpenAI/      │
                          │   Anthropic)    │
                          │                 │
                          └─────────────────┘
```

## Component Details

### Frontend Application

- **Technology**: React with TypeScript
- **State Management**: React Context API, local state
- **UI Framework**: Material-UI
- **Key Libraries**: 
  - React Router for navigation
  - Axios for API calls
  - Socket.io-client for real-time features
  - Chart.js for data visualization

### Backend API Server

- **Technology**: Node.js with Express
- **API**: RESTful API with JSON payloads
- **Authentication**: JWT-based authentication
- **Key Libraries**:
  - Mongoose for MongoDB integration
  - Socket.io for WebSocket support
  - OpenAI/Anthropic SDKs for AI service integration

### Database

- **Technology**: MongoDB
- **Schema**: Document-based schema with validation
- **Collections**:
  - Users
  - Patients
  - Notes
  - Appointments

### AI Services

- **Speech Recognition**: OpenAI Whisper API
- **Natural Language Processing**: 
  - OpenAI GPT-4 API
  - Anthropic Claude API
- **Clinical Decision Support**: Custom AI models based on GPT-4

### Real-time Communication

- **Technology**: Socket.io
- **Key Features**:
  - Real-time transcription streaming
  - Collaborative note editing
  - Notifications

## Data Flow

1. **Authentication Flow**:
   - User submits credentials
   - Backend validates credentials and issues JWT
   - Frontend stores JWT for subsequent requests

2. **Transcription Flow**:
   - User starts recording in the frontend
   - Audio data is sent to the backend
   - Backend sends audio to OpenAI Whisper API
   - Transcription is returned and processed
   - Structured note is generated using GPT-4/Claude

3. **Clinical Decision Support Flow**:
   - User enters patient symptoms and findings
   - Data is sent to the backend
   - Backend processes data using AI models
   - Differential diagnoses and recommendations are returned

## Security Architecture

- **Authentication**: JWT-based authentication with secure HTTP-only cookies
- **Authorization**: Role-based access control
- **Data Encryption**: TLS for data in transit, encryption for sensitive data at rest
- **API Security**: Rate limiting, input validation, CSRF protection
- **Infrastructure Security**: Firewall rules, network isolation, security groups

## Deployment Architecture

### Production Environment

- **Container Orchestration**: Docker Compose/Kubernetes
- **Load Balancing**: Nginx
- **Scaling**: Horizontal scaling for backend services
- **High Availability**: Multiple replicas across availability zones
- **Monitoring**: Prometheus, Grafana

### Staging Environment

- Similar to production but with reduced resources
- Used for testing before production deployment

## Integration Points

- **EHR Systems**: Integration with dental practice management systems
- **Scheduling Systems**: Calendar integrations
- **Billing Systems**: Integration with dental billing systems
- **Notification Systems**: Email, SMS notifications
EOL

# Create Contributing Guidelines
cat > "$DOCS_DIR/developer-guide/contributing.md" << EOL
# Contributing Guidelines

Thank you for your interest in contributing to DentalAI Assistant! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

Please be respectful and considerate of others when contributing to this project. We strive to maintain a welcoming and inclusive community.

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```
   git clone https://github.com/yourusername/dental-ai-assistant.git
   ```
3. Add the upstream repository:
   ```
   git remote add upstream https://github.com/originalowner/dental-ai-assistant.git
   ```
4. Create a new branch for your feature or bug fix:
   ```
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

1. Make your changes
2. Run tests to ensure your changes don't break existing functionality:
   ```
   npm test
   ```
3. Run linting to ensure your code follows the style guidelines:
   ```
   npm run lint
   ```
4. Commit your changes with a descriptive commit message:
   ```
   git commit -m "feat: add new feature"
   ```
   We follow the [Conventional Commits](https://www.conventionalcommits.org/) format.
5. Push your branch to your fork:
   ```
   git push origin feature/your-feature-name
   ```
6. Create a pull request from your fork to the upstream repository

## Pull Request Guidelines

- Keep your PR focused on a single feature or bug fix
- Write comprehensive descriptions of the changes
- Include screenshots or examples if applicable
- Make sure your changes pass all tests and linting
- Squash your commits into a single commit if possible

## Code Style

We follow these coding standards:

- **JavaScript/TypeScript**: ESLint configuration
- **CSS**: Consistent spacing and naming conventions
- **Git**: Conventional Commits format

## Testing

All new features should include appropriate tests:

- **Backend**: Unit tests with Jest for utilities and services, integration tests for API endpoints
- **Frontend**: Component tests with React Testing Library, integration tests for complex workflows

## Documentation

Please update documentation for any new features or changes:

- Update relevant documentation in the `docs/` directory
- Add JSDoc comments to functions and classes
- Update README files if necessary

## Review Process

1. Your PR will be reviewed by at least one maintainer
2. Feedback may be provided for necessary changes
3. Once approved, your PR will be merged

## License

By contributing to this project, you agree that your contributions will be licensed under the project's license.
EOL

# Make documentation files owned by the user
echo -e "${GREEN}Setting file permissions...${NC}"
chown -R $USER:$USER "$DOCS_DIR"

echo -e "${GREEN}"
echo "======================================================"
echo "   DentalAI Assistant Documentation Setup Complete    "
echo "======================================================"
echo -e "${NC}"
echo "Documentation has been set up successfully."
echo -e "You can generate API documentation with:"
echo -e "${YELLOW}cd $DOCS_DIR && ./generate-docs.sh${NC}"
echo -e "Documentation is available in the docs/ directory."
