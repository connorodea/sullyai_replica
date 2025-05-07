#!/bin/bash

# Backend setup script for DentalAI Assistant
# Sets up the Node.js backend server with Express

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

# Project directory
PROJECT_DIR="$HOME/dental-ai-assistant"
BACKEND_DIR="$PROJECT_DIR/backend"

echo -e "${BLUE}"
echo "======================================================"
echo "         DentalAI Assistant Backend Setup             "
echo "======================================================"
echo -e "${NC}"

# Navigate to backend directory
cd "$BACKEND_DIR"

# Initialize npm project
echo -e "${GREEN}Initializing npm project...${NC}"
npm init -y

# Update package.json
echo -e "${GREEN}Updating package.json...${NC}"
cat > package.json << EOL
{
  "name": "dental-ai-assistant-backend",
  "version": "0.1.0",
  "description": "Backend server for DentalAI Assistant",
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js",
    "test": "jest",
    "lint": "eslint ."
  },
  "keywords": [
    "dental",
    "ai",
    "healthcare",
    "assistant",
    "scribe"
  ],
  "author": "",
  "license": "UNLICENSED",
  "private": true,
  "dependencies": {
    "axios": "^0.27.2",
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.0.1",
    "express": "^4.18.1",
    "express-rate-limit": "^6.4.0",
    "express-validator": "^6.14.1",
    "helmet": "^5.1.0",
    "jsonwebtoken": "^8.5.1",
    "mongoose": "^6.3.5",
    "morgan": "^1.10.0",
    "multer": "^1.4.5-lts.1",
    "openai": "^3.1.0",
    "socket.io": "^4.5.1",
    "winston": "^3.7.2"
  },
  "devDependencies": {
    "eslint": "^8.17.0",
    "jest": "^28.1.1",
    "nodemon": "^2.0.16",
    "supertest": "^6.2.3"
  }
}
EOL

# Install dependencies
echo -e "${GREEN}Installing dependencies...${NC}"
npm install

# Create basic server setup
echo -e "${GREEN}Creating server files...${NC}"

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo -e "${GREEN}Creating .env file...${NC}"
    cat > .env << EOL
# DentalAI Assistant Backend Environment Variables
NODE_ENV=development
PORT=3000
MONGODB_URI=mongodb://localhost:27017/dental-ai
JWT_SECRET=change_this_to_a_secure_random_string
JWT_EXPIRATION=24h
OPENAI_API_KEY=your_openai_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here
EOL
fi

# Create server.js
cat > src/server.js << EOL
const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const mongoose = require('mongoose');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');
const { setupWebSockets } = require('./utils/socket');
const logger = require('./utils/logger');
const errorHandler = require('./middleware/errorHandler');

// Load environment variables
dotenv.config();

// Initialize Express app
const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: process.env.FRONTEND_URL || 'http://localhost:3001',
    methods: ['GET', 'POST'],
    credentials: true
  }
});

// Setup WebSockets
setupWebSockets(io);

// Middleware
app.use(helmet()); // Security headers
app.use(cors()); // Enable CORS
app.use(express.json()); // Parse JSON bodies
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded bodies
app.use(morgan('dev')); // Request logging

// API Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/patients', require('./routes/patients'));
app.use('/api/transcription', require('./routes/transcription'));
app.use('/api/notes', require('./routes/notes'));
app.use('/api/decision-support', require('./routes/decisionSupport'));

// Health check route
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', timestamp: new Date() });
});

