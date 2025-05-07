#!/bin/bash

# Frontend setup script for DentalAI Assistant
# Sets up the React.js frontend application

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
FRONTEND_DIR="$PROJECT_DIR/frontend"

echo -e "${BLUE}"
echo "======================================================"
echo "         DentalAI Assistant Frontend Setup            "
echo "======================================================"
echo -e "${NC}"

# Navigate to frontend directory
cd "$FRONTEND_DIR"

# Initialize React application using create-react-app
echo -e "${GREEN}Creating React application...${NC}"
npx create-react-app . --template typescript

# Clean up default files
echo -e "${GREEN}Cleaning up default files...${NC}"
rm src/App.css
rm src/App.test.tsx
rm src/logo.svg
rm public/logo192.png
rm public/logo512.png
rm public/manifest.json
rm public/robots.txt

# Update package.json with additional dependencies
echo -e "${GREEN}Updating package.json...${NC}"
cat > package.json << EOL
{
  "name": "dental-ai-assistant-frontend",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    "@material-ui/core": "^4.12.4",
    "@material-ui/icons": "^4.11.3",
    "@material-ui/lab": "^4.0.0-alpha.61",
    "@testing-library/jest-dom": "^5.16.4",
    "@testing-library/react": "^13.3.0",
    "@testing-library/user-event": "^13.5.0",
    "@types/jest": "^27.5.2",
    "@types/node": "^16.11.41",
    "@types/react": "^18.0.14",
    "@types/react-dom": "^18.0.5",
    "axios": "^0.27.2",
    "chart.js": "^3.8.0",
    "date-fns": "^2.28.0",
    "formik": "^2.2.9",
    "jwt-decode": "^3.1.2",
    "react": "^18.2.0",
    "react-chartjs-2": "^4.2.0",
    "react-dom": "^18.2.0",
    "react-error-boundary": "^3.1.4",
    "react-router-dom": "^6.3.0",
    "react-scripts": "5.0.1",
    "react-toastify": "^9.0.5",
    "socket.io-client": "^4.5.1",
    "typescript": "^4.7.4",
    "web-vitals": "^2.1.4",
    "yup": "^0.32.11"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject",
    "lint": "eslint --ext .js,.jsx,.ts,.tsx src/",
    "format": "prettier --write 'src/**/*.{js,jsx,ts,tsx,json,css,scss,md}'"
  },
  "eslintConfig": {
    "extends": [
      "react-app",
      "react-app/jest"
    ]
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  },
  "devDependencies": {
    "@typescript-eslint/eslint-plugin": "^5.29.0",
    "@typescript-eslint/parser": "^5.29.0",
    "eslint": "^8.18.0",
    "eslint-config-prettier": "^8.5.0",
    "eslint-plugin-prettier": "^4.0.0",
    "eslint-plugin-react": "^7.30.0",
    "prettier": "^2.7.1"
  }
}
EOL

# Install dependencies
echo -e "${GREEN}Installing dependencies...${NC}"
npm install

# Create environment files
echo -e "${GREEN}Creating environment files...${NC}"
cat > .env << EOL
REACT_APP_API_URL=http://localhost:3000/api
REACT_APP_SOCKET_URL=http://localhost:3000
EOL

cat > .env.production << EOL
REACT_APP_API_URL=/api
REACT_APP_SOCKET_URL=/
EOL

# Update public/index.html
echo -e "${GREEN}Updating index.html...${NC}"
cat > public/index.html << EOL
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <link rel="icon" href="%PUBLIC_URL%/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#000000" />
    <meta
      name="description"
      content="DentalAI Assistant - AI-powered dental scribe and clinical decision support"
    />
    <link rel="apple-touch-icon" href="%PUBLIC_URL%/favicon.ico" />
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap" rel="stylesheet">
    <title>DentalAI Assistant</title>
  </head>
  <body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
  </body>
</html>
EOL

# Create folder structure
echo -e "${GREEN}Creating folder structure...${NC}"
mkdir -p src/components/common
mkdir -p src/components/auth
mkdir -p src/components/dashboard
mkdir -p src/components/patients
mkdir -p src/components/transcription
mkdir -p src/components/notes
mkdir -p src/components/decision-support
mkdir -p src/pages
mkdir -p src/services
mkdir -p src/utils
mkdir -p src/contexts
mkdir -p src/hooks
mkdir -p src/types
mkdir -p src/assets/images

