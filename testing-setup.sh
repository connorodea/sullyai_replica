#!/bin/bash

# Testing setup script for DentalAI Assistant
# Sets up comprehensive testing environment and test suites

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
echo "      DentalAI Assistant Testing Setup                "
echo "======================================================"
echo -e "${NC}"

# Create testing directories if they don't exist
mkdir -p "$BACKEND_DIR/tests/unit"
mkdir -p "$BACKEND_DIR/tests/integration"
mkdir -p "$BACKEND_DIR/tests/e2e"
mkdir -p "$FRONTEND_DIR/src/tests/unit"
mkdir -p "$FRONTEND_DIR/src/tests/integration"
mkdir -p "$PROJECT_DIR/tests/e2e"

# Install backend testing dependencies
echo -e "${GREEN}Installing backend testing dependencies...${NC}"
cd "$BACKEND_DIR"
npm install --save-dev jest supertest mongodb-memory-server mock-socket sinon chai nock

# Install frontend testing dependencies
echo -e "${GREEN}Installing frontend testing dependencies...${NC}"
cd "$FRONTEND_DIR"
npm install --save-dev @testing-library/react @testing-library/jest-dom @testing-library/user-event msw jest-environment-jsdom

# Install E2E testing dependencies
echo -e "${GREEN}Installing E2E testing dependencies...${NC}"
cd "$PROJECT_DIR"
npm install --save-dev cypress playwright @playwright/test

# Configure Jest for backend
echo -e "${GREEN}Configuring Jest for backend...${NC}"
cat > "$BACKEND_DIR/jest.config.js" << EOL
module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/tests/**/*.test.js'],
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/server.js',
    '!**/node_modules/**'
  ],
  coverageDirectory: 'coverage',
  testPathIgnorePatterns: [
    '/node_modules/'
  ],
  setupFilesAfterEnv: ['./tests/setup.js'],
  testTimeout: 10000,
  watchPlugins: [
    'jest-watch-typeahead/filename',
    'jest-watch-typeahead/testname'
  ]
};
EOL

# Create backend test setup file
cat > "$BACKEND_DIR/tests/setup.js" << EOL
// Global test setup for backend tests
const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config({ path: '.env.test' });

let mongoServer;

// Set up MongoDB Memory Server for testing
beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  const mongoUri = mongoServer.getUri();
  
  await mongoose.connect(mongoUri, {
    useNewUrlParser: true,
    useUnifiedTopology: true
  });
});

// Clear database between tests
afterEach(async () => {
  const collections = mongoose.connection.collections;
  
  for (const key in collections) {
    const collection = collections[key];
    await collection.deleteMany({});
  }
});

// Close connections and stop MongoDB Memory Server after tests
afterAll(async () => {
  await mongoose.connection.close();
  await mongoServer.stop();
});

// Global test timeout
jest.setTimeout(30000);
EOL

# Create test environment file for backend
cat > "$BACKEND_DIR/.env.test" << EOL
# Test environment variables for backend

NODE_ENV=test
PORT=3001
MONGODB_URI=mongodb://localhost:27017/dental-ai-test
JWT_SECRET=test_jwt_secret
JWT_EXPIRATION=1h

# Test API keys (these are fake keys for testing)
OPENAI_API_KEY=sk-test-openai-key
ANTHROPIC_API_KEY=sk-test-anthropic-key
PRIMARY_AI_SERVICE=openai
EOL

# Configure Jest for frontend
echo -e "${GREEN}Configuring Jest for frontend...${NC}"
cd "$FRONTEND_DIR"

# Create setupTests.js file
cat > "$FRONTEND_DIR/src/setupTests.ts" << EOL
// Jest setup file for frontend tests
import '@testing-library/jest-dom';
import { server } from './tests/mocks/server';

// Establish API mocking before all tests
beforeAll(() => server.listen());

// Reset any request handlers that we may add during the tests
afterEach(() => server.resetHandlers());

// Clean up after the tests are finished
afterAll(() => server.close());
EOL

# Create MSW server for API mocking
mkdir -p "$FRONTEND_DIR/src/tests/mocks"
cat > "$FRONTEND_DIR/src/tests/mocks/server.ts" << EOL
// MSW Server setup for API mocking
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

