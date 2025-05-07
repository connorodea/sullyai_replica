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

```
bash scripts/main-setup.sh
```

This will set up the development environment, backend, frontend, database, and all necessary configurations.

### Development

Start the backend development server:

```
cd backend
npm run dev
```

Start the frontend development server:

```
cd frontend
npm start
```

## Documentation

Documentation is available in the `docs/` directory.

## Testing

Run tests:

```
npm test
```

## Deployment

See the deployment instructions in the `deployment/` directory.

## License

This project is proprietary and confidential.
