#!/bin/bash

# Database setup script for DentalAI Assistant
# Sets up MongoDB and initial database schema

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
DB_DIR="$PROJECT_DIR/database"

echo -e "${BLUE}"
echo "======================================================"
echo "         DentalAI Assistant Database Setup            "
echo "======================================================"
echo -e "${NC}"

# Create database directory
mkdir -p "$DB_DIR"
mkdir -p "$DB_DIR/scripts"
mkdir -p "$DB_DIR/backup"

# Check if MongoDB is running
echo -e "${GREEN}Checking MongoDB status...${NC}"
if command -v systemctl &> /dev/null; then
    # For systems with systemd
    if systemctl is-active --quiet mongodb || systemctl is-active --quiet mongod; then
        echo -e "${GREEN}MongoDB is running.${NC}"
    else
        echo -e "${YELLOW}MongoDB is not running. Starting MongoDB...${NC}"
        if systemctl list-unit-files | grep -q mongodb; then
            sudo systemctl start mongodb
        elif systemctl list-unit-files | grep -q mongod; then
            sudo systemctl start mongod
        else
            echo -e "${RED}MongoDB service not found. Please install MongoDB.${NC}"
            exit 1
        fi
    fi
elif command -v brew &> /dev/null; then
    # For macOS with Homebrew
    if brew services list | grep -q mongodb-community; then
        if ! brew services list | grep mongodb-community | grep -q started; then
            echo -e "${YELLOW}MongoDB is not running. Starting MongoDB...${NC}"
            brew services start mongodb-community
        else
            echo -e "${GREEN}MongoDB is running.${NC}"
        fi
    else
        echo -e "${RED}MongoDB service not found. Please install MongoDB.${NC}"
        exit 1
    fi
else
    # For other systems, check if mongod process is running
    if pgrep mongod &> /dev/null; then
        echo -e "${GREEN}MongoDB is running.${NC}"
    else
        echo -e "${RED}MongoDB is not running and could not be started automatically.${NC}"
        echo -e "${RED}Please start MongoDB manually and run this script again.${NC}"
        exit 1
    fi
fi

# Create MongoDB initialization script
echo -e "${GREEN}Creating MongoDB initialization script...${NC}"
cat > "$DB_DIR/scripts/init.js" << EOL
// MongoDB initialization script for DentalAI Assistant

// Database initialization
db = db.getSiblingDB('dental-ai');

// Create collections with schema validation
db.createCollection('users', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['name', 'email', 'password', 'role'],
      properties: {
        name: {
          bsonType: 'string',
          description: 'Name must be a string and is required'
        },
        email: {
          bsonType: 'string',
          description: 'Email must be a string and is required'
        },
        password: {
          bsonType: 'string',
          description: 'Password must be a string and is required'
        },
        role: {
          enum: ['dentist', 'assistant', 'admin'],
          description: 'Role must be one of the specified values'
        },
        isAdmin: {
          bsonType: 'bool',
          description: 'isAdmin must be a boolean'
        },
        practice: {
          bsonType: ['objectId', 'null'],
          description: 'Practice must be an ObjectId or null'
        },
        createdAt: {
          bsonType: 'date',
          description: 'createdAt must be a date'
        }
      }
    }
  }
});

db.createCollection('practices', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['name'],
      properties: {
        name: {
          bsonType: 'string',
          description: 'Name must be a string and is required'
        },
        address: {
          bsonType: 'object',
          properties: {
            street: { bsonType: 'string' },
            city: { bsonType: 'string' },
            state: { bsonType: 'string' },
            zipCode: { bsonType: 'string' },
            country: { bsonType: 'string' }
          }
        },
        phone: {
          bsonType: 'string',
          description: 'Phone must be a string'
        },
        email: {
          bsonType: 'string',
          description: 'Email must be a string'
        },
        website: {
          bsonType: 'string',
          description: 'Website must be a string'
        },
        createdAt: {
          bsonType: 'date',
          description: 'createdAt must be a date'
        }
      }
    }
  }
});

