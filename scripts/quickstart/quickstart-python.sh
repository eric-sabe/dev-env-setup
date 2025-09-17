#!/bin/bash
# Python Project Quickstart Script
# Creates a comprehensive Python project with best practices

if [[ ${STRICT_MODE:-0} == 1 || -n ${CI:-} ]]; then
    set -Eeuo pipefail
else
    set -o pipefail
fi
trap 'echo "[ERROR] quickstart-python failed at ${BASH_SOURCE[0]}:${LINENO}" >&2' ERR

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_header() {
    echo -e "${PURPLE}🐍 $1${NC}"
    echo -e "${PURPLE}$(printf '%.0s=' {1..50})${NC}"
}

# Source utility scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL_DIR="${SCRIPT_DIR%/quickstart*/}/utils"
[[ -f "$UTIL_DIR/cross-platform.sh" ]] && source "$UTIL_DIR/cross-platform.sh"
[[ -f "$UTIL_DIR/idempotency.sh" ]] && source "$UTIL_DIR/idempotency.sh"

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check Python 3
    if ! ensure_command python3 "Python 3"; then
        log_error "Python 3 is required. Please install it first."
        exit 1
    fi

    # Check pip3
    if ! ensure_command pip3 "pip3"; then
        log_error "pip3 is required. Please install it first."
        exit 1
    fi

    log_success "Prerequisites check passed"
}

# Get project information
get_project_info() {
    # Project name
    if [[ -z "$1" ]]; then
        read -p "Enter project name: " PROJECT_NAME
    else
        PROJECT_NAME="$1"
    fi

    # Project type
    echo ""
    echo "Select project type:"
    echo "1. Web API (FastAPI/Flask)"
    echo "2. CLI Tool"
    echo "3. Data Science/ML"
    echo "4. Library/Package"
    echo "5. Desktop App (Tkinter/PyQt)"
    echo "6. Minimal (Basic setup)"
    read -p "Choose project type [1]: " PROJECT_TYPE
    PROJECT_TYPE=${PROJECT_TYPE:-1}

    # Modern build system option
    read -p "Use pyproject.toml only (skip legacy setup.py)? (Y/n): " USE_PYPROJECT_ONLY
    if [[ $USE_PYPROJECT_ONLY =~ ^[Nn]$ ]]; then
        USE_PYPROJECT_ONLY=false
    else
        USE_PYPROJECT_ONLY=true
    fi

    # Project description
    read -p "Enter project description: " PROJECT_DESC
    PROJECT_DESC=${PROJECT_DESC:-"A Python project"}

    # Author
    read -p "Enter author name: " AUTHOR
    AUTHOR=${AUTHOR:-"$(whoami)"}

    # Author email
    read -p "Enter author email: " AUTHOR_EMAIL

    # Python version
    read -p "Python version to use (default: 3.x): " PYTHON_VERSION
    PYTHON_VERSION=${PYTHON_VERSION:-"3"}

    # Git repository
    read -p "Enter git repository URL (optional): " GIT_REPO

    # Include testing
    read -p "Include testing framework? (Y/n): " INCLUDE_TESTS
    if [[ $INCLUDE_TESTS =~ ^[Nn]$ ]]; then
        INCLUDE_TESTS=false
    else
        INCLUDE_TESTS=true
    fi

    # Include documentation
    read -p "Include documentation setup? (Y/n): " INCLUDE_DOCS
    if [[ $INCLUDE_DOCS =~ ^[Nn]$ ]]; then
        INCLUDE_DOCS=false
    else
        INCLUDE_DOCS=true
    fi

    # Virtual environment
    read -p "Create virtual environment? (Y/n): " CREATE_VENV
    if [[ $CREATE_VENV =~ ^[Nn]$ ]]; then
        CREATE_VENV=false
    else
        CREATE_VENV=true
    fi

    log_success "Project configuration complete"
}

# Create project directory
create_project_directory() {
    log_info "Creating project directory: $PROJECT_NAME"

    if [[ -d "$PROJECT_NAME" ]]; then
        log_error "Directory '$PROJECT_NAME' already exists"
        exit 1
    fi

    mkdir -p "$PROJECT_NAME"
    cd "$PROJECT_NAME"

    log_success "Project directory created"
}

# Create virtual environment
create_virtual_environment() {
    if [[ "$CREATE_VENV" == "true" ]]; then
        log_info "Creating virtual environment..."

        python3 -m venv venv

        # Activate virtual environment
        source venv/bin/activate

        # Upgrade pip
        pip install --upgrade pip

        log_success "Virtual environment created and activated"
    fi
}

