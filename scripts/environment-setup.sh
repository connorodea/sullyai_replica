#!/bin/bash

# Environment setup script for DentalAI Assistant
# Installs necessary tools and dependencies for development

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

echo -e "${BLUE}"
echo "======================================================"
echo "       DentalAI Assistant Environment Setup           "
echo "======================================================"
echo -e "${NC}"

# Check for required system tools
echo -e "${GREEN}Checking for required system tools...${NC}"

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}Node.js not found. Installing Node.js...${NC}"
    
    # Determine the OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if ! command -v brew &> /dev/null; then
            # Install Homebrew if not installed
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install node
    else
        echo -e "${RED}Unsupported operating system. Please install Node.js manually.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}Node.js is already installed.${NC}"
fi

# Check Node.js version
NODE_VERSION=$(node -v)
echo -e "${GREEN}Node.js version: $NODE_VERSION${NC}"

# Check for npm
if ! command -v npm &> /dev/null; then
    echo -e "${RED}npm not found. Please install npm manually.${NC}"
    exit 1
else
    echo -e "${GREEN}npm is already installed.${NC}"
    # Update npm to the latest version
    npm install -g npm@latest
fi

# Check npm version
NPM_VERSION=$(npm -v)
echo -e "${GREEN}npm version: $NPM_VERSION${NC}"

# Install global npm packages
echo -e "${GREEN}Installing global npm packages...${NC}"
npm install -g nodemon typescript ts-node @angular/cli create-react-app

# Check for MongoDB
if ! command -v mongod &> /dev/null; then
    echo -e "${YELLOW}MongoDB not found. Installing MongoDB...${NC}"
    
    # Determine the OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux - Ubuntu/Debian
        wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
        sudo apt-get update
        sudo apt-get install -y mongodb-org
        sudo systemctl start mongod
        sudo systemctl enable mongod
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if ! command -v brew &> /dev/null; then
            # Install Homebrew if not installed
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew tap mongodb/brew
        brew install mongodb-community
        brew services start mongodb-community
    else
        echo -e "${RED}Unsupported operating system. Please install MongoDB manually.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}MongoDB is already installed.${NC}"
fi

# Check for Git
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Git not found. Installing Git...${NC}"
    
    # Determine the OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        sudo apt-get install -y git
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if ! command -v brew &> /dev/null; then
            # Install Homebrew if not installed
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install git
    else
        echo -e "${RED}Unsupported operating system. Please install Git manually.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}Git is already installed.${NC}"
fi

# Check Git version
GIT_VERSION=$(git --version)
echo -e "${GREEN}Git version: $GIT_VERSION${NC}"

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker not found. Installing Docker...${NC}"
    
    # Determine the OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        sudo systemctl enable docker
        sudo systemctl start docker
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        echo -e "${YELLOW}Please install Docker Desktop for Mac manually from https://www.docker.com/products/docker-desktop${NC}"
    else
        echo -e "${RED}Unsupported operating system. Please install Docker manually.${NC}"
    fi
else
    echo -e "${GREEN}Docker is already installed.${NC}"
fi

# Install Docker Compose if not already installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}Docker Compose not found. Installing Docker Compose...${NC}"
    
    # Determine the OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS (should be included with Docker Desktop)
        echo -e "${YELLOW}Docker Compose should be included with Docker Desktop for Mac.${NC}"
    else
        echo -e "${RED}Unsupported operating system. Please install Docker Compose manually.${NC}"
    fi
else
    echo -e "${GREEN}Docker Compose is already installed.${NC}"
fi

# Create project directories
echo -e "${GREEN}Setting up project directory structure...${NC}"
mkdir -p "$HOME/dental-ai-assistant/backend/src/controllers"
mkdir -p "$HOME/dental-ai-assistant/backend/src/models"
mkdir -p "$HOME/dental-ai-assistant/backend/src/routes"
mkdir -p "$HOME/dental-ai-assistant/backend/src/services"
mkdir -p "$HOME/dental-ai-assistant/backend/src/middleware"
mkdir -p "$HOME/dental-ai-assistant/backend/src/utils"
mkdir -p "$HOME/dental-ai-assistant/backend/src/config"
mkdir -p "$HOME/dental-ai-assistant/backend/src/ai"
mkdir -p "$HOME/dental-ai-assistant/backend/tests"

mkdir -p "$HOME/dental-ai-assistant/frontend/src/components"
mkdir -p "$HOME/dental-ai-assistant/frontend/src/pages"
mkdir -p "$HOME/dental-ai-assistant/frontend/src/services"
mkdir -p "$HOME/dental-ai-assistant/frontend/src/utils"
mkdir -p "$HOME/dental-ai-assistant/frontend/src/assets"
mkdir -p "$HOME/dental-ai-assistant/frontend/src/styles"
mkdir -p "$HOME/dental-ai-assistant/frontend/src/contexts"
mkdir -p "$HOME/dental-ai-assistant/frontend/public"

# Install development tools
echo -e "${GREEN}Installing development tools...${NC}"
npm install -g eslint prettier jest

echo -e "${GREEN}"
echo "======================================================"
echo "     DentalAI Assistant Environment Setup Complete    "
echo "======================================================"
echo -e "${NC}"
echo "The development environment has been set up successfully."
echo "Proceed with backend and frontend setup."