db.createCollection('patients', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['firstName', 'lastName', 'dateOfBirth', 'gender', 'practice', 'createdBy'],
      properties: {
        firstName: {
          bsonType: 'string',
          description: 'First name must be a string and is required'
        },
        lastName: {
          bsonType: 'string',
          description: 'Last name must be a string and is required'
        },
        dateOfBirth: {
          bsonType: 'date',
          description: 'Date of birth must be a date and is required'
        },
        gender: {
          enum: ['male', 'female', 'other', 'prefer not to say'],
          description: 'Gender must be one of the specified values'
        },
        email: {
          bsonType: 'string',
          description: 'Email must be a string'
        },
        phone: {
          bsonType: 'string',
          description: 'Phone must be a string'
        },
        address: {
          bsonType: 'object',
          properties: {
            street: { bsonType: 'string' },
            city: { bsonType: 'string' },
            state: { bsonType: 'string' },
            zipCode: { bsonType: 'string' },
            country: { bsonType: 'string' }
          }
        },
        insuranceInfo: {
          bsonType: 'object',
          properties: {
            provider: { bsonType: 'string' },
            policyNumber: { bsonType: 'string' },
            groupNumber: { bsonType: 'string' },
            primary: { bsonType: 'bool' }
          }
        },
        medicalHistory: {
          bsonType: 'object',
          properties: {
            allergies: { bsonType: 'array', items: { bsonType: 'string' } },
            medications: { bsonType: 'array', items: { bsonType: 'string' } },
            conditions: { bsonType: 'array', items: { bsonType: 'string' } },
            surgeries: { bsonType: 'array', items: { bsonType: 'string' } },
            familyHistory: { bsonType: 'array', items: { bsonType: 'string' } }
          }
        },
        dentalHistory: {
          bsonType: 'object',
          properties: {
            lastVisit: { bsonType: 'date' },
            treatments: { bsonType: 'array', items: { bsonType: 'string' } },
            notes: { bsonType: 'string' }
          }
        },
        practice: {
          bsonType: 'objectId',
          description: 'Practice ID must be an ObjectId and is required'
        },
        createdBy: {
          bsonType: 'objectId',
          description: 'Created by must be an ObjectId and is required'
        },
        createdAt: {
          bsonType: 'date',
          description: 'createdAt must be a date'
        }
      }
    }
  }
});

db.createCollection('notes', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['patient', 'provider', 'noteType', 'content', 'status'],
      properties: {
        patient: {
          bsonType: 'objectId',
          description: 'Patient ID must be an ObjectId and is required'
        },
        appointment: {
          bsonType: ['objectId', 'null'],
          description: 'Appointment ID must be an ObjectId or null'
        },
        provider: {
          bsonType: 'objectId',
          description: 'Provider ID must be an ObjectId and is required'
        },
        noteType: {
          enum: ['SOAP', 'procedure', 'followUp', 'other'],
          description: 'Note type must be one of the specified values'
        },
        content: {
          bsonType: 'object',
          properties: {
            subjective: { bsonType: 'string' },
            objective: { bsonType: 'string' },
            assessment: { bsonType: 'string' },
            plan: { bsonType: 'string' },
            additionalNotes: { bsonType: 'string' },
            rawTranscript: { bsonType: 'string' }
          }
        },
        diagnosisCodes: {
          bsonType: 'array',
          items: {
            bsonType: 'object',
            properties: {
              code: { bsonType: 'string' },
              description: { bsonType: 'string' }
            }
          }
        },
        procedureCodes: {
          bsonType: 'array',
          items: {
            bsonType: 'object',
            properties: {
              code: { bsonType: 'string' },
              description: { bsonType: 'string' }
            }
          }
        },
        createdAt: {
          bsonType: 'date',
          description: 'createdAt must be a date'
        },
        updatedAt: {
          bsonType: 'date',
          description: 'updatedAt must be a date'
        },
        status: {
          enum: ['draft', 'finalized', 'signed'],
          description: 'Status must be one of the specified values'
        },
        isDeleted: {
          bsonType: 'bool',
          description: 'isDeleted must be a boolean'
        }
      }
    }
  }
});