# Create project structure
create_project_structure() {
    log_info "Creating project structure..."

    # Create directories
    mkdir -p src tests docs scripts

    # Create Python package structure
    mkdir -p "src/${PROJECT_NAME//-/_}"

    # Create __init__.py files
    touch "src/__init__.py"
    touch "src/${PROJECT_NAME//-/_}/__init__.py"

    # Create main module files based on project type
    case $PROJECT_TYPE in
        1) # Web API
            create_web_api_files
            ;;
        2) # CLI Tool
            create_cli_files
            ;;
        3) # Data Science/ML
            create_ml_files
            ;;
        4) # Library/Package
            create_library_files
            ;;
        5) # Desktop App
            create_desktop_files
            ;;
        6) # Minimal
            create_minimal_files
            ;;
    esac

    # Create configuration files
    create_config_files

    log_success "Project structure created"
}

# Create Web API files
create_web_api_files() {
    # Choose framework
    echo ""
    echo "Select web framework:"
    echo "1. FastAPI (recommended)"
    echo "2. Flask"
    read -p "Choose framework [1]: " WEB_FRAMEWORK
    WEB_FRAMEWORK=${WEB_FRAMEWORK:-1}

    if [[ $WEB_FRAMEWORK -eq 1 ]]; then
        # FastAPI
        cat << EOF > "src/${PROJECT_NAME//-/_}/main.py"
"""
${PROJECT_NAME} - ${PROJECT_DESC}
FastAPI web application
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn
from typing import List, Optional

app = FastAPI(
    title="${PROJECT_NAME}",
    description="${PROJECT_DESC}",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Data models
class Item(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    price: float

# In-memory storage (replace with database in production)
items_db = []
next_id = 1

@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "Welcome to ${PROJECT_NAME} API", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}

@app.get("/items", response_model=List[Item])
async def get_items():
    """Get all items"""
    return items_db

@app.get("/items/{item_id}", response_model=Item)
async def get_item(item_id: int):
    """Get item by ID"""
    for item in items_db:
        if item.id == item_id:
            return item
    raise HTTPException(status_code=404, detail="Item not found")

@app.post("/items", response_model=Item)
async def create_item(item: Item):
    """Create new item"""
    global next_id
    new_item = Item(id=next_id, **item.dict())
    items_db.append(new_item)
    next_id += 1
    return new_item

@app.put("/items/{item_id}", response_model=Item)
async def update_item(item_id: int, updated_item: Item):
    """Update item by ID"""
    for i, item in enumerate(items_db):
        if item.id == item_id:
            items_db[i] = updated_item
            return updated_item
    raise HTTPException(status_code=404, detail="Item not found")

@app.delete("/items/{item_id}")
async def delete_item(item_id: int):
    """Delete item by ID"""
    for i, item in enumerate(items_db):
        if item.id == item_id:
            del items_db[i]
            return {"message": "Item deleted"}
    raise HTTPException(status_code=404, detail="Item not found")

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
EOF

        # Create requirements.txt
        cat << EOF > requirements.txt
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
python-multipart==0.0.6
EOF

    else
        # Flask
        cat << EOF > "src/${PROJECT_NAME//-/_}/app.py"
"""
${PROJECT_NAME} - ${PROJECT_DESC}
Flask web application
"""

from flask import Flask, jsonify, request, abort
from flask_cors import CORS
import os
from datetime import datetime

app = Flask(__name__)
CORS(app)

# Configuration
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key')

# In-memory storage (replace with database in production)
items_db = {}
next_id = 1

@app.route('/')
def index():
    """Root endpoint"""
    return jsonify({
        'message': 'Welcome to ${PROJECT_NAME} API',
        'version': '1.0.0',
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy'})

@app.route('/items', methods=['GET'])
def get_items():
    """Get all items"""
    return jsonify(list(items_db.values()))

@app.route('/items/<int:item_id>', methods=['GET'])
def get_item(item_id):
    """Get item by ID"""
    if item_id not in items_db:
        abort(404, description="Item not found")
    return jsonify(items_db[item_id])

@app.route('/items', methods=['POST'])
def create_item():
    """Create new item"""
    global next_id

    if not request.is_json:
        abort(400, description="Request must be JSON")

    data = request.get_json()

    # Validate required fields
    if 'name' not in data or 'price' not in data:
        abort(400, description="Name and price are required")

    item = {
        'id': next_id,
        'name': data['name'],
        'description': data.get('description', ''),
        'price': float(data['price']),
        'created_at': datetime.utcnow().isoformat()
    }

    items_db[next_id] = item
    next_id += 1

    return jsonify(item), 201

@app.route('/items/<int:item_id>', methods=['PUT'])
def update_item(item_id):
    """Update item by ID"""
    if item_id not in items_db:
        abort(404, description="Item not found")

    if not request.is_json:
        abort(400, description="Request must be JSON")

    data = request.get_json()
    item = items_db[item_id]

    # Update fields
    if 'name' in data:
        item['name'] = data['name']
    if 'description' in data:
        item['description'] = data['description']
    if 'price' in data:
        item['price'] = float(data['price'])

    item['updated_at'] = datetime.utcnow().isoformat()

    return jsonify(item)

@app.route('/items/<int:item_id>', methods=['DELETE'])
def delete_item(item_id):
    """Delete item by ID"""
    if item_id not in items_db:
        abort(404, description="Item not found")

    del items_db[item_id]
    return jsonify({'message': 'Item deleted'})

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': str(error)}), 404

@app.errorhandler(400)
def bad_request(error):
    return jsonify({'error': str(error)}), 400

if __name__ == '__main__':
    app.run(
        host='0.0.0.0',
        port=int(os.environ.get('PORT', 5000)),
        debug=os.environ.get('FLASK_ENV') == 'development'
    )
EOF

        # Create requirements.txt
        cat << EOF > requirements.txt
Flask==3.0.0
Flask-CORS==4.0.0
Werkzeug==3.0.1
EOF
    fi
}

# Create CLI tool files
create_cli_files() {
    cat << EOF > "src/${PROJECT_NAME//-/_}/cli.py"
"""
${PROJECT_NAME} - ${PROJECT_DESC}
Command-line interface
"""

import argparse
import sys
from pathlib import Path

def greet(name: str = "World", count: int = 1) -> None:
    """Greet someone multiple times"""
    for i in range(count):
        print(f"Hello, {name}! (#{i+1})")

def count_words(file_path: str) -> None:
    """Count words in a file"""
    try:
        path = Path(file_path)
        if not path.exists():
            print(f"Error: File '{file_path}' not found")
            return

        content = path.read_text()
        words = len(content.split())
        lines = len(content.splitlines())
        chars = len(content)

        print(f"File: {file_path}")
        print(f"Lines: {lines}")
        print(f"Words: {words}")
        print(f"Characters: {chars}")

    except Exception as e:
        print(f"Error reading file: {e}")

def main():
    """Main CLI entry point"""
    parser = argparse.ArgumentParser(
        description="${PROJECT_DESC}",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s greet --name Alice --count 3
  %(prog)s count-words README.md
        """
    )

    subparsers = parser.add_subparsers(dest='command', help='Available commands')

    # Greet command
    greet_parser = subparsers.add_parser('greet', help='Greet someone')
    greet_parser.add_argument('--name', '-n', default='World', help='Name to greet')
    greet_parser.add_argument('--count', '-c', type=int, default=1, help='Number of greetings')

    # Count words command
    count_parser = subparsers.add_parser('count-words', help='Count words in a file')
    count_parser.add_argument('file', help='File to analyze')

    # Version
    parser.add_argument('--version', action='version', version='%(prog)s 1.0.0')

    args = parser.parse_args()

    if args.command == 'greet':
        greet(args.name, args.count)
    elif args.command == 'count-words':
        count_words(args.file)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