# Create basic TypeScript types
echo -e "${GREEN}Creating TypeScript types...${NC}"
cat > src/types/index.ts << EOL
// User types
export interface User {
  _id: string;
  name: string;
  email: string;
  role: 'dentist' | 'assistant' | 'admin';
  practice?: string;
  isAdmin: boolean;
}

export interface AuthState {
  isAuthenticated: boolean;
  user: User | null;
  loading: boolean;
  error: string | null;
}

// Patient types
export interface Patient {
  _id: string;
  firstName: string;
  lastName: string;
  dateOfBirth: string;
  gender: 'male' | 'female' | 'other' | 'prefer not to say';
  email?: string;
  phone?: string;
  address?: {
    street?: string;
    city?: string;
    state?: string;
    zipCode?: string;
    country?: string;
  };
  insuranceInfo?: {
    provider?: string;
    policyNumber?: string;
    groupNumber?: string;
    primary?: boolean;
  };
  medicalHistory?: {
    allergies?: string[];
    medications?: string[];
    conditions?: string[];
    surgeries?: string[];
    familyHistory?: string[];
  };
  dentalHistory?: {
    lastVisit?: string;
    treatments?: string[];
    notes?: string;
  };
  practice: string;
  createdBy: string;
  createdAt: string;
}

// Note types
export interface Note {
  _id: string;
  patient: string | Patient;
  appointment?: string;
  provider: string | User;
  noteType: 'SOAP' | 'procedure' | 'followUp' | 'other';
  content: {
    subjective?: string;
    objective?: string;
    assessment?: string;
    plan?: string;
    additionalNotes?: string;
    rawTranscript?: string;
  };
  diagnosisCodes?: Array<{
    code: string;
    description: string;
  }>;
  procedureCodes?: Array<{
    code: string;
    description: string;
  }>;
  createdAt: string;
  updatedAt: string;
  status: 'draft' | 'finalized' | 'signed';
  isDeleted: boolean;
}

// Transcription types
export interface TranscriptionRequest {
  audioData: Blob;
  patientId?: string;
}

export interface TranscriptionResponse {
  text: string;
}

export interface ProcessedNote {
  rawTranscript: string;
  structuredNote: {
    subjective: string;
    objective: string;
    assessment: string;
    plan: string;
    cdtCodes: Array<{
      code: string;
      description: string;
    }>;
  };
}

// Differential diagnosis types
export interface Diagnosis {
  name: string;
  likelihood: 'High' | 'Moderate' | 'Low';
  supportingEvidence: string;
  diagnosticTests: string;
  treatmentConsiderations: string;
}

export interface DifferentialDiagnosisRequest {
  symptoms: string;
  findings: string;
}

export interface DifferentialDiagnosisResponse {
  diagnoses: Diagnosis[];
}

// Treatment recommendation types
export interface Treatment {
  name: string;
  description: string;
  cdtCodes?: Array<{
    code: string;
    description: string;
    score?: number;
  }>;
}

export interface TreatmentRecommendation {
  treatments: Treatment[];
  preventiveMeasures: string[];
}

export interface TreatmentRecommendationRequest {
  diagnosis: string;
}

export interface TreatmentRecommendationResponse {
  recommendations: TreatmentRecommendation;
}

// Error types
export interface ApiError {
  message: string;
  stack?: string;
}
EOL

# Create API service
echo -e "${GREEN}Creating API service...${NC}"
cat > src/services/api.ts << EOL
import axios from 'axios';