db.createCollection('appointments', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['patient', 'provider', 'startTime', 'endTime', 'status'],
      properties: {
        patient: {
          bsonType: 'objectId',
          description: 'Patient ID must be an ObjectId and is required'
        },
        provider: {
          bsonType: 'objectId',
          description: 'Provider ID must be an ObjectId and is required'
        },
        startTime: {
          bsonType: 'date',
          description: 'Start time must be a date and is required'
        },
        endTime: {
          bsonType: 'date',
          description: 'End time must be a date and is required'
        },
        appointmentType: {
          bsonType: 'string',
          description: 'Appointment type must be a string'
        },
        reason: {
          bsonType: 'string',
          description: 'Reason must be a string'
        },
        notes: {
          bsonType: 'string',
          description: 'Notes must be a string'
        },
        status: {
          enum: ['scheduled', 'confirmed', 'cancelled', 'completed', 'no-show'],
          description: 'Status must be one of the specified values'
        },
        createdBy: {
          bsonType: 'objectId',
          description: 'Created by must be an ObjectId'
        },
        createdAt: {
          bsonType: 'date',
          description: 'createdAt must be a date'
        },
        updatedAt: {
          bsonType: 'date',
          description: 'updatedAt must be a date'
        }
      }
    }
  }
});

// Create indexes
db.users.createIndex({ email: 1 }, { unique: true });
db.users.createIndex({ practice: 1 });
db.patients.createIndex({ firstName: 'text', lastName: 'text', email: 'text' });
db.patients.createIndex({ practice: 1 });
db.patients.createIndex({ dateOfBirth: 1 });
db.notes.createIndex({ patient: 1 });
db.notes.createIndex({ provider: 1 });
db.notes.createIndex({ createdAt: 1 });
db.appointments.createIndex({ patient: 1 });
db.appointments.createIndex({ provider: 1 });
db.appointments.createIndex({ startTime: 1 });
db.appointments.createIndex({ status: 1 });

// Create default admin user if not exists
const adminUser = db.users.findOne({ email: 'admin@dentalai.com' });
if (!adminUser) {
  db.users.insertOne({
    name: 'Admin',
    email: 'admin@dentalai.com',
    // Default password: admin123 (hashed)
    password: '$2a$10$CtHS.yCGS9xnhrJAP1Z/ReuLfVjKPlaSjYXWj15XkL1kTlUzVJ65a',
    role: 'admin',
    isAdmin: true,
    createdAt: new Date()
  });
  print('Created default admin user');
}

// Create default practice if not exists
const defaultPractice = db.practices.findOne({ name: 'DentalAI Practice' });
if (!defaultPractice) {
  const practiceId = db.practices.insertOne({
    name: 'DentalAI Practice',
    address: {
      street: '123 Main St',
      city: 'Anytown',
      state: 'CA',
      zipCode: '12345',
      country: 'USA'
    },
    phone: '(555) 123-4567',
    email: 'info@dentalai.com',
    website: 'https://dentalai.com',
    createdAt: new Date()
  }).insertedId;
  print('Created default practice');
  
  // Create default dentist user if not exists
  const dentistUser = db.users.findOne({ email: 'dentist@dentalai.com' });
  if (!dentistUser) {
    db.users.insertOne({
      name: 'Dr. Smith',
      email: 'dentist@dentalai.com',
      // Default password: dentist123 (hashed)
      password: '$2a$10$yQkBMZyYJBzK8IXFJ2.W8eEABwZh4FhNuF7V.lQcBFDtHF1XSXJ0y',
      role: 'dentist',
      isAdmin: false,
      practice: practiceId,
      createdAt: new Date()
    });
    print('Created default dentist user');
  }
  
  // Create default assistant user if not exists
  const assistantUser = db.users.findOne({ email: 'assistant@dentalai.com' });
  if (!assistantUser) {
    db.users.insertOne({
      name: 'Jane Doe',
      email: 'assistant@dentalai.com',
      // Default password: assistant123 (hashed)
      password: '$2a$10$jZ1nemAIQpx4Fd2jmKM6keaOafZ0kROuFKFRYFja/7V.49Gqx1jEC',
      role: 'assistant',
      isAdmin: false,
      practice: practiceId,
      createdAt: new Date()
    });
    print('Created default assistant user');
  }
}