EOF

    # Create __main__.py for direct execution
    cat << EOF > "src/${PROJECT_NAME//-/_}/__main__.py"
"""
Entry point for running as a module
"""

from .cli import main

if __name__ == "__main__":
    main()
EOF

    # Create setup.py for CLI tool
    cat << EOF > setup.py
"""
Setup script for ${PROJECT_NAME}
"""

from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="${PROJECT_NAME}",
    version="1.0.0",
    author="${AUTHOR}",
    author_email="${AUTHOR_EMAIL}",
    description="${PROJECT_DESC}",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="${GIT_REPO}",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
    python_requires=">=3.8",
    entry_points={
        'console_scripts': [
            '${PROJECT_NAME//-/_}=${PROJECT_NAME//-/_}.cli:main',
        ],
    },
)
EOF

    # Create requirements.txt
    cat << EOF > requirements.txt
# No external dependencies for basic CLI
EOF
}

# Create ML/Data Science files
create_ml_files() {
    cat << EOF > "src/${PROJECT_NAME//-/_}/data_processor.py"
"""
${PROJECT_NAME} - Data Processing Module
"""

import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.model_selection import train_test_split
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DataProcessor:
    """Data processing utilities for machine learning"""

    def __init__(self):
        self.scaler = StandardScaler()
        self.encoders = {}

    def load_data(self, file_path: str, **kwargs) -> pd.DataFrame:
        """Load data from various file formats"""
        if file_path.endswith('.csv'):
            return pd.read_csv(file_path, **kwargs)
        elif file_path.endswith('.json'):
            return pd.read_json(file_path, **kwargs)
        elif file_path.endswith(('.xlsx', '.xls')):
            return pd.read_excel(file_path, **kwargs)
        else:
            raise ValueError(f"Unsupported file format: {file_path}")

    def clean_data(self, df: pd.DataFrame) -> pd.DataFrame:
        """Basic data cleaning"""
        logger.info("Cleaning data...")

        # Remove duplicates
        df = df.drop_duplicates()

        # Handle missing values
        df = df.dropna()

        # Reset index
        df = df.reset_index(drop=True)

        logger.info(f"Data cleaned. Shape: {df.shape}")
        return df

    def preprocess_features(self, df: pd.DataFrame, target_column: str = None) -> tuple:
        """Preprocess features for machine learning"""
        logger.info("Preprocessing features...")

        # Separate features and target
        if target_column:
            X = df.drop(columns=[target_column])
            y = df[target_column]
        else:
            X = df
            y = None

        # Handle categorical variables
        categorical_cols = X.select_dtypes(include=['object', 'category']).columns

        for col in categorical_cols:
            if col not in self.encoders:
                self.encoders[col] = LabelEncoder()
            X[col] = self.encoders[col].fit_transform(X[col])

        # Scale numerical features
        numerical_cols = X.select_dtypes(include=[np.number]).columns
        if len(numerical_cols) > 0:
            X[numerical_cols] = self.scaler.fit_transform(X[numerical_cols])

        return X, y

    def split_data(self, X, y, test_size: float = 0.2, random_state: int = 42):
        """Split data into training and testing sets"""
        return train_test_split(X, y, test_size=test_size, random_state=random_state)
EOF

    cat << EOF > "src/${PROJECT_NAME//-/_}/model_trainer.py"
"""
${PROJECT_NAME} - Model Training Module
"""

from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.linear_model import LogisticRegression, LinearRegression
from sklearn.svm import SVC, SVR
from sklearn.metrics import accuracy_score, mean_squared_error, classification_report
import joblib
import logging
from typing import Dict, Any

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ModelTrainer:
    """Machine learning model training utilities"""

    def __init__(self, model_type: str = 'classification'):
        self.model_type = model_type
        self.model = None

    def get_models(self) -> Dict[str, Any]:
        """Get available models based on type"""
        if self.model_type == 'classification':
            return {
                'random_forest': RandomForestClassifier(n_estimators=100, random_state=42),
                'logistic_regression': LogisticRegression(random_state=42),
                'svm': SVC(random_state=42)
            }
        else:  # regression
            return {
                'random_forest': RandomForestRegressor(n_estimators=100, random_state=42),
                'linear_regression': LinearRegression(),
                'svm': SVR()
            }

    def train_model(self, X_train, y_train, model_name: str = 'random_forest'):
        """Train a model"""
        logger.info(f"Training {model_name} model...")

        models = self.get_models()
        if model_name not in models:
            raise ValueError(f"Model {model_name} not found. Available: {list(models.keys())}")

        self.model = models[model_name]
        self.model.fit(X_train, y_train)

        logger.info("Model training completed")
        return self.model

    def evaluate_model(self, X_test, y_test):
        """Evaluate model performance"""
        if self.model is None:
            raise ValueError("No model trained yet")

        y_pred = self.model.predict(X_test)

        if self.model_type == 'classification':
            accuracy = accuracy_score(y_test, y_pred)
            report = classification_report(y_test, y_pred)

            logger.info(f"Model Accuracy: {accuracy:.4f}")
            print("Classification Report:")
            print(report)

            return {'accuracy': accuracy, 'report': report}
        else:
            mse = mean_squared_error(y_test, y_pred)
            rmse = mse ** 0.5

            logger.info(f"Model RMSE: {rmse:.4f}")
            print(f"MSE: {mse:.4f}")
            print(f"RMSE: {rmse:.4f}")

            return {'mse': mse, 'rmse': rmse}

    def save_model(self, filepath: str):
        """Save trained model"""
        if self.model is None:
            raise ValueError("No model trained yet")

        joblib.dump(self.model, filepath)
        logger.info(f"Model saved to {filepath}")

    def load_model(self, filepath: str):
        """Load trained model"""
        self.model = joblib.load(filepath)
        logger.info(f"Model loaded from {filepath}")
        return self.model
EOF

    cat << EOF > "notebooks/analysis.ipynb"
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# ${PROJECT_NAME} - Data Analysis Notebook\n",
    "\n",
    "This notebook demonstrates data analysis and machine learning workflows using ${PROJECT_NAME}.\n",
    "\n",
    "## Setup"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Import required libraries\n",
    "import sys\n",
    "import os\n",
    "sys.path.append('../src')\n",
    "\n",
    "import pandas as pd\n",
    "import numpy as np\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "\n",
    "from ${PROJECT_NAME//-/_}.data_processor import DataProcessor\n",
    "from ${PROJECT_NAME//-/_}.model_trainer import ModelTrainer\n",
    "\n",
    "# Set up plotting\n",
    "plt.style.use('seaborn-v0_8')\n",
    "%matplotlib inline"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Data Loading and Exploration"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Initialize data processor\n",
    "processor = DataProcessor()\n",
    "\n",
    "# Load your data (replace with your data file)\n",
    "# df = processor.load_data('data/your_data.csv')\n",
    "# print(df.head())\n",
    "# print(df.info())\n",
    "\n",
    "print(\"Data loading example - replace with your data file\")"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Model Training Example"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Initialize model trainer\n",
    "trainer = ModelTrainer(model_type='classification')\n",
    "\n",
    "# Example training (replace with your actual data)\n",
    "# X_train, X_test, y_train, y_test = processor.split_data(X, y)\n",
    "# model = trainer.train_model(X_train, y_train, 'random_forest')\n",
    "# results = trainer.evaluate_model(X_test, y_test)\n",
    "\n",
    "print(\"Model training example - replace with your actual data\")"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.8.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

    # Create requirements.txt
    cat << EOF > requirements.txt
pandas==2.1.3
numpy==1.24.3
scikit-learn==1.3.2
matplotlib==3.8.0
seaborn==0.12.2
jupyter==1.0.0
joblib==1.3.2
EOF

    # Create data directory
    mkdir -p data notebooks
}