// Error handling middleware
app.use(errorHandler);

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI)
  .then(() => {
    logger.info('Connected to MongoDB');
    
    // Start the server
    const PORT = process.env.PORT || 3000;
    server.listen(PORT, () => {
      logger.info(\`Server running in \${process.env.NODE_ENV} mode on port \${PORT}\`);
    });
  })
  .catch(error => {
    logger.error('MongoDB connection error:', error);
    process.exit(1);
  });

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  logger.error('Unhandled Promise Rejection:', err);
  // Close server & exit process
  server.close(() => process.exit(1));
});
EOL

# Create directory structure and basic files
mkdir -p src/config
mkdir -p src/controllers
mkdir -p src/middleware
mkdir -p src/models
mkdir -p src/routes
mkdir -p src/services
mkdir -p src/utils
mkdir -p src/ai

# Create utility files
# Logger
cat > src/utils/logger.js << EOL
const winston = require('winston');
const path = require('path');

// Define log format
const logFormat = winston.format.combine(
  winston.format.timestamp(),
  winston.format.printf(({ timestamp, level, message }) => {
    return \`\${timestamp} \${level.toUpperCase()}: \${message}\`;
  })
);

// Create logger instance
const logger = winston.createLogger({
  level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
  format: logFormat,
  transports: [
    // Console transport
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        logFormat
      )
    }),
    // File transport - error logs
    new winston.transports.File({ 
      filename: path.join(__dirname, '../../logs/error.log'), 
      level: 'error' 
    }),
    // File transport - all logs
    new winston.transports.File({ 
      filename: path.join(__dirname, '../../logs/combined.log') 
    })
  ]
});

module.exports = logger;
EOL

# Socket.io setup
cat > src/utils/socket.js << EOL
const logger = require('./logger');

// Setup WebSockets using Socket.io
const setupWebSockets = (io) => {
  // Connection event
  io.on('connection', (socket) => {
    logger.info(\`New client connected: \${socket.id}\`);
    
    // Handle transcription streaming
    socket.on('start-transcription', (data) => {
      logger.info(\`Starting transcription for user: \${data.userId}\`);
      // Additional implementation details here
    });
    
    // Handle real-time note updates
    socket.on('update-note', (data) => {
      logger.info(\`Note update received for patient: \${data.patientId}\`);
      // Broadcast updates to other clients if needed
      socket.broadcast.emit('note-updated', data);
    });
    
    // Disconnection event
    socket.on('disconnect', () => {
      logger.info(\`Client disconnected: \${socket.id}\`);
    });
  });
};

module.exports = { setupWebSockets };
EOL

# Error handler middleware
cat > src/middleware/errorHandler.js << EOL
const logger = require('../utils/logger');

// Error handling middleware
const errorHandler = (err, req, res, next) => {
  // Log the error
  logger.error(\`\${err.name}: \${err.message}\`);
  logger.error(err.stack);
  
  // Set status code
  const statusCode = res.statusCode !== 200 ? res.statusCode : 500;
  
  // Send error response
  res.status(statusCode).json({
    error: {
      message: err.message,
      stack: process.env.NODE_ENV === 'production' ? '🥞' : err.stack
    }
  });
};

module.exports = errorHandler;
EOL

# Auth middleware
cat > src/middleware/auth.js << EOL
const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Authentication middleware
const protect = async (req, res, next) => {
  let token;
  
  // Check for token in Authorization header
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      // Get token from header
      token = req.headers.authorization.split(' ')[1];
      
      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      // Get user from token
      req.user = await User.findById(decoded.id).select('-password');
      
      next();
    } catch (error) {
      console.error(error);
      res.status(401);
      throw new Error('Not authorized, token failed');
    }
  }
  
  if (!token) {
    res.status(401);
    throw new Error('Not authorized, no token');
  }
};

// Admin middleware
const admin = (req, res, next) => {
  if (req.user && req.user.isAdmin) {
    next();
  } else {
    res.status(401);
    throw new Error('Not authorized as an admin');
  }
};

module.exports = { protect, admin };
EOL

# Create basic models
# User model
cat > src/models/User.js << EOL
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Please add a name']
  },
  email: {
    type: String,
    required: [true, 'Please add an email'],
    unique: true,
    match: [
      /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
      'Please add a valid email'
    ]
  },
  password: {
    type: String,
    required: [true, 'Please add a password'],
    minlength: 6,
    select: false
  },
  role: {
    type: String,
    enum: ['dentist', 'assistant', 'admin'],
    default: 'dentist'
  },
  isAdmin: {
    type: Boolean,
    default: false
  },
  practice: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Practice'
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Encrypt password using bcrypt
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) {
    next();
  }
  
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

// Match user entered password to hashed password in database
userSchema.methods.matchPassword = async function(enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
EOL

# Patient model
cat > src/models/Patient.js << EOL
const mongoose = require('mongoose');

const patientSchema = new mongoose.Schema({
  firstName: {
    type: String,
    required: [true, 'Please add a first name']
  },
  lastName: {
    type: String,
    required: [true, 'Please add a last name']
  },
  dateOfBirth: {
    type: Date,
    required: [true, 'Please add a date of birth']
  },
  gender: {
    type: String,
    enum: ['male', 'female', 'other', 'prefer not to say'],
    required: [true, 'Please specify gender']
  },
  email: {
    type: String,
    match: [
      /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
      'Please add a valid email'
    ]
  },
  phone: {
    type: String
  },
  address: {
    street: String,
    city: String,
    state: String,
    zipCode: String,
    country: String
  },
  insuranceInfo: {
    provider: String,
    policyNumber: String,
    groupNumber: String,
    primary: Boolean
  },
  medicalHistory: {
    allergies: [String],
    medications: [String],
    conditions: [String],
    surgeries: [String],
    familyHistory: [String]
  },
  dentalHistory: {
    lastVisit: Date,
    treatments: [String],
    notes: String
  },
  practice: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Practice',
    required: true
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Create index for efficient patient search
patientSchema.index({ firstName: 'text', lastName: 'text', email: 'text' });

module.exports = mongoose.model('Patient', patientSchema);
EOL

# Note model
cat > src/models/Note.js << EOL
const mongoose = require('mongoose');

const noteSchema = new mongoose.Schema({
  patient: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Patient',
    required: true
  },
  appointment: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Appointment'
  },
  provider: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  noteType: {
    type: String,
    enum: ['SOAP', 'procedure', 'followUp', 'other'],
    default: 'SOAP'
  },
  content: {
    subjective: String,
    objective: String,
    assessment: String,
    plan: String,
    additionalNotes: String,
    rawTranscript: String
  },
  diagnosisCodes: [{
    code: String,
    description: String
  }],
  procedureCodes: [{
    code: String,
    description: String
  }],
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  },
  status: {
    type: String,
    enum: ['draft', 'finalized', 'signed'],
    default: 'draft'
  },
  isDeleted: {
    type: Boolean,
    default: false
  }
});

// Update the updatedAt timestamp before saving
noteSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('Note', noteSchema);
EOL

# Create basic controllers
# Auth controller
cat > src/controllers/authController.js << EOL
const jwt = require('jsonwebtoken');
const User = require('../models/User');

// @desc    Register a new user
// @route   POST /api/auth/register
// @access  Public
exports.register = async (req, res, next) => {
  try {
    const { name, email, password, role } = req.body;
    
    // Check if user exists
    const userExists = await User.findOne({ email });
    
    if (userExists) {
      res.status(400);
      throw new Error('User already exists');
    }
    
    // Create user
    const user = await User.create({
      name,
      email,
      password,
      role
    });
    
    if (user) {
      res.status(201).json({
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        isAdmin: user.isAdmin,
        token: generateToken(user._id)
      });
    } else {
      res.status(400);
      throw new Error('Invalid user data');
    }
  } catch (error) {
    next(error);
  }
};

// @desc    Authenticate a user
// @route   POST /api/auth/login
// @access  Public
exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    
    // Check for user email
    const user = await User.findOne({ email }).select('+password');
    
    if (!user) {
      res.status(401);
      throw new Error('Invalid credentials');
    }
    
    // Check if password matches
    const isMatch = await user.matchPassword(password);
    
    if (!isMatch) {
      res.status(401);
      throw new Error('Invalid credentials');
    }
    
    res.json({
      _id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      isAdmin: user.isAdmin,
      token: generateToken(user._id)
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get current logged in user
// @route   GET /api/auth/me
// @access  Private
exports.getMe = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id);
    
    res.json({
      _id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      isAdmin: user.isAdmin
    });
  } catch (error) {
    next(error);
  }
};

// Generate JWT
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRATION
  });
};
EOL

# Transcription controller
cat > src/controllers/transcriptionController.js << EOL
const { transcribeAudio, processTranscription } = require('../services/transcriptionService');

// @desc    Transcribe audio to text
// @route   POST /api/transcription
// @access  Private
exports.transcribeAudio = async (req, res, next) => {
  try {
    const { audioData } = req.body;
    
    // Validate the request
    if (!audioData) {
      res.status(400);
      throw new Error('Audio data is required');
    }
    
    // Process the transcription
    const transcription = await transcribeAudio(audioData);
    
    res.json({
      success: true,
      data: transcription
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Process transcription to structured note
// @route   POST /api/transcription/process
// @access  Private
exports.processTranscription = async (req, res, next) => {
  try {
    const { transcription, patientId } = req.body;
    
    // Validate the request
    if (!transcription) {
      res.status(400);
      throw new Error('Transcription data is required');
    }
    
    // Process the transcription into structured note
    const processedNote = await processTranscription(transcription, patientId);
    
    res.json({
      success: true,
      data: processedNote
    });
  } catch (error) {
    next(error);
  }
};
EOL

# Create basic routes
# Auth routes
cat > src/routes/auth.js << EOL
const express = require('express');
const { register, login, getMe } = require('../controllers/authController');
const { protect } = require('../middleware/auth');

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.get('/me', protect, getMe);

module.exports = router;
EOL

# Transcription routes
cat > src/routes/transcription.js << EOL
const express = require('express');
const { transcribeAudio, processTranscription } = require('../controllers/transcriptionController');
const { protect } = require('../middleware/auth');

const router = express.Router();

router.post('/', protect, transcribeAudio);
router.post('/process', protect, processTranscription);

module.exports = router;
EOL

# Create basic services
# AI Integration Service
cat > src/services/aiService.js << EOL
const axios = require('axios');
const { Configuration, OpenAIApi } = require('openai');
const logger = require('../utils/logger');

// Configure OpenAI API
const configuration = new Configuration({
  apiKey: process.env.OPENAI_API_KEY,
});
const openai = new OpenAIApi(configuration);

// Generate clinical notes using GPT-4
const generateClinicalNotes = async (transcript, patientContext = {}) => {
  try {
    // Create a prompt with dental context
    const prompt = \`
You are an expert dental scribe AI assistant. Based on the following conversation transcript between a dentist and patient, 
generate a comprehensive SOAP note including relevant dental findings, diagnoses, and treatment plans.

Patient Context:
Name: \${patientContext.firstName || ''} \${patientContext.lastName || ''}
DOB: \${patientContext.dateOfBirth || ''}
Relevant History: \${patientContext.relevantHistory || 'None provided'}

Transcript:
\${transcript}

Generate a complete SOAP note with the following sections:
1. Subjective: Patient's chief complaint, symptoms, and relevant history
2. Objective: Clinical examination findings
3. Assessment: Diagnosis or differential diagnoses with supporting evidence
4. Plan: Treatment plan, prescriptions, and follow-up recommendations
5. Billing Codes: Suggest appropriate dental procedure codes (CDT codes)
\`;

    // Call OpenAI API
    const response = await openai.createCompletion({
      model: "gpt-4",
      prompt: prompt,
      temperature: 0.2,
      max_tokens: 1000,
      top_p: 1,
      frequency_penalty: 0,
      presence_penalty: 0,
    });

    // Process and structure the response
    const noteText = response.data.choices[0].text.trim();
    const structuredNote = parseNoteText(noteText);
    
    return structuredNote;
  } catch (error) {
    logger.error('Error in generating clinical notes:', error);
    throw new Error('Failed to generate clinical notes');
  }
};

// Generate differential diagnoses
const generateDifferentialDiagnoses = async (symptoms, findings) => {
  try {
    // Create a prompt for differential diagnoses
    const prompt = \`
You are an expert dental diagnostician AI. Based on the following symptoms and clinical findings,
provide a list of potential differential diagnoses for a dental patient, ranked by likelihood.
For each diagnosis, provide supporting evidence from the findings and potential next steps.

Symptoms: \${symptoms}
Clinical Findings: \${findings}

Generate a list of differential diagnoses with:
1. Diagnosis name
2. Supporting evidence
3. Recommended diagnostic tests or procedures
4. Treatment considerations
\`;

    // Call OpenAI API
    const response = await openai.createCompletion({
      model: "gpt-4",
      prompt: prompt,
      temperature: 0.3,
      max_tokens: 800,
      top_p: 1,
      frequency_penalty: 0,
      presence_penalty: 0,
    });

    return response.data.choices[0].text.trim();
  } catch (error) {
    logger.error('Error in generating differential diagnoses:', error);
    throw new Error('Failed to generate differential diagnoses');
  }
};

// Helper function to parse and structure the note text
const parseNoteText = (noteText) => {
  // Initialize the structured note
  const structuredNote = {
    subjective: '',
    objective: '',
    assessment: '',
    plan: '',
    billingCodes: []
  };

  // Split the text by sections
  const sections = noteText.split(/\\n\\d+\\./);
  
  // Extract each section
  if (sections.length >= 5) {
    structuredNote.subjective = sections[1].trim();
    structuredNote.objective = sections[2].trim();
    structuredNote.assessment = sections[3].trim();
    structuredNote.plan = sections[4].trim();
    
    // Extract billing codes if present
    const billingCodeSection = sections[5] ? sections[5].trim() : '';
    if (billingCodeSection) {
      // Extract codes using regex
      const codeMatches = billingCodeSection.match(/D\\d{4}/g);
      if (codeMatches) {
        structuredNote.billingCodes = codeMatches.map(code => ({
          code,
          description: '' // Would need a lookup table for descriptions
        }));
      }
    }
  }
  
  return structuredNote;
};

module.exports = {
  generateClinicalNotes,
  generateDifferentialDiagnoses
};
EOL

# Transcription Service
cat > src/services/transcriptionService.js << EOL
const axios = require('axios');
const logger = require('../utils/logger');
const { generateClinicalNotes } = require('./aiService');
const Patient = require('../models/Patient');

// Transcribe audio to text using Whisper API
const transcribeAudio = async (audioData) => {
  try {
    // Call OpenAI Whisper API
    const response = await axios.post(
      'https://api.openai.com/v1/audio/transcriptions',
      {
        file: audioData,
        model: 'whisper-1',
        language: 'en'
      },
      {
        headers: {
          'Authorization': \`Bearer \${process.env.OPENAI_API_KEY}\`,
          'Content-Type': 'multipart/form-data'
        }
      }
    );

    return response.data.text;
  } catch (error) {
    logger.error('Error in transcribing audio:', error);
    throw new Error('Failed to transcribe audio');
  }
};

// Process transcription into structured note
const processTranscription = async (transcription, patientId) => {
  try {
    // Get patient context if patientId is provided
    let patientContext = {};
    if (patientId) {
      const patient = await Patient.findById(patientId);
      if (patient) {
        patientContext = {
          firstName: patient.firstName,
          lastName: patient.lastName,
          dateOfBirth: patient.dateOfBirth,
          relevantHistory: formatPatientHistory(patient)
        };
      }
    }
    
    // Generate structured clinical notes using AI
    const structuredNote = await generateClinicalNotes(transcription, patientContext);
    
    return {
      rawTranscript: transcription,
      structuredNote
    };
  } catch (error) {
    logger.error('Error in processing transcription:', error);
    throw new Error('Failed to process transcription');
  }
};

// Helper function to format patient history
const formatPatientHistory = (patient) => {
  if (!patient || !patient.medicalHistory) return 'None provided';
  
  const { allergies, medications, conditions } = patient.medicalHistory;
  
  let historyText = '';
  
  if (allergies && allergies.length > 0) {
    historyText += \`Allergies: \${allergies.join(', ')}. \`;
  }
  
  if (medications && medications.length > 0) {
    historyText += \`Medications: \${medications.join(', ')}. \`;
  }
  
  if (conditions && conditions.length > 0) {
    historyText += \`Medical Conditions: \${conditions.join(', ')}. \`;
  }
  
  return historyText || 'None provided';
};

module.exports = {
  transcribeAudio,
  processTranscription
};
EOL

# Create a basic README file
cat > README.md << EOL
# DentalAI Assistant - Backend

This is the backend server for the DentalAI Assistant application, an AI-powered dental scribe and clinical decision support system.

## Features

- Real-time speech-to-text transcription for dental appointments
- AI-generated SOAP notes from transcriptions
- Clinical decision support with differential diagnoses
- Patient management system
- Secure authentication and authorization
- WebSocket support for real-time updates

## Getting Started

### Prerequisites

- Node.js (v14+)
- MongoDB
- OpenAI API key

### Installation

1. Clone the repository
2. Install dependencies: \`npm install\`
3. Create a \`.env\` file with the required environment variables
4. Start the development server: \`npm run dev\`

### Environment Variables

- \`NODE_ENV\`: development or production
- \`PORT\`: Server port (default: 3000)
- \`MONGODB_URI\`: MongoDB connection string
- \`JWT_SECRET\`: Secret for JWT token generation
- \`JWT_EXPIRATION\`: Token expiration time
- \`OPENAI_API_KEY\`: OpenAI API key for AI services
- \`ANTHROPIC_API_KEY\`: Anthropic API key (optional)

## API Endpoints

### Authentication
- \`POST /api/auth/register\`: Register a new user
- \`POST /api/auth/login\`: Authenticate user
- \`GET /api/auth/me\`: Get current user

### Transcription
- \`POST /api/transcription\`: Transcribe audio to text
- \`POST /api/transcription/process\`: Process transcription to structured note

### Patients
- \`GET /api/patients\`: Get all patients
- \`POST /api/patients\`: Create a new patient
- \`GET /api/patients/:id\`: Get a specific patient
- \`PUT /api/patients/:id\`: Update a patient
- \`DELETE /api/patients/:id\`: Delete a patient

### Notes
- \`GET /api/notes\`: Get all notes
- \`POST /api/notes\`: Create a new note
- \`GET /api/notes/:id\`: Get a specific note
- \`PUT /api/notes/:id\`: Update a note
- \`DELETE /api/notes/:id\`: Delete a note

### Decision Support
- \`POST /api/decision-support/differential\`: Generate differential diagnoses
- \`POST /api/decision-support/treatment\`: Generate treatment recommendations

## WebSocket Events

- \`start-transcription\`: Start real-time transcription
- \`transcription-update\`: Real-time transcription updates
- \`update-note\`: Note updates
- \`note-updated\`: Broadcast note updates to clients
EOL

echo -e "${GREEN}"
echo "======================================================"
echo "       DentalAI Assistant Backend Setup Complete      "
echo "======================================================"
echo -e "${NC}"
echo "The backend server has been set up successfully."
echo "You can start the server with:"
echo -e "${YELLOW}cd $BACKEND_DIR && npm run dev${NC}"