print('Database initialization completed successfully');
EOL

# Create MongoDB backup script
echo -e "${GREEN}Creating MongoDB backup script...${NC}"
cat > "$DB_DIR/scripts/backup.sh" << EOL
#!/bin/bash

# MongoDB backup script
# Usage: ./backup.sh [backup_name]

# Get backup name from command line argument or use current date
BACKUP_NAME=\${1:-\$(date +"%Y%m%d_%H%M%S")}
BACKUP_DIR="$DB_DIR/backup"
MONGODB_URI="mongodb://localhost:27017/dental-ai"

# Create backup using mongodump
echo "Creating backup \$BACKUP_NAME..."
mongodump --uri="\$MONGODB_URI" --out="\$BACKUP_DIR/\$BACKUP_NAME"

# Check if backup was successful
if [ \$? -eq 0 ]; then
  echo "Backup created successfully: \$BACKUP_DIR/\$BACKUP_NAME"
else
  echo "Backup failed"
  exit 1
fi
EOL

# Create MongoDB restore script
echo -e "${GREEN}Creating MongoDB restore script...${NC}"
cat > "$DB_DIR/scripts/restore.sh" << EOL
#!/bin/bash

# MongoDB restore script
# Usage: ./restore.sh <backup_name>

# Check if backup name is provided
if [ -z "\$1" ]; then
  echo "Error: Backup name is required"
  echo "Usage: ./restore.sh <backup_name>"
  exit 1
fi

BACKUP_NAME="\$1"
BACKUP_DIR="$DB_DIR/backup"
MONGODB_URI="mongodb://localhost:27017/dental-ai"

# Check if backup exists
if [ ! -d "\$BACKUP_DIR/\$BACKUP_NAME" ]; then
  echo "Error: Backup \$BACKUP_NAME not found"
  exit 1
fi

# Restore using mongorestore
echo "Restoring from backup \$BACKUP_NAME..."
mongorestore --uri="\$MONGODB_URI" --drop "\$BACKUP_DIR/\$BACKUP_NAME"

# Check if restore was successful
if [ \$? -eq 0 ]; then
  echo "Restore completed successfully"
else
  echo "Restore failed"
  exit 1
fi
EOL

# Create seed data script
echo -e "${GREEN}Creating seed data script...${NC}"
cat > "$DB_DIR/scripts/seed.js" << EOL
// Seed data script for DentalAI Assistant

// Database connection
db = db.getSiblingDB('dental-ai');