# Create library/package files
create_library_files() {
    cat << EOF > "src/${PROJECT_NAME//-/_}/core.py"
"""
${PROJECT_NAME} - Core functionality
"""

def hello_world(name: str = "World") -> str:
    """Return a greeting message"""
    return f"Hello, {name}!"

def calculate_sum(*args: float) -> float:
    """Calculate the sum of given numbers"""
    return sum(args)

def is_even(number: int) -> bool:
    """Check if a number is even"""
    return number % 2 == 0

class Calculator:
    """Simple calculator class"""

    def add(self, a: float, b: float) -> float:
        """Add two numbers"""
        return a + b

    def subtract(self, a: float, b: float) -> float:
        """Subtract two numbers"""
        return a - b

    def multiply(self, a: float, b: float) -> float:
        """Multiply two numbers"""
        return a * b

    def divide(self, a: float, b: float) -> float:
        """Divide two numbers"""
        if b == 0:
            raise ValueError("Cannot divide by zero")
        return a / b
EOF

    # Create setup.py
    cat << EOF > setup.py
"""
Setup script for ${PROJECT_NAME}
"""

from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="${PROJECT_NAME}",
    version="1.0.0",
    author="${AUTHOR}",
    author_email="${AUTHOR_EMAIL}",
    description="${PROJECT_DESC}",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="${GIT_REPO}",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
    python_requires=">=3.8",
)
EOF

    # Create requirements.txt
    cat << EOF > requirements.txt
