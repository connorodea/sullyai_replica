#!/bin/bash

# AI Services setup script for DentalAI Assistant
# Configures connections to OpenAI, Anthropic and other AI services

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
AI_DIR="$BACKEND_DIR/src/ai"

echo -e "${BLUE}"
echo "======================================================"
echo "         DentalAI Assistant AI Services Setup         "
echo "======================================================"
echo -e "${NC}"

# Navigate to AI directory
cd "$AI_DIR"

# Create AI service files
echo -e "${GREEN}Creating AI service files...${NC}"

# Create OpenAI service
cat > openaiService.js << EOL
const { Configuration, OpenAIApi } = require('openai');
const logger = require('../utils/logger');

// Initialize OpenAI configuration
const configuration = new Configuration({
  apiKey: process.env.OPENAI_API_KEY,
});
const openai = new OpenAIApi(configuration);

/**
 * Transcribe audio to text using OpenAI Whisper
 * @param {Buffer} audioBuffer - Audio data buffer
 * @param {Object} options - Transcription options
 * @returns {Promise<string>} - Transcribed text
 */
const transcribeAudio = async (audioBuffer, options = {}) => {
  try {
    // Ensure we have an API key
    if (!process.env.OPENAI_API_KEY) {
      throw new Error('OpenAI API key is not configured');
    }

    const defaultOptions = {
      model: 'whisper-1',
      language: 'en',
      temperature: 0,
      responseFormat: 'json'
    };

    const transcriptionOptions = { ...defaultOptions, ...options };
    
    // Create form data for the API request
    const formData = new FormData();
    formData.append('file', new Blob([audioBuffer], { type: 'audio/webm' }));
    formData.append('model', transcriptionOptions.model);
    
    if (transcriptionOptions.language) {
      formData.append('language', transcriptionOptions.language);
    }
    
    formData.append('temperature', transcriptionOptions.temperature.toString());
    formData.append('response_format', transcriptionOptions.responseFormat);

    // Call OpenAI Whisper API
    const response = await fetch('https://api.openai.com/v1/audio/transcriptions', {
      method: 'POST',
      headers: {
        'Authorization': \`Bearer \${process.env.OPENAI_API_KEY}\`
      },
      body: formData
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(\`Whisper API error: \${error.error?.message || 'Unknown error'}\`);
    }

    const result = await response.json();
    return result.text;
  } catch (error) {
    logger.error('Transcription error:', error);
    throw new Error(\`Failed to transcribe audio: \${error.message}\`);
  }
};

/**
 * Generate dental-specific clinical notes from transcription
 * @param {string} transcript - Transcribed text
 * @param {Object} patientContext - Patient context for better note generation
 * @returns {Promise<Object>} - Structured clinical note
 */
const generateClinicalNotes = async (transcript, patientContext = {}) => {
  try {
    // Create a prompt with dental context
    const systemPrompt = \`
You are an expert dental scribe AI assistant. Your task is to convert conversations between dentists and patients 
into structured, accurate clinical notes following standard dental documentation practices.
Generate comprehensive dental SOAP notes including subjective complaints, objective findings, 
assessment/diagnosis, and treatment plan.

Important considerations:
1. Use standard dental terminology and notation
2. Include all relevant clinical information
3. Structure the note clearly with appropriate sections
4. Identify relevant CDT (dental procedure) codes for billing
5. Be concise but thorough
\`;

    const userPrompt = \`
Patient Information:
Name: \${patientContext.firstName || ''} \${patientContext.lastName || ''}
DOB: \${patientContext.dateOfBirth || ''}
Medical History: \${patientContext.medicalHistory || 'Not provided'}
Dental History: \${patientContext.dentalHistory || 'Not provided'}

Transcript of dental appointment:
\${transcript}

Please generate a complete SOAP note with the following sections:
1. Subjective: Patient's chief complaint, symptoms, and relevant history
2. Objective: Clinical examination findings, including dental charting observations if mentioned
3. Assessment: Diagnosis or differential diagnoses with supporting evidence
4. Plan: Treatment plan, prescriptions, follow-up recommendations
5. CDT Codes: Suggest appropriate dental procedure codes for billing
\`;

    // Call OpenAI API with gpt-4
    const response = await openai.createChatCompletion({
      model: "gpt-4",
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt }
      ],
      temperature: 0.2,
      max_tokens: 1500
    });

    // Process the response into structured format
    const noteText = response.data.choices[0].message.content;
    return parseNoteText(noteText);
  } catch (error) {
    logger.error('Error generating clinical notes:', error);
    throw new Error(\`Failed to generate clinical notes: \${error.message}\`);
  }
};

/**
 * Generate differential diagnoses based on symptoms
 * @param {string} symptoms - Patient symptoms
 * @param {string} findings - Clinical findings
 * @returns {Promise<Array>} - List of differential diagnoses
 */
const generateDifferentialDiagnoses = async (symptoms, findings) => {
  try {
    const systemPrompt = \`
You are an expert dental diagnostician AI. Your task is to analyze patient symptoms and clinical findings
to generate accurate differential diagnoses for dental conditions.
\`;

    const userPrompt = \`
Based on the following patient information, provide a list of potential differential diagnoses ranked by likelihood.
For each diagnosis, include supporting evidence, recommended diagnostic tests, and treatment considerations.

Reported Symptoms: \${symptoms}
Clinical Findings: \${findings}

Format your response as a list of differential diagnoses, each with:
1. Diagnosis name
2. Likelihood (High, Moderate, Low)
3. Supporting evidence from the symptoms/findings
4. Recommended diagnostic tests or procedures
5. Treatment considerations
\`;

    // Call OpenAI API with gpt-4
    const response = await openai.createChatCompletion({
      model: "gpt-4",
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt }
      ],
      temperature: 0.3,
      max_tokens: 1000
    });

    return parseDifferentialDiagnoses(response.data.choices[0].message.content);
  } catch (error) {
    logger.error('Error generating differential diagnoses:', error);
    throw new Error(\`Failed to generate differential diagnoses: \${error.message}\`);
  }
};

/**
 * Generate suggested questions for the dentist based on conversation context
 * @param {string} partialTranscript - Ongoing conversation transcript
 * @returns {Promise<Array>} - List of suggested questions
 */
const generateSuggestedQuestions = async (partialTranscript) => {
  try {
    const systemPrompt = \`
You are an expert dental assistant AI. Your task is to analyze ongoing conversations between dentists and patients
and suggest relevant follow-up questions that the dentist might want to ask based on the conversation context.
\`;

    const userPrompt = \`
Based on the following partial transcript of a dental appointment, suggest 3-5 relevant follow-up questions 
that would be helpful for the dentist to ask. Focus on questions that would help with diagnosis, treatment planning,
or improving patient care.

Partial Transcript:
\${partialTranscript}

Provide just a list of questions without any other text.
\`;

    // Call OpenAI API with gpt-3.5-turbo for faster response
    const response = await openai.createChatCompletion({
      model: "gpt-3.5-turbo",
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt }
      ],
      temperature: 0.4,
      max_tokens: 300
    });

    // Parse the response to get an array of questions
    const content = response.data.choices[0].message.content;
    return content.split('\\n')
      .filter(line => line.trim().length > 0)
      .map(line => line.replace(/^\\d+\\.\\s*/, '').trim());
  } catch (error) {
    logger.error('Error generating suggested questions:', error);
    throw new Error(\`Failed to generate suggested questions: \${error.message}\`);
  }
};

/**
 * Parse the AI-generated note text into a structured format
 * @param {string} noteText - The raw note text from the AI
 * @returns {Object} - Structured note object
 */
const parseNoteText = (noteText) => {
  // Initialize the structured note
  const structuredNote = {
    subjective: '',
    objective: '',
    assessment: '',
    plan: '',
    cdtCodes: []
  };

  // Parse the sections using regex
  const subjectiveMatch = noteText.match(/Subjective:([\\s\\S]*?)(?=Objective:|$)/i);
  const objectiveMatch = noteText.match(/Objective:([\\s\\S]*?)(?=Assessment:|$)/i);
  const assessmentMatch = noteText.match(/Assessment:([\\s\\S]*?)(?=Plan:|$)/i);
  const planMatch = noteText.match(/Plan:([\\s\\S]*?)(?=CDT Codes:|$)/i);
  const cdtCodesMatch = noteText.match(/CDT Codes:([\\s\\S]*?)$/i);

  // Extract the content of each section
  if (subjectiveMatch && subjectiveMatch[1]) {
    structuredNote.subjective = subjectiveMatch[1].trim();
  }
  
  if (objectiveMatch && objectiveMatch[1]) {
    structuredNote.objective = objectiveMatch[1].trim();
  }
  
  if (assessmentMatch && assessmentMatch[1]) {
    structuredNote.assessment = assessmentMatch[1].trim();
  }
  
  if (planMatch && planMatch[1]) {
    structuredNote.plan = planMatch[1].trim();
  }
  
  if (cdtCodesMatch && cdtCodesMatch[1]) {
    // Extract CDT codes using regex
    const codeLines = cdtCodesMatch[1].trim().split('\\n');
    
    codeLines.forEach(line => {
      const codeMatch = line.match(/D\d{4}/);
      if (codeMatch) {
        const code = codeMatch[0];
        const description = line.replace(code, '').replace(/[:-]/, '').trim();
        
        structuredNote.cdtCodes.push({
          code,
          description
        });
      }
    });
  }
  
  return structuredNote;
};

/**
 * Parse the differential diagnoses text into structured format
 * @param {string} diagnosesText - Raw diagnoses text from AI
 * @returns {Array} - Structured array of diagnoses
 */
const parseDifferentialDiagnoses = (diagnosesText) => {
  const diagnoses = [];
  
  // Split the text by numbered diagnoses
  const diagnosisBlocks = diagnosesText.split(/\\d+\\.\\s+/);
  
  // Skip the first empty block if it exists
  const blocks = diagnosisBlocks[0].trim() === '' ? diagnosisBlocks.slice(1) : diagnosisBlocks;
  
  blocks.forEach(block => {
    if (!block.trim()) return;
    
    // Initialize diagnosis object
    const diagnosis = {
      name: '',
      likelihood: '',
      supportingEvidence: '',
      diagnosticTests: '',
      treatmentConsiderations: ''
    };
    
    // Extract diagnosis name (usually the first line)
    const lines = block.split('\\n');
    diagnosis.name = lines[0].trim().replace(/\\(High|Moderate|Low\\)/, '').trim();
    
    // Extract likelihood
    const likelihoodMatch = lines[0].match(/\\((High|Moderate|Low)\\)/);
    if (likelihoodMatch) {
      diagnosis.likelihood = likelihoodMatch[1];
    }
    
    // Extract other fields
    let currentField = '';
    lines.slice(1).forEach(line => {
      line = line.trim();
      
      if (line.match(/supporting evidence/i)) {
        currentField = 'supportingEvidence';
      } else if (line.match(/diagnostic tests/i)) {
        currentField = 'diagnosticTests';
      } else if (line.match(/treatment considerations/i)) {
        currentField = 'treatmentConsiderations';
      } else if (line && currentField) {
        diagnosis[currentField] += line + ' ';
      }
    });
    
    // Trim all fields
    Object.keys(diagnosis).forEach(key => {
      if (typeof diagnosis[key] === 'string') {
        diagnosis[key] = diagnosis[key].trim();
      }
    });
    
    diagnoses.push(diagnosis);
  });
  
  return diagnoses;
};

module.exports = {
  transcribeAudio,
  generateClinicalNotes,
  generateDifferentialDiagnoses,
  generateSuggestedQuestions
};
EOL

# Create Anthropic service
cat > anthropicService.js << EOL
const axios = require('axios');
const logger = require('../utils/logger');

/**
 * Generate clinical notes using Anthropic Claude
 * @param {string} transcript - Transcribed appointment
 * @param {Object} patientContext - Patient information
 * @returns {Promise<Object>} - Structured clinical note
 */
const generateClinicalNotes = async (transcript, patientContext = {}) => {
  try {
    // Ensure we have an API key
    if (!process.env.ANTHROPIC_API_KEY) {
      throw new Error('Anthropic API key is not configured');
    }

    // Create a prompt with dental context
    const systemPrompt = \`
You are Claude, an expert dental scribe AI assistant. Your task is to convert conversations between dentists and patients 
into structured, accurate clinical notes following standard dental documentation practices.
Generate comprehensive dental SOAP notes including subjective complaints, objective findings, 
assessment/diagnosis, and treatment plan.
\`;

    const userPrompt = \`
Patient Information:
Name: \${patientContext.firstName || ''} \${patientContext.lastName || ''}
DOB: \${patientContext.dateOfBirth || ''}
Medical History: \${patientContext.medicalHistory || 'Not provided'}
Dental History: \${patientContext.dentalHistory || 'Not provided'}

Transcript of dental appointment:
\${transcript}

Please generate a complete SOAP note with the following sections:
1. Subjective: Patient's chief complaint, symptoms, and relevant history
2. Objective: Clinical examination findings, including dental charting observations if mentioned
3. Assessment: Diagnosis or differential diagnoses with supporting evidence
4. Plan: Treatment plan, prescriptions, follow-up recommendations
5. CDT Codes: Suggest appropriate dental procedure codes for billing

Format your response with clear section headers.
\`;

    // Call Anthropic Claude API
    const response = await axios.post(
      'https://api.anthropic.com/v1/messages',
      {
        model: 'claude-3-opus-20240229',
        max_tokens: 1500,
        messages: [
          {
            role: 'user',
            content: userPrompt
          }
        ],
        system: systemPrompt
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': process.env.ANTHROPIC_API_KEY,
          'anthropic-version': '2023-06-01'
        }
      }
    );

    // Extract the content from the response
    const noteText = response.data.content[0].text;
    
    // Parse the response into a structured format
    return parseNoteText(noteText);
  } catch (error) {
    logger.error('Error generating clinical notes with Claude:', error);
    throw new Error(\`Failed to generate clinical notes with Claude: \${error.message}\`);
  }
};

/**
 * Generate real-time suggested questions using Claude
 * @param {string} partialTranscript - Current conversation transcript
 * @returns {Promise<Array>} - List of suggested follow-up questions
 */
const generateSuggestedQuestions = async (partialTranscript) => {
  try {
    // Ensure we have an API key
    if (!process.env.ANTHROPIC_API_KEY) {
      throw new Error('Anthropic API key is not configured');
    }

    const systemPrompt = \`
You are an expert dental assistant AI. Your task is to analyze ongoing conversations between dentists and patients
and suggest relevant follow-up questions that the dentist might want to ask based on the conversation context.
\`;

    const userPrompt = \`
Based on the following partial transcript of a dental appointment, suggest 3-5 relevant follow-up questions 
that would be helpful for the dentist to ask. Focus on questions that would help with diagnosis, treatment planning,
or improving patient care.

Partial Transcript:
\${partialTranscript}

Provide a numbered list of questions without any other text.
\`;

    // Call Anthropic Claude API
    const response = await axios.post(
      'https://api.anthropic.com/v1/messages',
      {
        model: 'claude-3-haiku-20240307',  // Using a smaller, faster model for real-time suggestions
        max_tokens: 300,
        messages: [
          {
            role: 'user',
            content: userPrompt
          }
        ],
        system: systemPrompt
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': process.env.ANTHROPIC_API_KEY,
          'anthropic-version': '2023-06-01'
        }
      }
    );

    // Extract the content from the response
    const suggestionsText = response.data.content[0].text;
    
    // Parse into an array of questions
    return suggestionsText.split('\\n')
      .filter(line => line.trim().length > 0)
      .map(line => line.replace(/^\\d+\\.\\s*/, '').trim());
  } catch (error) {
    logger.error('Error generating suggested questions with Claude:', error);
    throw new Error(\`Failed to generate suggested questions with Claude: \${error.message}\`);
  }
};

/**
 * Parse the AI-generated note text into a structured format
 * @param {string} noteText - The raw note text from the AI
 * @returns {Object} - Structured note object
 */
const parseNoteText = (noteText) => {
  // Initialize the structured note
  const structuredNote = {
    subjective: '',
    objective: '',
    assessment: '',
    plan: '',
    cdtCodes: []
  };

  // Parse the sections using regex
  const subjectiveMatch = noteText.match(/Subjective:([\\s\\S]*?)(?=Objective:|$)/i);
  const objectiveMatch = noteText.match(/Objective:([\\s\\S]*?)(?=Assessment:|$)/i);
  const assessmentMatch = noteText.match(/Assessment:([\\s\\S]*?)(?=Plan:|$)/i);
  const planMatch = noteText.match(/Plan:([\\s\\S]*?)(?=CDT Codes:|$)/i);
  const cdtCodesMatch = noteText.match(/CDT Codes:([\\s\\S]*?)$/i);

  // Extract the content of each section
  if (subjectiveMatch && subjectiveMatch[1]) {
    structuredNote.subjective = subjectiveMatch[1].trim();
  }
  
  if (objectiveMatch && objectiveMatch[1]) {
    structuredNote.objective = objectiveMatch[1].trim();
  }
  
  if (assessmentMatch && assessmentMatch[1]) {
    structuredNote.assessment = assessmentMatch[1].trim();
  }
  
  if (planMatch && planMatch[1]) {
    structuredNote.plan = planMatch[1].trim();
  }
  
  if (cdtCodesMatch && cdtCodesMatch[1]) {
    // Extract CDT codes using regex
    const codeLines = cdtCodesMatch[1].trim().split('\\n');
    
    codeLines.forEach(line => {
      const codeMatch = line.match(/D\d{4}/);
      if (codeMatch) {
        const code = codeMatch[0];
        const description = line.replace(code, '').replace(/[:-]/, '').trim();
        
        structuredNote.cdtCodes.push({
          code,
          description
        });
      }
    });
  }
  
  return structuredNote;
};

module.exports = {
  generateClinicalNotes,
  generateSuggestedQuestions
};
EOL

# Create AI service manager
cat > aiServiceManager.js << EOL
const openaiService = require('./openaiService');
const anthropicService = require('./anthropicService');
const logger = require('../utils/logger');

/**
 * AI Service Manager - Handles routing to appropriate AI service
 * and provides fallback mechanisms
 */

// Transcription service with fallback
const transcribeAudio = async (audioBuffer, options = {}) => {
  try {
    // Currently only OpenAI supports audio transcription
    return await openaiService.transcribeAudio(audioBuffer, options);
  } catch (error) {
    logger.error('Transcription error:', error);
    throw new Error(\`Failed to transcribe audio: \${error.message}\`);
  }
};

// Clinical note generation with fallback
const generateClinicalNotes = async (transcript, patientContext = {}) => {
  try {
    // Try with primary service first (based on environment variable)
    const primaryService = process.env.PRIMARY_AI_SERVICE?.toLowerCase() || 'openai';
    
    if (primaryService === 'anthropic' && process.env.ANTHROPIC_API_KEY) {
      try {
        return await anthropicService.generateClinicalNotes(transcript, patientContext);
      } catch (error) {
        logger.warn('Anthropic clinical notes generation failed, falling back to OpenAI:', error.message);
        return await openaiService.generateClinicalNotes(transcript, patientContext);
      }
    } else {
      try {
        return await openaiService.generateClinicalNotes(transcript, patientContext);
      } catch (error) {
        if (process.env.ANTHROPIC_API_KEY) {
          logger.warn('OpenAI clinical notes generation failed, falling back to Anthropic:', error.message);
          return await anthropicService.generateClinicalNotes(transcript, patientContext);
        }
        throw error;
      }
    }
  } catch (error) {
    logger.error('Clinical notes generation error:', error);
    throw new Error(\`Failed to generate clinical notes: \${error.message}\`);
  }
};

// Generate differential diagnoses
const generateDifferentialDiagnoses = async (symptoms, findings) => {
  try {
    // Currently only supported by OpenAI
    return await openaiService.generateDifferentialDiagnoses(symptoms, findings);
  } catch (error) {
    logger.error('Differential diagnoses generation error:', error);
    throw new Error(\`Failed to generate differential diagnoses: \${error.message}\`);
  }
};

// Generate suggested questions with fallback
const generateSuggestedQuestions = async (partialTranscript) => {
  try {
    // Try with primary service first (based on environment variable)
    const primaryService = process.env.PRIMARY_AI_SERVICE?.toLowerCase() || 'openai';
    
    if (primaryService === 'anthropic' && process.env.ANTHROPIC_API_KEY) {
      try {
        return await anthropicService.generateSuggestedQuestions(partialTranscript);
      } catch (error) {
        logger.warn('Anthropic suggested questions generation failed, falling back to OpenAI:', error.message);
        return await openaiService.generateSuggestedQuestions(partialTranscript);
      }
    } else {
      try {
        return await openaiService.generateSuggestedQuestions(partialTranscript);
      } catch (error) {
        if (process.env.ANTHROPIC_API_KEY) {
          logger.warn('OpenAI suggested questions generation failed, falling back to Anthropic:', error.message);
          return await anthropicService.generateSuggestedQuestions(partialTranscript);
        }
        throw error;
      }
    }
  } catch (error) {
    logger.error('Suggested questions generation error:', error);
    throw new Error(\`Failed to generate suggested questions: \${error.message}\`);
  }
};

module.exports = {
  transcribeAudio,
  generateClinicalNotes,
  generateDifferentialDiagnoses,
  generateSuggestedQuestions
};
EOL

# Create dental terminology data
mkdir -p "$AI_DIR/data"

cat > "$AI_DIR/data/dentalTerminology.js" << EOL
/**
 * Dental terminology and CDT codes for reference and model enhancement
 */

// Common dental terms and abbreviations
const dentalTerminology = {
  // Tooth numbering systems
  toothNumberingSystems: {
    universal: {
      description: "Universal/National System (US)",
      mapping: {
        1: "Third molar (upper right)",
        2: "Second molar (upper right)",
        3: "First molar (upper right)",
        4: "Second premolar (upper right)",
        5: "First premolar (upper right)",
        6: "Canine (upper right)",
        7: "Lateral incisor (upper right)",
        8: "Central incisor (upper right)",
        9: "Central incisor (upper left)",
        10: "Lateral incisor (upper left)",
        11: "Canine (upper left)",
        12: "First premolar (upper left)",
        13: "Second premolar (upper left)",
        14: "First molar (upper left)",
        15: "Second molar (upper left)",
        16: "Third molar (upper left)",
        17: "Third molar (lower left)",
        18: "Second molar (lower left)",
        19: "First molar (lower left)",
        20: "Second premolar (lower left)",
        21: "First premolar (lower left)",
        22: "Canine (lower left)",
        23: "Lateral incisor (lower left)",
        24: "Central incisor (lower left)",
        25: "Central incisor (lower right)",
        26: "Lateral incisor (lower right)",
        27: "Canine (lower right)",
        28: "First premolar (lower right)",
        29: "Second premolar (lower right)",
        30: "First molar (lower right)",
        31: "Second molar (lower right)",
        32: "Third molar (lower right)",
        // Primary dentition (letters)
        A: "Second molar (upper right primary)",
        B: "First molar (upper right primary)",
        C: "Canine (upper right primary)",
        D: "Lateral incisor (upper right primary)",
        E: "Central incisor (upper right primary)",
        F: "Central incisor (upper left primary)",
        G: "Lateral incisor (upper left primary)",
        H: "Canine (upper left primary)",
        I: "First molar (upper left primary)",
        J: "Second molar (upper left primary)",
        K: "Second molar (lower left primary)",
        L: "First molar (lower left primary)",
        M: "Canine (lower left primary)",
        N: "Lateral incisor (lower left primary)",
        O: "Central incisor (lower left primary)",
        P: "Central incisor (lower right primary)",
        Q: "Lateral incisor (lower right primary)",
        R: "Canine (lower right primary)",
        S: "First molar (lower right primary)",
        T: "Second molar (lower right primary)"
      }
    },
    fdi: {
      description: "FDI/ISO System (International)",
      mapping: {
        // Upper right (Quadrant 1)
        18: "Third molar (upper right)",
        17: "Second molar (upper right)",
        16: "First molar (upper right)",
        15: "Second premolar (upper right)",
        14: "First premolar (upper right)",
        13: "Canine (upper right)",
        12: "Lateral incisor (upper right)",
        11: "Central incisor (upper right)",
        // Upper left (Quadrant 2)
        21: "Central incisor (upper left)",
        22: "Lateral incisor (upper left)",
        23: "Canine (upper left)",
        24: "First premolar (upper left)",
        25: "Second premolar (upper left)",
        26: "First molar (upper left)",
        27: "Second molar (upper left)",
        28: "Third molar (upper left)",
        // Lower left (Quadrant 3)
        38: "Third molar (lower left)",
        37: "Second molar (lower left)",
        36: "First molar (lower left)",
        35: "Second premolar (lower left)",
        34: "First premolar (lower left)",
        33: "Canine (lower left)",
        32: "Lateral incisor (lower left)",
        31: "Central incisor (lower left)",
        // Lower right (Quadrant 4)
        41: "Central incisor (lower right)",
        42: "Lateral incisor (lower right)",
        43: "Canine (lower right)",
        44: "First premolar (lower right)",
        45: "Second premolar (lower right)",
        46: "First molar (lower right)",
        47: "Second molar (lower right)",
        48: "Third molar (lower right)",
        // Primary dentition
        // Upper right (Quadrant 5)
        55: "Second molar (upper right primary)",
        54: "First molar (upper right primary)",
        53: "Canine (upper right primary)",
        52: "Lateral incisor (upper right primary)",
        51: "Central incisor (upper right primary)",
        // Upper left (Quadrant 6)
        61: "Central incisor (upper left primary)",
        62: "Lateral incisor (upper left primary)",
        63: "Canine (upper left primary)",
        64: "First molar (upper left primary)",
        65: "Second molar (upper left primary)",
        // Lower left (Quadrant 7)
        75: "Second molar (lower left primary)",
        74: "First molar (lower left primary)",
        73: "Canine (lower left primary)",
        72: "Lateral incisor (lower left primary)",
        71: "Central incisor (lower left primary)",
        // Lower right (Quadrant 8)
        81: "Central incisor (lower right primary)",
        82: "Lateral incisor (lower right primary)",
        83: "Canine (lower right primary)",
        84: "First molar (lower right primary)",
        85: "Second molar (lower right primary)"
      }
    }
  },
  
  // Common dental abbreviations
  abbreviations: {
    BW: "Bitewing radiograph",
    PA: "Periapical radiograph",
    FMX: "Full mouth x-rays",
    PFM: "Porcelain fused to metal",
    FPD: "Fixed partial denture",
    RPD: "Removable partial denture",
    RCT: "Root canal treatment",
    BOP: "Bleeding on probing",
    CAL: "Clinical attachment level",
    PD: "Probing depth",
    OP: "Occlusal plane",
    TMJ: "Temporomandibular joint",
    TMD: "Temporomandibular disorder",
    BOE: "Buccal object evaluation",
    NSPT: "Non-surgical periodontal therapy",
    MBL: "Marginal bone loss",
    MIH: "Molar incisor hypomineralization",
    MOD: "Mesial-occlusal-distal",
    DO: "Distal-occlusal",
    MO: "Mesial-occlusal",
    CO: "Centric occlusion",
    CR: "Centric relation",
    WNL: "Within normal limits",
    CBCT: "Cone beam computed tomography",
    POE: "Periodic oral evaluation",
    CEJ: "Cemento-enamel junction"
  },
  
  // Dental materials
  materials: [
    "Amalgam",
    "Composite resin",
    "Glass ionomer",
    "Resin modified glass ionomer",
    "Compomer",
    "Porcelain",
    "Zirconia",
    "Lithium disilicate",
    "Gold alloy",
    "Base metal alloy",
    "Titanium",
    "PMMA (Polymethyl methacrylate)",
    "Temporary cement",
    "Resin cement",
    "Glass ionomer cement",
    "Zinc phosphate cement",
    "Zinc oxide eugenol"
  ],
  
  // Common dental conditions
  conditions: [
    "Dental caries",
    "Gingivitis",
    "Periodontitis",
    "Periapical abscess",
    "Pericoronitis",
    "Pulpitis",
    "Pulp necrosis",
    "Cracked tooth syndrome",
    "Dental erosion",
    "Dental abrasion",
    "Dental attrition",
    "Bruxism",
    "Malocclusion",
    "Temporomandibular disorder",
    "Dry socket (alveolar osteitis)",
    "Leukoplakia",
    "Oral candidiasis",
    "Lichen planus",
    "Recurrent aphthous stomatitis",
    "Geographic tongue",
    "Oral cancer",
    "Dentinal hypersensitivity",
    "Enamel hypoplasia",
    "Fluorosis",
    "Amelogenesis imperfecta",
    "Dentinogenesis imperfecta",
    "Dental ankylosis",
    "Peri-implantitis"
  ],
  
  // Common dental procedures
  procedures: [
    "Prophylaxis",
    "Scaling and root planing",
    "Fluoride treatment",
    "Sealant application",
    "Dental restoration",
    "Crown preparation",
    "Pulpotomy",
    "Pulpectomy",
    "Root canal treatment",
    "Apicoectomy",
    "Simple extraction",
    "Surgical extraction",
    "Alveoloplasty",
    "Dental implant placement",
    "Bone grafting",
    "Sinus lift",
    "Gingival graft",
    "Frenectomy",
    "Incision and drainage",
    "Space maintainer",
    "Orthodontic treatment",
    "Denture fabrication",
    "Bite splint/night guard",
    "Teeth whitening",
    "Veneer preparation"
  ]
};

// Sample of common CDT (Code on Dental Procedures and Nomenclature) codes
const commonCdtCodes = {
  // Diagnostic
  "D0120": "Periodic oral evaluation - established patient",
  "D0140": "Limited oral evaluation - problem focused",
  "D0150": "Comprehensive oral evaluation - new or established patient",
  "D0210": "Intraoral - complete series of radiographic images",
  "D0220": "Intraoral - periapical first radiographic image",
  "D0230": "Intraoral - periapical each additional radiographic image",
  "D0240": "Intraoral - occlusal radiographic image",
  "D0270": "Bitewing - single radiographic image",
  "D0272": "Bitewings - two radiographic images",
  "D0273": "Bitewings - three radiographic images",
  "D0274": "Bitewings - four radiographic images",
  "D0330": "Panoramic radiographic image",
  "D0350": "2D oral/facial photographic image",
  "D0470": "Diagnostic casts",
  
  // Preventive
  "D1110": "Prophylaxis - adult",
  "D1120": "Prophylaxis - child",
  "D1206": "Topical application of fluoride varnish",
  "D1208": "Topical application of fluoride - excluding varnish",
  "D1351": "Sealant - per tooth",
  "D1352": "Preventive resin restoration in moderate to high caries risk patient – permanent tooth",
  "D1510": "Space maintainer - fixed, unilateral - per quadrant",
  "D1516": "Space maintainer - fixed - bilateral, maxillary",
  "D1517": "Space maintainer - fixed - bilateral, mandibular",
  
  // Restorative
  "D2140": "Amalgam - one surface, primary or permanent",
  "D2150": "Amalgam - two surfaces, primary or permanent",
  "D2160": "Amalgam - three surfaces, primary or permanent",
  "D2161": "Amalgam - four or more surfaces, primary or permanent",
  "D2330": "Resin-based composite - one surface, anterior",
  "D2331": "Resin-based composite - two surfaces, anterior",
  "D2332": "Resin-based composite - three surfaces, anterior",
  "D2335": "Resin-based composite - four or more surfaces or involving incisal angle (anterior)",
  "D2390": "Resin-based composite crown, anterior",
  "D2391": "Resin-based composite - one surface, posterior",
  "D2392": "Resin-based composite - two surfaces, posterior",
  "D2393": "Resin-based composite - three surfaces, posterior",
  "D2394": "Resin-based composite - four or more surfaces, posterior",
  "D2740": "Crown - porcelain/ceramic",
  "D2750": "Crown - porcelain fused to high noble metal",
  "D2751": "Crown - porcelain fused to predominantly base metal",
  "D2752": "Crown - porcelain fused to noble metal",
  "D2790": "Crown - full cast high noble metal",
  "D2920": "Re-cement or re-bond crown",
  "D2950": "Core buildup, including any pins when required",
  "D2951": "Pin retention - per tooth, in addition to restoration",
  "D2952": "Post and core in addition to crown, indirectly fabricated",
  
  // Endodontics
  "D3110": "Pulp cap - direct (excluding final restoration)",
  "D3120": "Pulp cap - indirect (excluding final restoration)",
  "D3220": "Therapeutic pulpotomy (excluding final restoration)",
  "D3310": "Endodontic therapy, anterior tooth (excluding final restoration)",
  "D3320": "Endodontic therapy, premolar tooth (excluding final restoration)",
  "D3330": "Endodontic therapy, molar tooth (excluding final restoration)",
  "D3346": "Retreatment of previous root canal therapy - anterior",
  "D3347": "Retreatment of previous root canal therapy - premolar",
  "D3348": "Retreatment of previous root canal therapy - molar",
  "D3410": "Apicoectomy - anterior",
  "D3421": "Apicoectomy - premolar (first root)",
  "D3425": "Apicoectomy - molar (first root)",
  
  // Periodontics
  "D4210": "Gingivectomy or gingivoplasty - four or more contiguous teeth or tooth bounded spaces per quadrant",
  "D4211": "Gingivectomy or gingivoplasty - one to three contiguous teeth or tooth bounded spaces per quadrant",
  "D4240": "Gingival flap procedure, including root planing - four or more contiguous teeth or tooth bounded spaces per quadrant",
  "D4249": "Clinical crown lengthening - hard tissue",
  "D4260": "Osseous surgery - four or more contiguous teeth or tooth bounded spaces per quadrant",
  "D4261": "Osseous surgery - one to three contiguous teeth or tooth bounded spaces per quadrant",
  "D4341": "Periodontal scaling and root planing - four or more teeth per quadrant",
  "D4342": "Periodontal scaling and root planing - one to three teeth per quadrant",
  "D4346": "Scaling in presence of generalized moderate or severe gingival inflammation - full mouth, after oral evaluation",
  "D4355": "Full mouth debridement to enable a comprehensive oral evaluation and diagnosis on a subsequent visit",
  "D4910": "Periodontal maintenance",
  
  // Prosthodontics (removable)
  "D5110": "Complete denture - maxillary",
  "D5120": "Complete denture - mandibular",
  "D5130": "Immediate denture - maxillary",
  "D5140": "Immediate denture - mandibular",
  "D5211": "Maxillary partial denture - resin base",
  "D5212": "Mandibular partial denture - resin base",
  "D5213": "Maxillary partial denture - cast metal framework with resin denture bases",
  "D5214": "Mandibular partial denture - cast metal framework with resin denture bases",
  "D5410": "Adjust complete denture - maxillary",
  "D5411": "Adjust complete denture - mandibular",
  "D5421": "Adjust partial denture - maxillary",
  "D5422": "Adjust partial denture - mandibular",
  
  // Prosthodontics (fixed)
  "D6210": "Pontic - cast high noble metal",
  "D6240": "Pontic - porcelain fused to high noble metal",
  "D6241": "Pontic - porcelain fused to predominantly base metal",
  "D6242": "Pontic - porcelain fused to noble metal",
  "D6245": "Pontic - porcelain/ceramic",
  "D6740": "Retainer crown - porcelain/ceramic",
  "D6750": "Retainer crown - porcelain fused to high noble metal",
  "D6751": "Retainer crown - porcelain fused to predominantly base metal",
  "D6752": "Retainer crown - porcelain fused to noble metal",
  
  // Oral and Maxillofacial Surgery
  "D7140": "Extraction, erupted tooth or exposed root (elevation and/or forceps removal)",
  "D7210": "Extraction, erupted tooth requiring removal of bone and/or sectioning of tooth",
  "D7220": "Removal of impacted tooth - soft tissue",
  "D7230": "Removal of impacted tooth - partially bony",
  "D7240": "Removal of impacted tooth - completely bony",
  "D7241": "Removal of impacted tooth - completely bony, with unusual surgical complications",
  "D7250": "Removal of residual tooth roots (cutting procedure)",
  "D7270": "Tooth reimplantation and/or stabilization of accidentally evulsed or displaced tooth",
  "D7310": "Alveoloplasty in conjunction with extractions - four or more teeth or tooth spaces, per quadrant",
  "D7320": "Alveoloplasty not in conjunction with extractions - four or more teeth or tooth spaces, per quadrant",
  "D7510": "Incision and drainage of abscess - intraoral soft tissue",
  
  // Orthodontics
  "D8010": "Limited orthodontic treatment of the primary dentition",
  "D8020": "Limited orthodontic treatment of the transitional dentition",
  "D8030": "Limited orthodontic treatment of the adolescent dentition",
  "D8040": "Limited orthodontic treatment of the adult dentition",
  "D8070": "Comprehensive orthodontic treatment of the transitional dentition",
  "D8080": "Comprehensive orthodontic treatment of the adolescent dentition",
  "D8090": "Comprehensive orthodontic treatment of the adult dentition",
  "D8210": "Removable appliance therapy",
  "D8220": "Fixed appliance therapy",
  
  // Adjunctive General Services
  "D9110": "Palliative (emergency) treatment of dental pain - minor procedure",
  "D9215": "Local anesthesia in conjunction with operative or surgical procedures",
  "D9222": "Deep sedation/general anesthesia - first 15 minutes",
  "D9223": "Deep sedation/general anesthesia - each subsequent 15 minute increment",
  "D9230": "Inhalation of nitrous oxide/analgesia, anxiolysis",
  "D9310": "Consultation - diagnostic service provided by dentist or physician other than requesting dentist or physician",
  "D9430": "Office visit for observation (during regularly scheduled hours) - no other services performed",
  "D9440": "Office visit - after regularly scheduled hours",
  "D9910": "Application of desensitizing medicament",
  "D9911": "Application of desensitizing resin for cervical and/or root surface, per tooth",
  "D9944": "Occlusal guard - hard appliance, full arch",
  "D9945": "Occlusal guard - soft appliance, full arch",
  "D9951": "Occlusal adjustment - limited",
  "D9952": "Occlusal adjustment - complete"
};

module.exports = {
  dentalTerminology,
  commonCdtCodes
};
EOL

# Create decision support service
cat > "$AI_DIR/decisionSupportService.js" << EOL
const { generateDifferentialDiagnoses } = require('./aiServiceManager');
const { dentalTerminology, commonCdtCodes } = require('./data/dentalTerminology');
const logger = require('../utils/logger');

/**
 * Generate differential diagnoses based on symptoms and findings
 * @param {string} symptoms - Patient symptoms
 * @param {string} findings - Clinical findings
 * @returns {Promise<Array>} - List of potential diagnoses
 */
const generateDifferentials = async (symptoms, findings) => {
  try {
    return await generateDifferentialDiagnoses(symptoms, findings);
  } catch (error) {
    logger.error('Error generating differential diagnoses:', error);
    throw new Error(\`Failed to generate differential diagnoses: \${error.message}\`);
  }
};

/**
 * Lookup CDT codes based on description or keywords
 * @param {string} description - Description or keywords
 * @returns {Array} - Matching CDT codes
 */
const lookupCdtCodes = (description) => {
  const keywords = description.toLowerCase().split(/\\s+/);
  const matches = [];
  
  for (const [code, codeDescription] of Object.entries(commonCdtCodes)) {
    // Score each code based on keyword matches
    let score = 0;
    const lowerDesc = codeDescription.toLowerCase();
    
    keywords.forEach(keyword => {
      if (keyword.length > 3 && lowerDesc.includes(keyword)) {
        score += 1;
      }
    });
    
    if (score > 0) {
      matches.push({
        code,
        description: codeDescription,
        score
      });
    }
  }
  
  // Sort by score (descending)
  return matches.sort((a, b) => b.score - a.score);
};

/**
 * Get treatment recommendations based on diagnosis
 * @param {string} diagnosis - Diagnosis
 * @returns {Promise<Object>} - Treatment recommendations
 */
const getTreatmentRecommendations = async (diagnosis) => {
  // This would eventually call an AI model, but for now use a simple rule-based approach
  const diagnosisLower = diagnosis.toLowerCase();
  
  // Very basic rule-based recommendations
  if (diagnosisLower.includes('caries') || diagnosisLower.includes('cavity')) {
    return {
      treatments: [
        {
          name: "Composite restoration",
          description: "Tooth-colored filling to restore the affected tooth",
          cdtCodes: lookupCdtCodes("resin-based composite").slice(0, 3)
        },
        {
          name: "Amalgam restoration",
          description: "Silver filling to restore the affected tooth",
          cdtCodes: lookupCdtCodes("amalgam").slice(0, 3)
        }
      ],
      preventiveMeasures: [
        "Improved oral hygiene instruction",
        "Increased fluoride exposure",
        "Dietary counseling to reduce sugar intake",
        "Regular dental check-ups"
      ]
    };
  } 
  else if (diagnosisLower.includes('pulpitis') || diagnosisLower.includes('pulp')) {
    return {
      treatments: [
        {
          name: "Root canal treatment",
          description: "Removal of infected pulp tissue and sealing of the root canal system",
          cdtCodes: lookupCdtCodes("endodontic therapy").slice(0, 3)
        }
      ],
      preventiveMeasures: [
        "Follow-up with permanent restoration (crown)"
      ]
    };
  }
  else if (diagnosisLower.includes('gingivitis')) {
    return {
      treatments: [
        {
          name: "Professional dental cleaning",
          description: "Removal of plaque and calculus",
          cdtCodes: lookupCdtCodes("prophylaxis").slice(0, 2)
        }
      ],
      preventiveMeasures: [
        "Improved oral hygiene instruction",
        "Regular use of antimicrobial mouthwash",
        "Regular dental check-ups"
      ]
    };
  }
  else if (diagnosisLower.includes('periodontitis')) {
    return {
      treatments: [
        {
          name: "Scaling and root planing",
          description: "Deep cleaning below the gumline",
          cdtCodes: lookupCdtCodes("scaling and root planing").slice(0, 2)
        },
        {
          name: "Periodontal maintenance",
          description: "Regular maintenance cleaning",
          cdtCodes: lookupCdtCodes("periodontal maintenance").slice(0, 1)
        }
      ],
      preventiveMeasures: [
        "Improved oral hygiene instruction",
        "Regular periodontal maintenance visits",
        "Smoking cessation if applicable"
      ]
    };
  }
  else {
    // Generic response for unknown conditions
    return {
      treatments: [
        {
          name: "Further evaluation needed",
          description: "Additional diagnostic tests or specialist consultation may be required",
          cdtCodes: lookupCdtCodes("evaluation").slice(0, 3)
        }
      ],
      preventiveMeasures: [
        "Maintain good oral hygiene",
        "Regular dental check-ups"
      ]
    };
  }
};

module.exports = {
  generateDifferentials,
  lookupCdtCodes,
  getTreatmentRecommendations
};
EOL

# Create index.js to export all AI services
cat > "$AI_DIR/index.js" << EOL
/**
 * AI Services entry point
 * Exports all AI-related services for easy importing
 */

const aiServiceManager = require('./aiServiceManager');
const decisionSupportService = require('./decisionSupportService');
const { dentalTerminology, commonCdtCodes } = require('./data/dentalTerminology');

module.exports = {
  // Core AI functions
  transcribeAudio: aiServiceManager.transcribeAudio,
  generateClinicalNotes: aiServiceManager.generateClinicalNotes,
  generateDifferentialDiagnoses: aiServiceManager.generateDifferentialDiagnoses,
  generateSuggestedQuestions: aiServiceManager.generateSuggestedQuestions,
  
  // Decision support functions
  generateDifferentials: decisionSupportService.generateDifferentials,
  lookupCdtCodes: decisionSupportService.lookupCdtCodes,
  getTreatmentRecommendations: decisionSupportService.getTreatmentRecommendations,
  
  // Reference data
  dentalTerminology,
  commonCdtCodes
};
EOL

# Add AI service-related packages to package.json in backend
cd "$BACKEND_DIR"
npm install --save openai axios@0.27.2

# Create .env.example in the AI directory
cat > "$AI_DIR/.env.example" << EOL
# AI Service API Keys
OPENAI_API_KEY=your_openai_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# AI Service Configuration
PRIMARY_AI_SERVICE=openai  # options: openai, anthropic
EOL

echo -e "${GREEN}"
echo "======================================================"
echo "      DentalAI Assistant AI Services Setup Complete   "
echo "======================================================"
echo -e "${NC}"
echo "AI services have been configured successfully."
echo "Make sure to set your API keys in the .env file."