// Sample patient data
const samplePatients = [
  {
    firstName: 'John',
    lastName: 'Doe',
    dateOfBirth: new Date('1985-06-15'),
    gender: 'male',
    email: 'john.doe@example.com',
    phone: '(555) 123-4567',
    address: {
      street: '123 Main St',
      city: 'Anytown',
      state: 'CA',
      zipCode: '12345',
      country: 'USA'
    },
    insuranceInfo: {
      provider: 'Delta Dental',
      policyNumber: 'DD123456',
      groupNumber: 'GRP001',
      primary: true
    },
    medicalHistory: {
      allergies: ['Penicillin', 'Latex'],
      medications: ['Lisinopril 10mg', 'Atorvastatin 20mg'],
      conditions: ['Hypertension', 'High Cholesterol'],
      surgeries: ['Appendectomy (2010)'],
      familyHistory: ['Diabetes', 'Heart Disease']
    },
    dentalHistory: {
      lastVisit: new Date('2023-01-15'),
      treatments: ['Cleaning', 'Filling (tooth #30)'],
      notes: 'Patient has dental anxiety, prefers nitrous oxide during procedures.'
    }
  },
  {
    firstName: 'Jane',
    lastName: 'Smith',
    dateOfBirth: new Date('1990-03-22'),
    gender: 'female',
    email: 'jane.smith@example.com',
    phone: '(555) 987-6543',
    address: {
      street: '456 Oak Ave',
      city: 'Anytown',
      state: 'CA',
      zipCode: '12345',
      country: 'USA'
    },
    insuranceInfo: {
      provider: 'Cigna',
      policyNumber: 'CG789012',
      groupNumber: 'GRP002',
      primary: true
    },
    medicalHistory: {
      allergies: ['Aspirin'],
      medications: ['Levothyroxine 50mcg'],
      conditions: ['Hypothyroidism'],
      surgeries: [],
      familyHistory: ['Thyroid disorders']
    },
    dentalHistory: {
      lastVisit: new Date('2023-03-10'),
      treatments: ['Cleaning', 'X-rays'],
      notes: 'Patient has excellent oral hygiene.'
    }
  },
  {
    firstName: 'Michael',
    lastName: 'Johnson',
    dateOfBirth: new Date('1978-11-08'),
    gender: 'male',
    email: 'michael.johnson@example.com',
    phone: '(555) 456-7890',
    address: {
      street: '789 Pine St',
      city: 'Othertown',
      state: 'CA',
      zipCode: '67890',
      country: 'USA'
    },
    insuranceInfo: {
      provider: 'MetLife',
      policyNumber: 'ML345678',
      groupNumber: 'GRP003',
      primary: true
    },
    medicalHistory: {
      allergies: [],
      medications: ['Metformin 500mg', 'Glipizide 5mg'],
      conditions: ['Type 2 Diabetes'],
      surgeries: [],
      familyHistory: ['Diabetes']
    },
    dentalHistory: {
      lastVisit: new Date('2022-12-05'),
      treatments: ['Root Canal (tooth #19)', 'Crown (tooth #19)'],
      notes: 'Patient has history of periodontal disease, on 3-month recall schedule.'
    }
  }
];

// Get default practice
const defaultPractice = db.practices.findOne({ name: 'DentalAI Practice' });
if (!defaultPractice) {
  print('Error: Default practice not found');
  quit();
}

// Get default dentist
const defaultDentist = db.users.findOne({ email: 'dentist@dentalai.com' });
if (!defaultDentist) {
  print('Error: Default dentist not found');
  quit();
}