# No external dependencies for basic library
EOF
}

# Create desktop app files
create_desktop_files() {
    # Choose GUI framework
    echo ""
    echo "Select GUI framework:"
    echo "1. Tkinter (built-in)"
    echo "2. PyQt6"
    read -p "Choose framework [1]: " GUI_FRAMEWORK
    GUI_FRAMEWORK=${GUI_FRAMEWORK:-1}

    if [[ $GUI_FRAMEWORK -eq 1 ]]; then
        # Tkinter
        cat << EOF > "src/${PROJECT_NAME//-/_}/gui.py"
"""
${PROJECT_NAME} - Tkinter GUI Application
"""

import tkinter as tk
from tkinter import ttk, messagebox
import sys

class ${PROJECT_NAME//-/_}App:
    """Main application class"""

    def __init__(self, root):
        self.root = root
        self.root.title("${PROJECT_NAME}")
        self.root.geometry("400x300")

        self.setup_ui()

    def setup_ui(self):
        """Set up the user interface"""
        # Create main frame
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))

        # Title
        title_label = ttk.Label(main_frame, text="${PROJECT_DESC}",
                               font=("Arial", 14, "bold"))
        title_label.grid(row=0, column=0, columnspan=2, pady=(0, 20))

        # Input field
        ttk.Label(main_frame, text="Enter your name:").grid(row=1, column=0, sticky=tk.W, pady=5)
        self.name_entry = ttk.Entry(main_frame, width=30)
        self.name_entry.grid(row=1, column=1, pady=5, padx=(10, 0))

        # Buttons
        button_frame = ttk.Frame(main_frame)
        button_frame.grid(row=2, column=0, columnspan=2, pady=20)

        ttk.Button(button_frame, text="Greet", command=self.greet).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="Clear", command=self.clear).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="Quit", command=self.quit).pack(side=tk.LEFT, padx=5)

        # Result label
        self.result_label = ttk.Label(main_frame, text="", foreground="blue")
        self.result_label.grid(row=3, column=0, columnspan=2, pady=10)

        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)

    def greet(self):
        """Handle greet button click"""
        name = self.name_entry.get().strip()
        if name:
            greeting = f"Hello, {name}! Welcome to ${PROJECT_NAME}!"
            self.result_label.config(text=greeting)
        else:
            messagebox.showwarning("Input Required", "Please enter your name.")

    def clear(self):
        """Clear the input and result"""
        self.name_entry.delete(0, tk.END)
        self.result_label.config(text="")

    def quit(self):
        """Quit the application"""
        if messagebox.askyesno("Quit", "Are you sure you want to quit?"):
            self.root.quit()