// Setup requests interception using the given handlers
export const server = setupServer(...handlers);
EOL

# Create MSW handlers
cat > "$FRONTEND_DIR/src/tests/mocks/handlers.ts" << EOL
// MSW Handlers for API mocking
import { rest } from 'msw';

// API endpoint base URL
const apiUrl = process.env.REACT_APP_API_URL || 'http://localhost:3000/api';

export const handlers = [
  // Auth handlers
  rest.post(\`\${apiUrl}/auth/login\`, (req, res, ctx) => {
    return res(
      ctx.status(200),
      ctx.json({
        token: 'fake-jwt-token',
        user: {
          _id: '1',
          name: 'Test User',
          email: 'test@example.com',
          role: 'dentist',
          isAdmin: false
        }
      })
    );
  }),
  
  rest.get(\`\${apiUrl}/auth/me\`, (req, res, ctx) => {
    return res(
      ctx.status(200),
      ctx.json({
        _id: '1',
        name: 'Test User',
        email: 'test@example.com',
        role: 'dentist',
        isAdmin: false
      })
    );
  }),
  
  // Patients handlers
  rest.get(\`\${apiUrl}/patients\`, (req, res, ctx) => {
    return res(
      ctx.status(200),
      ctx.json([
        {
          _id: '1',
          firstName: 'John',
          lastName: 'Doe',
          dateOfBirth: '1985-06-15T00:00:00.000Z',
          gender: 'male',
          email: 'john.doe@example.com',
          phone: '(555) 123-4567',
          createdAt: '2023-01-01T00:00:00.000Z'
        },
        {
          _id: '2',
          firstName: 'Jane',
          lastName: 'Smith',
          dateOfBirth: '1990-03-22T00:00:00.000Z',
          gender: 'female',
          email: 'jane.smith@example.com',
          phone: '(555) 987-6543',
          createdAt: '2023-01-02T00:00:00.000Z'
        }
      ])
    );
  }),
  
  // Transcription handlers
  rest.post(\`\${apiUrl}/transcription\`, (req, res, ctx) => {
    return res(
      ctx.status(200),
      ctx.json({
        text: 'Sample transcription text for testing purposes.'
      })
    );
  }),
  
  rest.post(\`\${apiUrl}/transcription/process\`, (req, res, ctx) => {
    return res(
      ctx.status(200),
      ctx.json({
        rawTranscript: 'Sample transcription text for testing purposes.',
        structuredNote: {
          subjective: 'Patient reports tooth pain in lower right quadrant.',
          objective: 'Visual examination shows caries on tooth #30.',
          assessment: 'Dental caries on tooth #30.',
          plan: 'Schedule for restoration of tooth #30.',
          cdtCodes: [
            {
              code: 'D2392',
              description: 'Resin-based composite - two surfaces, posterior'
            }
          ]
        }
      })
    );
  }),
  
  // Notes handlers
  rest.get(\`\${apiUrl}/notes\`, (req, res, ctx) => {
    return res(
      ctx.status(200),
      ctx.json([
        {
          _id: '1',
          patient: '1',
          provider: '1',
          noteType: 'SOAP',
          content: {
            subjective: 'Patient reports tooth pain in lower right quadrant.',
            objective: 'Visual examination shows caries on tooth #30.',
            assessment: 'Dental caries on tooth #30.',
            plan: 'Schedule for restoration of tooth #30.'
          },
          createdAt: '2023-01-01T00:00:00.000Z',
          updatedAt: '2023-01-01T00:00:00.000Z',
          status: 'draft'
        }
      ])
    );
  })
];
EOL

# Configure Cypress for E2E testing
echo -e "${GREEN}Configuring Cypress for E2E testing...${NC}"
mkdir -p "$PROJECT_DIR/cypress/integration"
mkdir -p "$PROJECT_DIR/cypress/fixtures"
mkdir -p "$PROJECT_DIR/cypress/support"

# Create Cypress configuration
cat > "$PROJECT_DIR/cypress.json" << EOL
{
  "baseUrl": "http://localhost:3001",
  "viewportWidth": 1280,
  "viewportHeight": 720,
  "video": false,
  "screenshotOnRunFailure": true,
  "integrationFolder": "cypress/integration",
  "fixturesFolder": "cypress/fixtures",
  "supportFile": "cypress/support/index.js",
  "pluginsFile": "cypress/plugins/index.js",
  "env": {
    "apiUrl": "http://localhost:3000/api"
  }
}
EOL

# Create Cypress support file
mkdir -p "$PROJECT_DIR/cypress/plugins"
cat > "$PROJECT_DIR/cypress/plugins/index.js" << EOL
/// <reference types="cypress" />

/**
 * @type {Cypress.PluginConfig}
 */
module.exports = (on, config) => {
  // \`on\` is used to hook into various events Cypress emits
  // \`config\` is the resolved Cypress config
  return config;
};
EOL

cat > "$PROJECT_DIR/cypress/support/index.js" << EOL
// Import commands.js using ES2015 syntax
import './commands';

// Prevent uncaught exceptions from failing tests
Cypress.on('uncaught:exception', (err, runnable) => {
  // returning false here prevents Cypress from failing the test
  return false;
});
EOL

cat > "$PROJECT_DIR/cypress/support/commands.js" << EOL
// Custom Cypress commands

// Login command
Cypress.Commands.add('login', (email = 'dentist@dentalai.com', password = 'dentist123') => {
  cy.request({
    method: 'POST',
    url: \`\${Cypress.env('apiUrl')}/auth/login\`,
    body: {
      email,
      password
    }
  }).then((response) => {
    localStorage.setItem('token', response.body.token);
    cy.visit('/');
  });
});

// Logout command
Cypress.Commands.add('logout', () => {
  localStorage.removeItem('token');
  cy.visit('/login');
});
EOL

# Configure Playwright for E2E testing
echo -e "${GREEN}Configuring Playwright for E2E testing...${NC}"
mkdir -p "$PROJECT_DIR/tests/e2e/playwright"

# Create Playwright configuration
cat > "$PROJECT_DIR/playwright.config.js" << EOL
// @ts-check
const { devices } = require('@playwright/test');

/**
 * @see https://playwright.dev/docs/test-configuration
 * @type {import('@playwright/test').PlaywrightTestConfig}
 */
const config = {
  testDir: './tests/e2e/playwright',
  timeout: 30000,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  use: {
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'on-first-retry',
    baseURL: 'http://localhost:3001',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    {
      name: 'mobile-chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'mobile-safari',
      use: { ...devices['iPhone 12'] },
    },
  ],
};

module.exports = config;
EOL

# Create sample test files
echo -e "${GREEN}Creating sample test files...${NC}"

# Backend unit tests
cat > "$BACKEND_DIR/tests/unit/auth.test.js" << EOL
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { register, login } = require('../../src/controllers/authController');
const User = require('../../src/models/User');

// Mock dependencies
jest.mock('../../src/models/User');
jest.mock('bcryptjs');
jest.mock('jsonwebtoken');

describe('Auth Controller', () => {
  let req;
  let res;
  let next;

  beforeEach(() => {
    req = {
      body: {
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        role: 'dentist'
      }
    };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn()
    };
    next = jest.fn();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('register', () => {
    it('should register a new user successfully', async () => {
      // Mock User.findOne to return null (user doesn't exist)
      User.findOne.mockResolvedValue(null);
      
      // Mock User.create to return a new user
      const mockUser = {
        _id: 'user_id',
        name: 'Test User',
        email: 'test@example.com',
        role: 'dentist',
        isAdmin: false
      };
      User.create.mockResolvedValue(mockUser);
      
      // Mock jwt.sign to return a token
      jwt.sign.mockReturnValue('fake_token');
      
      await register(req, res, next);
      
      expect(User.findOne).toHaveBeenCalledWith({ email: 'test@example.com' });
      expect(User.create).toHaveBeenCalled();
      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith({
        _id: 'user_id',
        name: 'Test User',
        email: 'test@example.com',
        role: 'dentist',
        isAdmin: false,
        token: 'fake_token'
      });
    });

    it('should return 400 if user already exists', async () => {
      // Mock User.findOne to return a user (user exists)
      User.findOne.mockResolvedValue({ email: 'test@example.com' });
      
      await register(req, res, next);
      
      expect(User.findOne).toHaveBeenCalledWith({ email: 'test@example.com' });
      expect(User.create).not.toHaveBeenCalled();
      expect(res.status).toHaveBeenCalledWith(400);
      expect(next).toHaveBeenCalled();
    });
  });

  describe('login', () => {
    it('should login user successfully with correct credentials', async () => {
      // Mock User.findOne to return a user
      const mockUser = {
        _id: 'user_id',
        name: 'Test User',
        email: 'test@example.com',
        password: 'hashed_password',
        role: 'dentist',
        isAdmin: false,
        matchPassword: jest.fn().mockResolvedValue(true)
      };
      User.findOne.mockReturnValue({
        select: jest.fn().mockResolvedValue(mockUser)
      });
      
      // Mock jwt.sign to return a token
      jwt.sign.mockReturnValue('fake_token');
      
      req.body = {
        email: 'test@example.com',
        password: 'password123'
      };
      
      await login(req, res, next);
      
      expect(User.findOne).toHaveBeenCalledWith({ email: 'test@example.com' });
      expect(mockUser.matchPassword).toHaveBeenCalledWith('password123');
      expect(res.json).toHaveBeenCalledWith({
        _id: 'user_id',
        name: 'Test User',
        email: 'test@example.com',
        role: 'dentist',
        isAdmin: false,
        token: 'fake_token'
      });
    });

    it('should return 401 if user not found', async () => {
      // Mock User.findOne to return null (user not found)
      User.findOne.mockReturnValue({
        select: jest.fn().mockResolvedValue(null)
      });
      
      req.body = {
        email: 'test@example.com',
        password: 'password123'
      };
      
      await login(req, res, next);
      
      expect(User.findOne).toHaveBeenCalledWith({ email: 'test@example.com' });
      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).toHaveBeenCalled();
    });

    it('should return 401 if password is incorrect', async () => {
      // Mock User.findOne to return a user
      const mockUser = {
        _id: 'user_id',
        name: 'Test User',
        email: 'test@example.com',
        password: 'hashed_password',
        role: 'dentist',
        isAdmin: false,
        matchPassword: jest.fn().mockResolvedValue(false)
      };
      User.findOne.mockReturnValue({
        select: jest.fn().mockResolvedValue(mockUser)
      });
      
      req.body = {
        email: 'test@example.com',
        password: 'wrong_password'
      };
      
      await login(req, res, next);
      
      expect(User.findOne).toHaveBeenCalledWith({ email: 'test@example.com' });
      expect(mockUser.matchPassword).toHaveBeenCalledWith('wrong_password');
      expect(res.status).toHaveBeenCalledWith(401);
      expect(next).toHaveBeenCalled();
    });
  });
});
EOL

# Backend integration tests
cat > "$BACKEND_DIR/tests/integration/auth.test.js" << EOL
const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../../src/app'); // You need to export app from server.js
const User = require('../../src/models/User');

describe('Auth Endpoints', () => {
  beforeEach(async () => {
    // Clear users collection before each test
    await User.deleteMany({});
  });

  describe('POST /api/auth/register', () => {
    it('should register a new user', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          password: 'password123',
          role: 'dentist'
        });
      
      expect(res.statusCode).toEqual(201);
      expect(res.body).toHaveProperty('token');
      expect(res.body).toHaveProperty('_id');
      expect(res.body.name).toEqual('Test User');
      expect(res.body.email).toEqual('test@example.com');
      expect(res.body.role).toEqual('dentist');
    });

    it('should not register a user with existing email', async () => {
      // Create a user first
      await User.create({
        name: 'Existing User',
        email: 'test@example.com',
        password: 'password123',
        role: 'dentist'
      });
      
      // Try to register with the same email
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          name: 'Test User',
          email: 'test@example.com',
          password: 'password123',
          role: 'dentist'
        });
      
      expect(res.statusCode).toEqual(400);
      expect(res.body).toHaveProperty('error');
    });
  });

  describe('POST /api/auth/login', () => {
    it('should login existing user', async () => {
      // Create a user first
      const user = new User({
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        role: 'dentist'
      });
      
      await user.save();
      
      // Login
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com',
          password: 'password123'
        });
      
      expect(res.statusCode).toEqual(200);
      expect(res.body).toHaveProperty('token');
      expect(res.body.name).toEqual('Test User');
      expect(res.body.email).toEqual('test@example.com');
    });

    it('should not login with invalid credentials', async () => {
      // Create a user first
      const user = new User({
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        role: 'dentist'
      });
      
      await user.save();
      
      // Try to login with wrong password
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com',
          password: 'wrongpassword'
        });
      
      expect(res.statusCode).toEqual(401);
      expect(res.body).toHaveProperty('error');
    });
  });

  describe('GET /api/auth/me', () => {
    it('should get current user profile', async () => {
      // Create a user first
      const user = new User({
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        role: 'dentist'
      });
      
      await user.save();
      
      // Login to get token
      const loginRes = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com',
          password: 'password123'
        });
      
      const token = loginRes.body.token;
      
      // Get user profile
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', \`Bearer \${token}\`);
      
      expect(res.statusCode).toEqual(200);
      expect(res.body.name).toEqual('Test User');
      expect(res.body.email).toEqual('test@example.com');
    });

    it('should return 401 if not authenticated', async () => {
      const res = await request(app)
        .get('/api/auth/me');
      
      expect(res.statusCode).toEqual(401);
    });
  });
});
EOL

# Frontend unit tests
cat > "$FRONTEND_DIR/src/tests/unit/components/LoginForm.test.tsx" << EOL
import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import LoginForm from '../../../components/auth/LoginForm';
import { AuthProvider } from '../../../contexts/AuthContext';

// Mock the useNavigate hook
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => jest.fn(),
}));

// Mock the toast notifications
jest.mock('react-toastify', () => ({
  toast: {
    success: jest.fn(),
    error: jest.fn(),
  },
}));

describe('LoginForm', () => {
  beforeEach(() => {
    render(
      <BrowserRouter>
        <AuthProvider>
          <LoginForm />
        </AuthProvider>
      </BrowserRouter>
    );
  });

  it('renders the login form', () => {
    expect(screen.getByText(/Login/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/Email Address/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/Password/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Login/i })).toBeInTheDocument();
  });

  it('allows entering email and password', () => {
    const emailInput = screen.getByLabelText(/Email Address/i);
    const passwordInput = screen.getByLabelText(/Password/i);

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    fireEvent.change(passwordInput, { target: { value: 'password123' } });

    expect(emailInput).toHaveValue('test@example.com');
    expect(passwordInput).toHaveValue('password123');
  });

  it('submits the form with valid data', async () => {
    const emailInput = screen.getByLabelText(/Email Address/i);
    const passwordInput = screen.getByLabelText(/Password/i);
    const loginButton = screen.getByRole('button', { name: /Login/i });

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    fireEvent.change(passwordInput, { target: { value: 'password123' } });
    fireEvent.click(loginButton);

    // Wait for the form submission to complete
    await waitFor(() => {
      // This checks if the button is not in loading state
      expect(loginButton).not.toBeDisabled();
    });
  });

  it('shows validation errors for empty fields', async () => {
    const loginButton = screen.getByRole('button', { name: /Login/i });
    
    // Submit form without entering data
    fireEvent.click(loginButton);
    
    // Check for validation errors
    await waitFor(() => {
      expect(screen.getByText(/Email is required/i)).toBeInTheDocument();
      expect(screen.getByText(/Password is required/i)).toBeInTheDocument();
    });
  });
});
EOL

# End-to-end tests with Cypress
cat > "$PROJECT_DIR/cypress/integration/login.spec.js" << EOL
/// <reference types="cypress" />

describe('Login Page', () => {
  beforeEach(() => {
    cy.visit('/login');
  });

  it('displays the login form', () => {
    cy.get('h2').should('contain', 'Login');
    cy.get('input[name="email"]').should('exist');
    cy.get('input[name="password"]').should('exist');
    cy.get('button[type="submit"]').should('exist');
  });

  it('shows validation errors for empty fields', () => {
    cy.get('button[type="submit"]').click();
    cy.get('form').should('contain', 'Email is required');
    cy.get('form').should('contain', 'Password is required');
  });

  it('allows a user to login', () => {
    // Intercept the login request
    cy.intercept('POST', '/api/auth/login', {
      statusCode: 200,
      body: {
        token: 'fake-jwt-token',
        user: {
          _id: '1',
          name: 'Test User',
          email: 'test@example.com',
          role: 'dentist',
          isAdmin: false
        }
      }
    }).as('loginRequest');

    // Fill out the form
    cy.get('input[name="email"]').type('test@example.com');
    cy.get('input[name="password"]').type('password123');
    cy.get('button[type="submit"]').click();

    // Wait for the request to complete
    cy.wait('@loginRequest');

    // Verify we're redirected to the dashboard
    cy.url().should('include', '/dashboard');
  });

  it('shows an error message for invalid credentials', () => {
    // Intercept the login request
    cy.intercept('POST', '/api/auth/login', {
      statusCode: 401,
      body: {
        error: 'Invalid credentials'
      }
    }).as('loginRequest');

    // Fill out the form
    cy.get('input[name="email"]').type('test@example.com');
    cy.get('input[name="password"]').type('wrongpassword');
    cy.get('button[type="submit"]').click();

    // Wait for the request to complete
    cy.wait('@loginRequest');

    // Verify the error message is displayed
    cy.get('form').should('contain', 'Invalid credentials');
  });
});
EOL

# End-to-end tests with Playwright
cat > "$PROJECT_DIR/tests/e2e/playwright/login.spec.js" << EOL
const { test, expect } = require('@playwright/test');

test.describe('Login Page', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
  });

  test('displays the login form', async ({ page }) => {
    await expect(page.locator('h2')).toContainText('Login');
    await expect(page.locator('input[name="email"]')).toBeVisible();
    await expect(page.locator('input[name="password"]')).toBeVisible();
    await expect(page.locator('button[type="submit"]')).toBeVisible();
  });

  test('shows validation errors for empty fields', async ({ page }) => {
    await page.locator('button[type="submit"]').click();
    await expect(page.locator('form')).toContainText('Email is required');
    await expect(page.locator('form')).toContainText('Password is required');
  });

  test('allows a user to login', async ({ page }) => {
    // Intercept the login request
    await page.route('/api/auth/login', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          token: 'fake-jwt-token',
          user: {
            _id: '1',
            name: 'Test User',
            email: 'test@example.com',
            role: 'dentist',
            isAdmin: false
          }
        })
      });
    });

    // Fill out the form
    await page.fill('input[name="email"]', 'test@example.com');
    await page.fill('input[name="password"]', 'password123');
    await page.click('button[type="submit"]');

    // Verify we're redirected to the dashboard
    await expect(page).toHaveURL(/.*dashboard/);
  });

  test('shows an error message for invalid credentials', async ({ page }) => {
    // Intercept the login request
    await page.route('/api/auth/login', async (route) => {
      await route.fulfill({
        status: 401,
        contentType: 'application/json',
        body: JSON.stringify({
          error: 'Invalid credentials'
        })
      });
    });

    // Fill out the form
    await page.fill('input[name="email"]', 'test@example.com');
    await page.fill('input[name="password"]', 'wrongpassword');
    await page.click('button[type="submit"]');

    // Verify the error message is displayed
    await expect(page.locator('form')).toContainText('Invalid credentials');
  });
});
EOL

# Update package.json scripts for the root project
echo -e "${GREEN}Updating package.json scripts...${NC}"
cd "$PROJECT_DIR"
if grep -q "\"test:all\":" package.json; then
  echo "Scripts already exist in package.json"
else
  # Using perl for in-place editing which works on both Linux and macOS
  perl -i -pe 's/"test": "npm run test:backend && npm run test:frontend"/"test": "npm run test:backend && npm run test:frontend",\n    "test:all": "npm run test:backend && npm run test:frontend && npm run test:e2e",\n    "test:e2e": "cypress run",\n    "test:e2e:playwright": "playwright test",\n    "test:coverage": "npm run test:backend:coverage && npm run test:frontend:coverage"/' package.json
fi

# Update package.json scripts for backend
cd "$BACKEND_DIR"
if grep -q "\"test:coverage\":" package.json; then
  echo "Scripts already exist in backend package.json"
else
  # Using perl for in-place editing which works on both Linux and macOS
  perl -i -pe 's/"test": "jest"/"test": "jest",\n    "test:watch": "jest --watch",\n    "test:coverage": "jest --coverage",\n    "test:unit": "jest tests\\/unit",\n    "test:integration": "jest tests\\/integration"/' package.json
fi

# Update package.json scripts for frontend
cd "$FRONTEND_DIR"
if grep -q "\"test:coverage\":" package.json; then
  echo "Scripts already exist in frontend package.json"
else
  # Using perl for in-place editing which works on both Linux and macOS
  perl -i -pe 's/"test": "react-scripts test"/"test": "react-scripts test",\n    "test:watch": "react-scripts test --watchAll",\n    "test:coverage": "react-scripts test --coverage",\n    "test:ci": "react-scripts test --watchAll=false"/' package.json
fi

# Create a README file for testing
echo -e "${GREEN}Creating testing README...${NC}"
cat > "$PROJECT_DIR/tests/README.md" << EOL
# DentalAI Assistant - Testing

This directory contains the testing setup and test files for the DentalAI Assistant application.

## Testing Structure

The project uses a comprehensive testing approach with multiple levels of testing:

1. **Unit Tests**: Testing individual components and functions in isolation
2. **Integration Tests**: Testing the interaction between components
3. **End-to-End Tests**: Testing the entire application flow

## Test Directories

- **Backend Tests**: Located in \`backend/tests/\`
  - \`unit/\`: Unit tests for backend components
  - \`integration/\`: Integration tests for backend APIs
  - \`e2e/\`: End-to-end tests for backend workflows

- **Frontend Tests**: Located in \`frontend/src/tests/\`
  - \`unit/\`: Unit tests for React components
  - \`integration/\`: Integration tests for frontend workflows

- **End-to-End Tests**: Located in \`tests/e2e/\`
  - \`cypress/\`: E2E tests using Cypress
  - \`playwright/\`: E2E tests using Playwright

## Running Tests

### Running All Tests

\`\`\`
npm test
\`\`\`

### Running Backend Tests

\`\`\`
npm run test:backend
npm run test:backend:unit
npm run test:backend:integration
\`\`\`

### Running Frontend Tests

\`\`\`
npm run test:frontend
npm run test:frontend:watch
\`\`\`

### Running E2E Tests

\`\`\`
npm run test:e2e                # Cypress
npm run test:e2e:playwright      # Playwright
\`\`\`

### Running Test Coverage

\`\`\`
npm run test:coverage
\`\`\`

## Test Configuration

- **Backend**: Jest configuration in \`backend/jest.config.js\`
- **Frontend**: Create React App test setup
- **Cypress**: Configuration in \`cypress.json\`
- **Playwright**: Configuration in \`playwright.config.js\`

## Mock Data

- **API Mocks**: Frontend API mocks using Mock Service Worker (MSW) in \`frontend/src/tests/mocks/\`
- **Fixtures**: Test fixtures in \`cypress/fixtures/\`

## Continuous Integration

Tests are automatically run in the CI/CD pipeline defined in \`.github/workflows/ci.yml\`.
EOL

echo -e "${GREEN}"
echo "======================================================"
echo "      DentalAI Assistant Testing Setup Complete       "
echo "======================================================"
echo -e "${NC}"
echo "Testing environment has been set up successfully."
echo -e "You can run tests with the following commands:"
echo -e "${YELLOW}npm test${NC} - Run all tests"
echo -e "${YELLOW}npm run test:backend${NC} - Run backend tests"
echo -e "${YELLOW}npm run test:frontend${NC} - Run frontend tests"
echo -e "${YELLOW}npm run test:e2e${NC} - Run end-to-end tests with Cypress"
echo -e "${YELLOW}npm run test:coverage${NC} - Run tests with coverage reports"