// Insert sample patients
print('Inserting sample patients...');
samplePatients.forEach(patient => {
  // Check if patient already exists
  const existingPatient = db.patients.findOne({ 
    firstName: patient.firstName, 
    lastName: patient.lastName,
    dateOfBirth: patient.dateOfBirth
  });
  
  if (!existingPatient) {
    db.patients.insertOne({
      ...patient,
      practice: defaultPractice._id,
      createdBy: defaultDentist._id,
      createdAt: new Date()
    });
    print(\`Created patient: \${patient.firstName} \${patient.lastName}\`);
  } else {
    print(\`Patient already exists: \${patient.firstName} \${patient.lastName}\`);
  }
});

// Sample notes data
const patientJohn = db.patients.findOne({ firstName: 'John', lastName: 'Doe' });
if (patientJohn) {
  // Check if note already exists
  const existingNote = db.notes.findOne({ patient: patientJohn._id });
  
  if (!existingNote) {
    print('Creating sample note for John Doe...');
    db.notes.insertOne({
      patient: patientJohn._id,
      provider: defaultDentist._id,
      noteType: 'SOAP',
      content: {
        subjective: 'Patient presents with pain in lower right quadrant when chewing. Pain started 3 days ago and has been increasing in intensity. Patient rates pain as 6/10. No sensitivity to hot or cold. No previous history of pain in this area.',
        objective: 'Examination reveals deep carious lesion on tooth #30 (lower right first molar). Percussion test positive. Cold test negative. No visible swelling or sinus tract. Periodontal probing depths within normal limits.',
        assessment: 'Pulpal necrosis with symptomatic apical periodontitis on tooth #30 due to carious exposure.',
        plan: '1. Root canal treatment on tooth #30\\n2. Full coverage crown on tooth #30 after endodontic therapy\\n3. OHI and recommend improved flossing technique',
        rawTranscript: 'Dr: Good morning John, what brings you in today?\\nPatient: I\'ve been having some pain when I chew on my lower right side.\\nDr: When did this start?\\nPatient: About 3 days ago, and it\'s been getting worse.\\nDr: On a scale of 1-10, how would you rate the pain?\\nPatient: I\'d say about a 6.\\nDr: Any sensitivity to hot or cold?\\nPatient: No, just when I\'m eating.\\nDr: Have you had pain in this area before?\\nPatient: No, this is the first time.\\nDr: Let me take a look... I can see you have a large cavity on your lower right first molar. I\'m going to tap on it to see if it\'s sensitive... does that hurt?\\nPatient: Yes, that\'s definitely where the pain is.\\nDr: I\'m going to do a cold test... do you feel anything?\\nPatient: No, nothing.\\nDr: Based on my examination, the cavity has reached the nerve of your tooth, and the nerve has died, causing an infection at the root tip. That\'s what\'s causing your pain. You\'ll need a root canal treatment followed by a crown to save the tooth.\\nPatient: I figured it would be something like that. When can we do it?\\nDr: We can start the root canal today if you\'d like, and then schedule you for the crown in a couple of weeks. I also notice you have some plaque buildup around your gums. Let\'s talk about improving your flossing technique...'
      },
      procedureCodes: [
        {
          code: 'D3330',
          description: 'Endodontic therapy, molar tooth (excluding final restoration)'
        },
        {
          code: 'D2740',
          description: 'Crown - porcelain/ceramic'
        },
        {
          code: 'D1330',
          description: 'Oral hygiene instructions'
        }
      ],
      createdAt: new Date(),
      updatedAt: new Date(),
      status: 'finalized',
      isDeleted: false
    });
    print('Sample note created');
  } else {
    print('Note already exists for John Doe');
  }
}

// Sample appointments
print('Creating sample appointments...');
const today = new Date();
const tomorrow = new Date(today);
tomorrow.setDate(today.getDate() + 1);
const nextWeek = new Date(today);
nextWeek.setDate(today.getDate() + 7);

// Helper function to set time
function setTime(date, hours, minutes) {
  const newDate = new Date(date);
  newDate.setHours(hours, minutes, 0, 0);
  return newDate;
}

// Sample appointment data
const sampleAppointments = [
  {
    patient: patientJohn._id,
    provider: defaultDentist._id,
    startTime: setTime(tomorrow, 9, 0),
    endTime: setTime(tomorrow, 10, 30),
    appointmentType: 'Root Canal',
    reason: 'Root canal treatment on tooth #30',
    notes: 'Patient has dental anxiety, consider nitrous oxide',
    status: 'confirmed'
  },
  {
    patient: db.patients.findOne({ firstName: 'Jane', lastName: 'Smith' })._id,
    provider: defaultDentist._id,
    startTime: setTime(tomorrow, 11, 0),
    endTime: setTime(tomorrow, 12, 0),
    appointmentType: 'Check-up',
    reason: 'Regular 6-month check-up and cleaning',
    notes: '',
    status: 'confirmed'
  },
  {
    patient: db.patients.findOne({ firstName: 'Michael', lastName: 'Johnson' })._id,
    provider: defaultDentist._id,
    startTime: setTime(nextWeek, 14, 0),
    endTime: setTime(nextWeek, 15, 0),
    appointmentType: 'Crown',
    reason: 'Crown delivery for tooth #19',
    notes: 'Final restoration after RCT',
    status: 'scheduled'
  }
];

// Insert sample appointments
sampleAppointments.forEach(appointment => {
  // Check if appointment already exists
  const existingAppointment = db.appointments.findOne({ 
    patient: appointment.patient,
    provider: appointment.provider,
    startTime: appointment.startTime
  });
  
  if (!existingAppointment) {
    db.appointments.insertOne({
      ...appointment,
      createdBy: defaultDentist._id,
      createdAt: new Date(),
      updatedAt: new Date()
    });
    print('Created appointment');
  } else {
    print('Appointment already exists');
  }
});

print('Seed data script completed');
EOL

# Make scripts executable
chmod +x "$DB_DIR/scripts/backup.sh"
chmod +x "$DB_DIR/scripts/restore.sh"

# Run MongoDB initialization script
echo -e "${GREEN}Initializing MongoDB database...${NC}"
mongosh "mongodb://localhost:27017/admin" "$DB_DIR/scripts/init.js"

# Ask if user wants to run seed script
read -p "Do you want to populate the database with sample data? (y/n): " RUN_SEED
if [ "$RUN_SEED" = "y" ]; then
    echo -e "${GREEN}Populating database with sample data...${NC}"
    mongosh "mongodb://localhost:27017/admin" "$DB_DIR/scripts/seed.js"
fi

# Create a MongoDB configuration file
echo -e "${GREEN}Creating MongoDB configuration file...${NC}"
cat > "$DB_DIR/mongodb.conf" << EOL
# MongoDB configuration file

# Where and how to store data
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

# Where to write logging data
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# Network interfaces
net:
  port: 27017
  bindIp: 127.0.0.1

# Security
security:
  authorization: enabled
EOL

# Create a database README file
echo -e "${GREEN}Creating database README...${NC}"
cat > "$DB_DIR/README.md" << EOL
# DentalAI Assistant - Database

This directory contains the database setup scripts and configuration for the DentalAI Assistant application.

## MongoDB Setup

The application uses MongoDB as its database. The scripts in this directory help with setting up and managing the database.

### Scripts

- \`scripts/init.js\`: MongoDB initialization script that creates the database, collections, and indexes.
- \`scripts/seed.js\`: Script to populate the database with sample data for development and testing.
- \`scripts/backup.sh\`: Script to create a backup of the database.
- \`scripts/restore.sh\`: Script to restore the database from a backup.

### Default Credentials

For development purposes, the following default users are created:

1. Admin User:
   - Email: admin@dentalai.com
   - Password: admin123

2. Dentist User:
   - Email: dentist@dentalai.com
   - Password: dentist123

3. Assistant User:
   - Email: assistant@dentalai.com
   - Password: assistant123

**Note:** These default credentials should be changed in production.

### Database Schema

The database consists of the following collections:

1. \`users\`: Stores user information including dentists, assistants, and administrators.
2. \`practices\`: Stores dental practice information.
3. \`patients\`: Stores patient information and medical/dental history.
4. \`notes\`: Stores clinical notes created from transcriptions.
5. \`appointments\`: Stores appointment scheduling information.

## Backup and Restore

To create a backup:

\`\`\`
./scripts/backup.sh [backup_name]
\`\`\`

To restore from a backup:

\`\`\`
./scripts/restore.sh <backup_name>
\`\`\`

## Production Deployment

For production deployment, the following steps are recommended:

1. Use a managed MongoDB service or properly configure MongoDB for production security.
2. Change default credentials.
3. Implement regular backups.
4. Configure proper firewall and network security.
EOL

echo -e "${GREEN}"
echo "======================================================"
echo "      DentalAI Assistant Database Setup Complete      "
echo "======================================================"
echo -e "${NC}"
echo "The database has been set up successfully."
echo "Default credentials:"
echo -e "${YELLOW}Admin: admin@dentalai.com / admin123${NC}"
echo -e "${YELLOW}Dentist: dentist@dentalai.com / dentist123${NC}"
echo -e "${YELLOW}Assistant: assistant@dentalai.com / assistant123${NC}"