def main():
    """Main entry point"""
    root = tk.Tk()
    app = ${PROJECT_NAME//-/_}App(root)
    root.mainloop()

if __name__ == "__main__":
    main()
EOF

        # Create requirements.txt
        cat << EOF > requirements.txt
# Tkinter is included with Python
EOF

    else
        # PyQt6
        cat << EOF > "src/${PROJECT_NAME//-/_}/gui.py"
"""
${PROJECT_NAME} - PyQt6 GUI Application
"""

import sys
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout,
                             QHBoxLayout, QLabel, QLineEdit, QPushButton, QMessageBox)
from PyQt6.QtCore import Qt
from PyQt6.QtGui import QFont

class ${PROJECT_NAME//-/_}App(QMainWindow):
    """Main application window"""

    def __init__(self):
        super().__init__()
        self.setWindowTitle("${PROJECT_NAME}")
        self.setGeometry(100, 100, 400, 300)

        self.setup_ui()

    def setup_ui(self):
        """Set up the user interface"""
        # Create central widget
        central_widget = QWidget()
        self.setCentralWidget(central_widget)

        # Create main layout
        layout = QVBoxLayout(central_widget)

        # Title
        title_label = QLabel("${PROJECT_DESC}")
        title_font = QFont()
        title_font.setPointSize(14)
        title_font.setBold(True)
        title_label.setFont(title_font)
        title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(title_label)

        # Input section
        input_layout = QHBoxLayout()
        input_label = QLabel("Enter your name:")
        self.name_input = QLineEdit()
        self.name_input.setPlaceholderText("Your name here...")

        input_layout.addWidget(input_label)
        input_layout.addWidget(self.name_input)
        layout.addLayout(input_layout)

        # Buttons
        button_layout = QHBoxLayout()

        greet_button = QPushButton("Greet")
        greet_button.clicked.connect(self.greet)

        clear_button = QPushButton("Clear")
        clear_button.clicked.connect(self.clear)

        quit_button = QPushButton("Quit")
        quit_button.clicked.connect(self.quit_app)

        button_layout.addWidget(greet_button)
        button_layout.addWidget(clear_button)
        button_layout.addWidget(quit_button)
        layout.addLayout(button_layout)

        # Result label
        self.result_label = QLabel("")
        self.result_label.setStyleSheet("color: blue; font-weight: bold;")
        self.result_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(self.result_label)

        # Add stretch to push everything to the top
        layout.addStretch()

    def greet(self):
        """Handle greet button click"""
        name = self.name_input.text().strip()
        if name:
            greeting = f"Hello, {name}! Welcome to ${PROJECT_NAME}!"
            self.result_label.setText(greeting)
        else:
            QMessageBox.warning(self, "Input Required", "Please enter your name.")

    def clear(self):
        """Clear the input and result"""
        self.name_input.clear()
        self.result_label.clear()

    def quit_app(self):
        """Quit the application"""
        reply = QMessageBox.question(self, "Quit", "Are you sure you want to quit?",
                                   QMessageBox.StandardButton.Yes |
                                   QMessageBox.StandardButton.No)