// Create axios instance with defaults
const api = axios.create({
  baseURL: process.env.REACT_APP_API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add request interceptor to include auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = \`Bearer \${token}\`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Add response interceptor to handle auth errors
api.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    if (error.response && error.response.status === 401) {
      // Clear local storage and redirect to login
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api;
EOL

# Create auth service
cat > src/services/authService.ts << EOL
import api from './api';
import jwt_decode from 'jwt-decode';
import { User } from '../types';

interface LoginData {
  email: string;
  password: string;
}

interface RegisterData {
  name: string;
  email: string;
  password: string;
  role?: string;
}

interface AuthResponse {
  token: string;
  user: User;
}

// Login user
export const login = async (data: LoginData): Promise<User> => {
  const response = await api.post<AuthResponse>('/auth/login', data);
  
  // Save token to local storage
  localStorage.setItem('token', response.data.token);
  
  return response.data.user;
};

// Register user
export const register = async (data: RegisterData): Promise<User> => {
  const response = await api.post<AuthResponse>('/auth/register', data);
  
  // Save token to local storage
  localStorage.setItem('token', response.data.token);
  
  return response.data.user;
};

// Logout user
export const logout = (): void => {
  localStorage.removeItem('token');
};

// Get current user
export const getCurrentUser = async (): Promise<User | null> => {
  try {
    const response = await api.get<User>('/auth/me');
    return response.data;
  } catch (error) {
    return null;
  }
};

// Check if user is authenticated
export const isAuthenticated = (): boolean => {
  const token = localStorage.getItem('token');
  
  if (!token) {
    return false;
  }
  
  try {
    // Check token expiration
    const decoded: any = jwt_decode(token);
    const currentTime = Date.now() / 1000;
    
    return decoded.exp > currentTime;
  } catch (error) {
    return false;
  }
};
EOL

# Create patient service
cat > src/services/patientService.ts << EOL
import api from './api';
import { Patient } from '../types';

// Get all patients
export const getPatients = async (): Promise<Patient[]> => {
  const response = await api.get<Patient[]>('/patients');
  return response.data;
};

// Get patient by ID
export const getPatientById = async (id: string): Promise<Patient> => {
  const response = await api.get<Patient>(\`/patients/\${id}\`);
  return response.data;
};

// Create new patient
export const createPatient = async (patient: Omit<Patient, '_id' | 'createdBy' | 'createdAt'>): Promise<Patient> => {
  const response = await api.post<Patient>('/patients', patient);
  return response.data;
};

// Update patient
export const updatePatient = async (id: string, patient: Partial<Patient>): Promise<Patient> => {
  const response = await api.put<Patient>(\`/patients/\${id}\`, patient);
  return response.data;
};

// Delete patient
export const deletePatient = async (id: string): Promise<void> => {
  await api.delete(\`/patients/\${id}\`);
};

// Search patients
export const searchPatients = async (query: string): Promise<Patient[]> => {
  const response = await api.get<Patient[]>(\`/patients/search?q=\${query}\`);
  return response.data;
};
EOL

# Create transcription service
cat > src/services/transcriptionService.ts << EOL
import api from './api';
import { TranscriptionResponse, ProcessedNote } from '../types';

// Transcribe audio
export const transcribeAudio = async (audioBlob: Blob): Promise<string> => {
  // Create form data
  const formData = new FormData();
  formData.append('audio', audioBlob);
  
  const response = await api.post<TranscriptionResponse>('/transcription', formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });
  
  return response.data.text;
};

// Process transcription
export const processTranscription = async (transcription: string, patientId?: string): Promise<ProcessedNote> => {
  const response = await api.post<ProcessedNote>('/transcription/process', {
    transcription,
    patientId,
  });
  
  return response.data;
};
EOL

# Create notes service
cat > src/services/noteService.ts << EOL
import api from './api';
import { Note, ProcessedNote } from '../types';

// Get all notes
export const getNotes = async (patientId?: string): Promise<Note[]> => {
  const url = patientId ? \`/notes?patientId=\${patientId}\` : '/notes';
  const response = await api.get<Note[]>(url);
  return response.data;
};

// Get note by ID
export const getNoteById = async (id: string): Promise<Note> => {
  const response = await api.get<Note>(\`/notes/\${id}\`);
  return response.data;
};

// Create note from processed transcription
export const createNoteFromTranscription = async (
  patientId: string,
  processedNote: ProcessedNote
): Promise<Note> => {
  const noteData = {
    patient: patientId,
    noteType: 'SOAP',
    content: {
      subjective: processedNote.structuredNote.subjective,
      objective: processedNote.structuredNote.objective,
      assessment: processedNote.structuredNote.assessment,
      plan: processedNote.structuredNote.plan,
      rawTranscript: processedNote.rawTranscript
    },
    procedureCodes: processedNote.structuredNote.cdtCodes.map(code => ({
      code: code.code,
      description: code.description
    }))
  };
  
  const response = await api.post<Note>('/notes', noteData);
  return response.data;
};

// Update note
export const updateNote = async (id: string, note: Partial<Note>): Promise<Note> => {
  const response = await api.put<Note>(\`/notes/\${id}\`, note);
  return response.data;
};

// Delete note
export const deleteNote = async (id: string): Promise<void> => {
  await api.delete(\`/notes/\${id}\`);
};

// Finalize note
export const finalizeNote = async (id: string): Promise<Note> => {
  const response = await api.put<Note>(\`/notes/\${id}/finalize\`, {});
  return response.data;
};

// Sign note
export const signNote = async (id: string): Promise<Note> => {
  const response = await api.put<Note>(\`/notes/\${id}/sign\`, {});
  return response.data;
};
EOL

# Create decision support service
cat > src/services/decisionSupportService.ts << EOL
import api from './api';
import { DifferentialDiagnosisRequest, DifferentialDiagnosisResponse, TreatmentRecommendationRequest, TreatmentRecommendationResponse } from '../types';

// Generate differential diagnoses
export const generateDifferentialDiagnoses = async (
  symptoms: string,
  findings: string
): Promise<DifferentialDiagnosisResponse> => {
  const request: DifferentialDiagnosisRequest = {
    symptoms,
    findings
  };
  
  const response = await api.post<DifferentialDiagnosisResponse>(
    '/decision-support/differential',
    request
  );
  
  return response.data;
};

// Get treatment recommendations
export const getTreatmentRecommendations = async (
  diagnosis: string
): Promise<TreatmentRecommendationResponse> => {
  const request: TreatmentRecommendationRequest = {
    diagnosis
  };
  
  const response = await api.post<TreatmentRecommendationResponse>(
    '/decision-support/treatment',
    request
  );
  
  return response.data;
};
EOL

# Create socket service
cat > src/services/socketService.ts << EOL
import { io, Socket } from 'socket.io-client';

let socket: Socket | null = null;

// Initialize socket connection
export const initSocket = (): Socket => {
  if (!socket) {
    socket = io(process.env.REACT_APP_SOCKET_URL || 'http://localhost:3000', {
      auth: {
        token: localStorage.getItem('token')
      }
    });
    
    // Setup reconnection logic
    socket.on('disconnect', () => {
      console.log('Socket disconnected');
    });
    
    socket.on('connect', () => {
      console.log('Socket connected');
    });
  }
  
  return socket;
};

// Get socket instance
export const getSocket = (): Socket | null => {
  return socket;
};

// Close socket connection
export const closeSocket = (): void => {
  if (socket) {
    socket.disconnect();
    socket = null;
  }
};
EOL

# Create auth context
echo -e "${GREEN}Creating authentication context...${NC}"
cat > src/contexts/AuthContext.tsx << EOL
import React, { createContext, useContext, useEffect, useState } from 'react';
import { AuthState, User } from '../types';
import * as authService from '../services/authService';

interface AuthContextValue extends AuthState {
  login: (email: string, password: string) => Promise<void>;
  register: (name: string, email: string, password: string) => Promise<void>;
  logout: () => void;
}

const initialState: AuthState = {
  isAuthenticated: false,
  user: null,
  loading: true,
  error: null
};

const AuthContext = createContext<AuthContextValue>({
  ...initialState,
  login: async () => {},
  register: async () => {},
  logout: () => {}
});

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [state, setState] = useState<AuthState>(initialState);

  // Check if user is authenticated on app load
  useEffect(() => {
    const loadUser = async () => {
      if (authService.isAuthenticated()) {
        try {
          const user = await authService.getCurrentUser();
          setState({
            isAuthenticated: true,
            user,
            loading: false,
            error: null
          });
        } catch (error) {
          setState({
            isAuthenticated: false,
            user: null,
            loading: false,
            error: 'Failed to load user'
          });
        }
      } else {
        setState({
          isAuthenticated: false,
          user: null,
          loading: false,
          error: null
        });
      }
    };

    loadUser();
  }, []);

  // Login
  const login = async (email: string, password: string) => {
    try {
      setState({ ...state, loading: true, error: null });
      const user = await authService.login({ email, password });
      setState({
        isAuthenticated: true,
        user,
        loading: false,
        error: null
      });
    } catch (error: any) {
      setState({
        ...state,
        loading: false,
        error: error.response?.data?.message || 'Login failed'
      });
      throw error;
    }
  };

  // Register
  const register = async (name: string, email: string, password: string) => {
    try {
      setState({ ...state, loading: true, error: null });
      const user = await authService.register({ name, email, password });
      setState({
        isAuthenticated: true,
        user,
        loading: false,
        error: null
      });
    } catch (error: any) {
      setState({
        ...state,
        loading: false,
        error: error.response?.data?.message || 'Registration failed'
      });
      throw error;
    }
  };

  // Logout
  const logout = () => {
    authService.logout();
    setState({
      isAuthenticated: false,
      user: null,
      loading: false,
      error: null
    });
  };

  return (
    <AuthContext.Provider
      value={{
        ...state,
        login,
        register,
        logout
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

// Custom hook to use auth context
export const useAuth = () => useContext(AuthContext);
EOL

# Create App component
echo -e "${GREEN}Creating main App component...${NC}"
cat > src/App.tsx << EOL
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@material-ui/core/styles';
import CssBaseline from '@material-ui/core/CssBaseline';
import { ErrorBoundary } from 'react-error-boundary';
import { ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

// Context providers
import { AuthProvider, useAuth } from './contexts/AuthContext';

// Pages (to be implemented)
import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import DashboardPage from './pages/DashboardPage';
import PatientsPage from './pages/PatientsPage';
import PatientDetailPage from './pages/PatientDetailPage';
import TranscriptionPage from './pages/TranscriptionPage';
import NotesPage from './pages/NotesPage';
import NoteDetailPage from './pages/NoteDetailPage';
import ErrorFallback from './components/common/ErrorFallback';

// Create theme
const theme = createTheme({
  palette: {
    primary: {
      main: '#2196f3',
    },
    secondary: {
      main: '#f50057',
    },
    background: {
      default: '#f5f5f5',
    },
  },
  typography: {
    fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
  },
});

// Protected route component
const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated, loading } = useAuth();

  if (loading) {
    return <div>Loading...</div>;
  }

  return isAuthenticated ? <>{children}</> : <Navigate to="/login" />;
};

const App: React.FC = () => {
  return (
    <ErrorBoundary FallbackComponent={ErrorFallback}>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <ToastContainer />
        <AuthProvider>
          <Router>
            <Routes>
              {/* Public routes */}
              <Route path="/login" element={<LoginPage />} />
              <Route path="/register" element={<RegisterPage />} />
              
              {/* Protected routes */}
              <Route 
                path="/" 
                element={
                  <ProtectedRoute>
                    <DashboardPage />
                  </ProtectedRoute>
                } 
              />
              <Route 
                path="/patients" 
                element={
                  <ProtectedRoute>
                    <PatientsPage />
                  </ProtectedRoute>
                } 
              />
              <Route 
                path="/patients/:id" 
                element={
                  <ProtectedRoute>
                    <PatientDetailPage />
                  </ProtectedRoute>
                } 
              />
              <Route 
                path="/transcription" 
                element={
                  <ProtectedRoute>
                    <TranscriptionPage />
                  </ProtectedRoute>
                } 
              />
              <Route 
                path="/notes" 
                element={
                  <ProtectedRoute>
                    <NotesPage />
                  </ProtectedRoute>
                } 
              />
              <Route 
                path="/notes/:id" 
                element={
                  <ProtectedRoute>
                    <NoteDetailPage />
                  </ProtectedRoute>
                } 
              />
              
              {/* Catch-all route */}
              <Route path="*" element={<Navigate to="/" />} />
            </Routes>
          </Router>
        </AuthProvider>
      </ThemeProvider>
    </ErrorBoundary>
  );
};

export default App;
EOL

# Create index.tsx
echo -e "${GREEN}Updating index.tsx...${NC}"
cat > src/index.tsx << EOL
import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';
import reportWebVitals from './reportWebVitals';

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();
EOL

# Create basic CSS
echo -e "${GREEN}Creating basic styles...${NC}"
cat > src/index.css << EOL
body {
  margin: 0;
  font-family: 'Roboto', 'Helvetica', 'Arial', sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  background-color: #f5f5f5;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}
EOL

# Create placeholder components
echo -e "${GREEN}Creating placeholder components...${NC}"

# Common components
cat > src/components/common/ErrorFallback.tsx << EOL
import React from 'react';
import { Button, Typography, Container, Paper, Box } from '@material-ui/core';
import { FallbackProps } from 'react-error-boundary';

const ErrorFallback: React.FC<FallbackProps> = ({ error, resetErrorBoundary }) => {
  return (
    <Container maxWidth="sm">
      <Paper elevation={3} style={{ padding: '2rem', marginTop: '2rem' }}>
        <Typography variant="h5" color="error" gutterBottom>
          Something went wrong
        </Typography>
        <Typography variant="body1" paragraph>
          {error.message}
        </Typography>
        <Box display="flex" justifyContent="center">
          <Button
            variant="contained"
            color="primary"
            onClick={resetErrorBoundary}
          >
            Try again
          </Button>
        </Box>
      </Paper>
    </Container>
  );
};

export default ErrorFallback;
EOL

# Create placeholder pages
echo -e "${GREEN}Creating placeholder pages...${NC}"

# Login page
mkdir -p src/pages
cat > src/pages/LoginPage.tsx << EOL
import React, { useState } from 'react';
import { useNavigate, Link as RouterLink } from 'react-router-dom';
import { Container, Typography, TextField, Button, Paper, Box, Link, CircularProgress } from '@material-ui/core';
import { useAuth } from '../contexts/AuthContext';
import { toast } from 'react-toastify';

const LoginPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const { login, loading, error } = useAuth();
  const navigate = useNavigate();
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      await login(email, password);
      toast.success('Login successful!');
      navigate('/');
    } catch (err) {
      // Error is handled by the auth context
      toast.error('Login failed. Please check your credentials.');
    }
  };
  
  return (
    <Container maxWidth="xs">
      <Box
        display="flex"
        flexDirection="column"
        alignItems="center"
        justifyContent="center"
        minHeight="100vh"
      >
        <Paper elevation={3} style={{ padding: '2rem', width: '100%' }}>
          <Typography variant="h4" component="h1" align="center" gutterBottom>
            DentalAI Assistant
          </Typography>
          <Typography variant="h5" component="h2" align="center" gutterBottom>
            Login
          </Typography>
          
          {error && (
            <Typography color="error" align="center" paragraph>
              {error}
            </Typography>
          )}
          
          <form onSubmit={handleSubmit}>
            <TextField
              variant="outlined"
              margin="normal"
              required
              fullWidth
              id="email"
              label="Email Address"
              name="email"
              autoComplete="email"
              autoFocus
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
            <TextField
              variant="outlined"
              margin="normal"
              required
              fullWidth
              name="password"
              label="Password"
              type="password"
              id="password"
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
            <Button
              type="submit"
              fullWidth
              variant="contained"
              color="primary"
              disabled={loading}
              style={{ marginTop: '1rem' }}
            >
              {loading ? <CircularProgress size={24} /> : 'Login'}
            </Button>
          </form>
          
          <Box mt={2} textAlign="center">
            <Typography variant="body2">
              Don't have an account?{' '}
              <Link component={RouterLink} to="/register">
                Register
              </Link>
            </Typography>
          </Box>
        </Paper>
      </Box>
    </Container>
  );
};

export default LoginPage;
EOL

# Create a basic README file
echo -e "${GREEN}Creating README.md...${NC}"
cat > README.md << EOL
# DentalAI Assistant - Frontend

This is the frontend application for the DentalAI Assistant project, an AI-powered dental scribe and clinical decision support system.

## Features

- Real-time speech-to-text transcription
- AI-generated clinical notes
- Patient management
- Clinical decision support with differential diagnoses
- Treatment recommendations

## Getting Started

### Prerequisites

- Node.js (v14+)
- npm or yarn

### Installation

1. Clone the repository
2. Install dependencies:
   \`\`\`
   npm install
   \`\`\`
3. Start the development server:
   \`\`\`
   npm start
   \`\`\`

## Available Scripts

- \`npm start\`: Run the development server
- \`npm build\`: Build the production version
- \`npm test\`: Run the test suite
- \`npm lint\`: Lint the code

## Folder Structure

- \`/src/components\`: Reusable React components
- \`/src/pages\`: Page components
- \`/src/services\`: API service functions
- \`/src/contexts\`: React context providers
- \`/src/hooks\`: Custom React hooks
- \`/src/utils\`: Utility functions
- \`/src/types\`: TypeScript type definitions
- \`/src/assets\`: Static assets like images

## Environmental Variables

- \`REACT_APP_API_URL\`: URL for the backend API
- \`REACT_APP_SOCKET_URL\`: URL for WebSocket connections
EOL

echo -e "${GREEN}"
echo "======================================================"
echo "      DentalAI Assistant Frontend Setup Complete      "
echo "======================================================"
echo -e "${NC}"
echo "The frontend application has been set up successfully."
echo "You can start the development server with:"
echo -e "${YELLOW}cd $FRONTEND_DIR && npm start${NC}"