        if reply == QMessageBox.StandardButton.Yes:
            QApplication.quit()

def main():
    """Main entry point"""
    app = QApplication(sys.argv)
    window = ${PROJECT_NAME//-/_}App()
    window.show()
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
EOF

        # Create requirements.txt
        cat << EOF > requirements.txt
PyQt6==6.5.3
PyQt6-Qt6==6.5.3
EOF
    fi
}

# Create minimal files
create_minimal_files() {
    cat << EOF > "src/${PROJECT_NAME//-/_}/main.py"
"""
${PROJECT_NAME} - ${PROJECT_DESC}
Main module
"""

def main():
    """Main function"""
    print(f"Hello from ${PROJECT_NAME}!")
    print(f"Description: ${PROJECT_DESC}")
    print(f"Author: ${AUTHOR}")
    print("Version: 1.0.0")

if __name__ == "__main__":
    main()
EOF

    # Create requirements.txt
    cat << EOF > requirements.txt
# No external dependencies
EOF
}

# Create configuration files
create_config_files() {
    # setup.py (legacy) unless user chose pyproject-only
    if [[ "$USE_PYPROJECT_ONLY" != "true" ]]; then
        if [[ $PROJECT_TYPE -eq 4 ]]; then
            # Already created in create_library_files
            :
        else
            cat << EOF > setup.py
"""
Setup script for ${PROJECT_NAME}
"""

from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="${PROJECT_NAME}",
    version="1.0.0",
    author="${AUTHOR}",
    author_email="${AUTHOR_EMAIL}",
    description="${PROJECT_DESC}",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="${GIT_REPO}",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
    python_requires=">=3.8",
    install_requires=[],
)
EOF
        fi
    fi

    # pyproject.toml (always generate)
    cat << EOF > pyproject.toml
[build-system]
requires = ["setuptools>=45", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "${PROJECT_NAME}"
version = "1.0.0"
description = "${PROJECT_DESC}"
authors = [{name = "${AUTHOR}", email = "${AUTHOR_EMAIL}"}]
readme = "README.md"
requires-python = ">=3.8"
classifiers = [
    "Development Status :: 3 - Alpha",
    "Intended Audience :: Developers",
    "License :: OSI Approved :: MIT License",
    "Programming Language :: Python :: 3",
]
dependencies = []

[project.urls]
Homepage = "${GIT_REPO}"
Repository = "${GIT_REPO}"

[tool.setuptools]
package-dir = {"" = "src"}

[tool.setuptools.packages.find]
where = ["src"]
EOF

    # .gitignore
    cat << EOF > .gitignore
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# C extensions
*.so

# Distribution / packaging
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
pip-wheel-metadata/
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# PyInstaller
*.manifest
*.spec

# Installer logs
pip-log.txt
pip-delete-this-directory.txt

# Unit test / coverage reports
htmlcov/
.tox/
.nox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
*.py,cover
.hypothesis/
.pytest_cache/

# Translations
*.mo
*.pot

# Django stuff:
*.log
local_settings.py
db.sqlite3
db.sqlite3-journal

# Flask stuff:
instance/
.webassets-cache

# Scrapy stuff:
.scrapy

# Sphinx documentation
docs/_build/

# PyBuilder
target/

# Jupyter Notebook
.ipynb_checkpoints

# IPython
profile_default/
ipython_config.py

# pyenv
.python-version

# pipenv
Pipfile.lock

# PEP 582
__pypackages__/

# Celery stuff
celerybeat-schedule
celerybeat.pid

# SageMath parsed files
*.sage.py

# Environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# Spyder project settings
.spyderproject
.spyproject

# Rope project settings
.ropeproject

# mkdocs documentation
/site

# mypy
.mypy_cache/
.dmypy.json
dmypy.json

# Pyre type checker
.pyre/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
EOF

    # README.md
    cat << EOF > README.md
# ${PROJECT_NAME}

${PROJECT_DESC}

## Installation

### From Source
\`\`\`bash
git clone ${GIT_REPO}
cd ${PROJECT_NAME}
pip install -e .
\`\`\`

### From PyPI (when published)
\`\`\`bash
pip install ${PROJECT_NAME}
\`\`\`

## Usage

### Basic Usage
\`\`\`python
from ${PROJECT_NAME//-/_} import hello_world

print(hello_world("Python"))
\`\`\`

### Command Line (if applicable)
\`\`\`bash
${PROJECT_NAME//-/_} --help
\`\`\`

## Development

### Setup Development Environment
\`\`\`bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\\Scripts\\activate

# Install dependencies
pip install -e ".[dev]"
\`\`\`

### Running Tests
\`\`\`bash
pytest
\`\`\`

### Code Quality
\`\`\`bash
# Format code
black src/

# Lint code
flake8 src/

# Type checking
mypy src/
\`\`\`

## Project Structure

\`\`\`
${PROJECT_NAME}/
├── src/
│   └── ${PROJECT_NAME//-/_}/
│       ├── __init__.py
│       └── main.py
├── tests/
├── docs/
├── scripts/
├── pyproject.toml
├── setup.py
├── requirements.txt
└── README.md
\`\`\`

## Contributing

1. Fork the repository
2. Create your feature branch (\`git checkout -b feature/amazing-feature\`)
3. Commit your changes (\`git commit -m 'Add some amazing feature'\`)
4. Push to the branch (\`git push origin feature/amazing-feature\`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

${AUTHOR}
EOF

    # Create basic test file if testing is enabled
    if [[ "$INCLUDE_TESTS" == "true" ]]; then
        mkdir -p tests
        cat << EOF > tests/__init__.py
# Tests package
EOF

        cat << EOF > tests/test_basic.py
"""
Basic tests for ${PROJECT_NAME}
"""

import pytest
from ${PROJECT_NAME//-/_}.main import main

def test_main_function(capsys):
    """Test the main function"""
    main()
    captured = capsys.readouterr()
    assert "Hello from ${PROJECT_NAME}!" in captured.out

def test_placeholder():
    """Placeholder test"""
    assert True
EOF

        # Add pytest to requirements if testing enabled
        echo "pytest==7.4.3" >> requirements.txt
        echo "pytest-cov==4.1.0" >> requirements.txt
    fi

    # Create docs structure if documentation is enabled
    if [[ "$INCLUDE_DOCS" == "true" ]]; then
        mkdir -p docs
        cat << EOF > docs/index.md
# ${PROJECT_NAME} Documentation

${PROJECT_DESC}

## Getting Started

TODO: Add getting started guide

## API Reference

TODO: Add API documentation

## Examples

TODO: Add usage examples
EOF

        # Add sphinx to requirements if docs enabled
        echo "sphinx==7.2.6" >> requirements.txt
        echo "sphinx-rtd-theme==1.3.0" >> requirements.txt
    fi
}

# Install dependencies
install_dependencies() {
    log_info "Installing dependencies..."

    if [[ -f "requirements.txt" ]]; then
        pip install -r requirements.txt
        log_success "Dependencies installed"
    else
        log_warning "No requirements.txt found"
    fi
}

# Initialize git repository
initialize_git() {
    if [[ -n "$GIT_REPO" ]]; then
        log_info "Initializing Git repository..."

        git init
        git add .
        git commit -m "Initial commit: ${PROJECT_DESC}"

        if [[ -n "$GIT_REPO" ]]; then
            git remote add origin "$GIT_REPO"
            log_info "Added remote origin: $GIT_REPO"
        fi

        log_success "Git repository initialized"
    fi
}

# Display project summary
display_summary() {
    log_header "Project Created Successfully!"

    echo "📁 Project: $PROJECT_NAME"
    echo "📍 Location: $(pwd)"
    echo "📝 Description: $PROJECT_DESC"
    echo "👤 Author: $AUTHOR"
    echo ""

    if [[ "$CREATE_VENV" == "true" ]]; then
        echo "🐍 Virtual Environment: Created and activated"
        echo "   To activate later: source venv/bin/activate"
        echo ""
    fi

    echo "🚀 Quick Start:"
    if [[ -f "src/${PROJECT_NAME//-/_}/main.py" ]]; then
        echo "  python -m ${PROJECT_NAME//-/_}.main"
    fi
    if [[ -f "src/${PROJECT_NAME//-/_}/cli.py" ]]; then
        echo "  python -m ${PROJECT_NAME//-/_} --help"
    fi
    if [[ -f "src/${PROJECT_NAME//-/_}/gui.py" ]]; then
        echo "  python -m ${PROJECT_NAME//-/_}.gui"
    fi
    echo ""

    if [[ "$INCLUDE_TESTS" == "true" ]]; then
        echo "🧪 Testing:"
        echo "  python -m pytest"
        echo ""
    fi

    if [[ "$INCLUDE_DOCS" == "true" ]]; then
        echo "📚 Documentation:"
        echo "  cd docs && make html"
        echo ""
    fi

    echo "📦 Next Steps:"
    echo "  1. Review and customize the generated files"
    echo "  2. Add your application logic"
    echo "  3. Write comprehensive tests"
    echo "  4. Update documentation"
    echo ""

    log_success "Happy coding! 🐍"
}

# Main function
main() {
    log_header "Python Project Quickstart"

    check_prerequisites
    get_project_info "$@"
    create_project_directory
    create_virtual_environment
    create_project_structure
    install_dependencies
    initialize_git
    display_summary
}

# Run main function
main "$@"
