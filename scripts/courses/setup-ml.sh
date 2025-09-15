#!/bin/bash
# Machine Learning Course Setup Script
# Installs ML tools and frameworks for machine learning courses

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Detect platform
detect_platform() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            if [[ "$ID" == "ubuntu" ]] || [[ "$ID" == "debian" ]] || [[ "$ID" == "pop" ]] || [[ "$ID" == "elementary" ]] || [[ "$ID" == "linuxmint" ]]; then
                PLATFORM="ubuntu"
            elif [[ "$ID" == "centos" ]] || [[ "$ID" == "rhel" ]] || [[ "$ID" == "fedora" ]]; then
                PLATFORM="redhat"
            elif [[ "$ID" == "arch" ]] || [[ "$ID" == "manjaro" ]]; then
                PLATFORM="arch"
            else
                PLATFORM="linux"
            fi
        else
            PLATFORM="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        PLATFORM="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        PLATFORM="windows"
    else
        log_error "Unsupported platform: $OSTYPE"
        exit 1
    fi

    log_success "Detected platform: $PLATFORM"
}

# Check Python
check_python() {
    if ! command -v python &>/dev/null && ! command -v python3 &>/dev/null; then
        log_error "Python is required. Please run the platform setup script first."
        exit 1
    fi

    if ! command -v pip &>/dev/null && ! command -v pip3 &>/dev/null; then
        log_error "pip is required. Please run the platform setup script first."
        exit 1
    fi

    log_success "Python found"
}

# Install Jupyter and scientific Python stack
install_jupyter() {
    log_info "Installing Jupyter and scientific Python stack..."

    pip install --user jupyter jupyterlab notebook
    pip install --user numpy scipy matplotlib pandas
    pip install --user scikit-learn seaborn plotly bokeh

    # Install Jupyter extensions
    pip install --user jupyter-contrib-nbextensions
    jupyter contrib nbextension install --user

    # Install JupyterLab extensions
    pip install --user jupyterlab-git
    pip install --user jupyterlab-drawio

    log_success "Jupyter and scientific stack installed"
}

# Install TensorFlow
install_tensorflow() {
    log_info "Installing TensorFlow..."

    # Check if CUDA is available (for GPU support)
    if command -v nvidia-smi &>/dev/null; then
        log_info "NVIDIA GPU detected, installing TensorFlow with GPU support"
        pip install --user tensorflow[and-cuda]
    else
        log_info "No NVIDIA GPU detected, installing CPU-only TensorFlow"
        pip install --user tensorflow-cpu
    fi

    # Install additional TensorFlow tools
    pip install --user tensorflow-datasets tensorflow-hub tensorflow-probability

    log_success "TensorFlow installed"
}

# Install PyTorch
install_pytorch() {
    log_info "Installing PyTorch..."

    # Detect CUDA version for GPU support
    if command -v nvidia-smi &>/dev/null; then
        log_info "Installing PyTorch with CUDA support"
        pip install --user torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
    else
        log_info "Installing PyTorch CPU-only"
        pip install --user torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
    fi

    # Install additional PyTorch tools
    pip install --user torchtext torchmetrics pytorch-lightning

    log_success "PyTorch installed"
}

# Install scikit-learn and ML libraries
install_scikit_learn() {
    log_info "Installing scikit-learn and ML libraries..."

    pip install --user scikit-learn xgboost lightgbm catboost
    pip install --user imbalanced-learn yellowbrick
    pip install --user optuna hyperopt

    log_success "scikit-learn and ML libraries installed"
}

# Install computer vision libraries
install_cv_libraries() {
    log_info "Installing computer vision libraries..."

    pip install --user opencv-python opencv-contrib-python
    pip install --user pillow scikit-image
    pip install --user albumentations

    log_success "Computer vision libraries installed"
}

# Install NLP libraries
install_nlp_libraries() {
    log_info "Installing NLP libraries..."

    pip install --user nltk spacy transformers datasets
    pip install --user gensim textblob vaderSentiment

    # Download NLTK data
    python -c "import nltk; nltk.download('punkt'); nltk.download('stopwords'); nltk.download('wordnet')"

    # Download spaCy model
    python -c "import spacy; spacy.cli.download('en_core_web_sm')"

    log_success "NLP libraries installed"
}

# Install visualization libraries
install_visualization() {
    log_info "Installing visualization libraries..."

    pip install --user matplotlib seaborn plotly bokeh
    pip install --user altair streamlit panel
    pip install --user plotly dash

    log_success "Visualization libraries installed"
}

# Install additional ML tools
install_ml_tools() {
    log_info "Installing additional ML tools..."

    pip install --user mlflow dvc kedro
    pip install --user wandb comet-ml
    pip install --user joblib pickle5

    log_success "Additional ML tools installed"
}

# Install GPU support (if available)
install_gpu_support() {
    log_info "Checking for GPU support..."

    if command -v nvidia-smi &>/dev/null; then
        log_info "NVIDIA GPU detected"

        # Install CUDA toolkit if not present
        case $PLATFORM in
            ubuntu)
                # Add CUDA repository
                wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
                sudo dpkg -i cuda-keyring_1.1-1_all.deb
                sudo apt update
                sudo apt install -y cuda-toolkit-12-2
                ;;
            redhat)
                # Add CUDA repository for RHEL
                log_info "Please install CUDA manually from NVIDIA website for RHEL/CentOS"
                ;;
            arch)
                sudo pacman -S --noconfirm cuda
                ;;
            macos)
                log_info "macOS GPU support requires manual setup"
                ;;
        esac

        # Install cuDNN (if CUDA was installed)
        if [[ -d /usr/local/cuda ]]; then
            log_info "CUDA toolkit found, cuDNN may need manual installation"
        fi

        log_success "GPU support configured"
    else
        log_info "No NVIDIA GPU detected, skipping GPU setup"
    fi
}

# Create ML course directory structure
create_course_structure() {
    log_info "Creating machine learning course directory structure..."

    local course_dir="$HOME/dev/current/ml-course"
    mkdir -p "$course_dir"/{notebooks,datasets,models,projects,scripts,reports}

    # Create sample Jupyter notebook
    cat << 'EOF' > "$course_dir/notebooks/ml-basics.ipynb"
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Machine Learning Basics\n",
    "\n",
    "This notebook covers basic machine learning concepts and implementations."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Import required libraries\n",
    "import numpy as np\n",
    "import pandas as pd\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "from sklearn.model_selection import train_test_split\n",
    "from sklearn.preprocessing import StandardScaler\n",
    "from sklearn.linear_model import LogisticRegression\n",
    "from sklearn.metrics import classification_report, confusion_matrix\n",
    "\n",
    "# Set random seed for reproducibility\n",
    "np.random.seed(42)\n",
    "\n",
    "print(\"Libraries imported successfully!\")"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Data Loading and Exploration\n",
    "\n",
    "Load a sample dataset and explore its characteristics."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Load sample dataset (Iris)\n",
    "from sklearn.datasets import load_iris\n",
    "iris = load_iris()\n",
    "X, y = iris.data, iris.target\n",
    "feature_names = iris.feature_names\n",
    "target_names = iris.target_names\n",
    "\n",
    "# Create DataFrame for easier exploration\n",
    "df = pd.DataFrame(X, columns=feature_names)\n",
    "df['target'] = y\n",
    "df['species'] = [target_names[i] for i in y]\n",
    "\n",
    "print(\"Dataset shape:\", df.shape)\n",
    "print(\"\\nFirst 5 rows:\")\n",
    "print(df.head())\n",
    "print(\"\\nTarget distribution:\")\n",
    "print(df['species'].value_counts())"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Data Visualization\n",
    "\n",
    "Visualize the relationships between features and classes."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Create scatter plots\n",
    "plt.figure(figsize=(12, 8))\n",
    "\n",
    "# Plot sepal length vs sepal width\n",
    "plt.subplot(2, 2, 1)\n",
    "for i, species in enumerate(target_names):\n",
    "    plt.scatter(df[df['species'] == species]['sepal length (cm)'],\n",
    "                df[df['species'] == species]['sepal width (cm)'],\n",
    "                label=species)\n",
    "plt.xlabel('Sepal Length (cm)')\n",
    "plt.ylabel('Sepal Width (cm)')\n",
    "plt.legend()\n",
    "plt.title('Sepal Dimensions')\n",
    "\n",
    "# Plot petal length vs petal width\n",
    "plt.subplot(2, 2, 2)\n",
    "for i, species in enumerate(target_names):\n",
    "    plt.scatter(df[df['species'] == species]['petal length (cm)'],\n",
    "                df[df['species'] == species]['petal width (cm)'],\n",
    "                label=species)\n",
    "plt.xlabel('Petal Length (cm)')\n",
    "plt.ylabel('Petal Width (cm)')\n",
    "plt.legend()\n",
    "plt.title('Petal Dimensions')\n",
    "\n",
    "plt.tight_layout()\n",
    "plt.show()"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Model Training\n",
    "\n",
    "Split the data and train a simple classifier."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Split the data\n",
    "X_train, X_test, y_train, y_test = train_test_split(\n",
    "    X, y, test_size=0.3, random_state=42, stratify=y\n",
    ")\n",
    "\n",
    "# Scale the features\n",
    "scaler = StandardScaler()\n",
    "X_train_scaled = scaler.fit_transform(X_train)\n",
    "X_test_scaled = scaler.transform(X_test)\n",
    "\n",
    "# Train a logistic regression model\n",
    "model = LogisticRegression(random_state=42, max_iter=1000)\n",
    "model.fit(X_train_scaled, y_train)\n",
    "\n",
    "# Make predictions\n",
    "y_pred = model.predict(X_test_scaled)\n",
    "\n",
    "print(\"Model training completed!\")\n",
    "print(\"Training accuracy:\", model.score(X_train_scaled, y_train))\n",
    "print(\"Test accuracy:\", model.score(X_test_scaled, y_test))"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Model Evaluation\n",
    "\n",
    "Evaluate the model's performance with detailed metrics."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Print classification report\n",
    "print(\"Classification Report:\")\n",
    "print(classification_report(y_test, y_pred, target_names=target_names))\n",
    "\n",
    "# Create confusion matrix\n",
    "cm = confusion_matrix(y_test, y_pred)\n",
    "plt.figure(figsize=(8, 6))\n",
    "sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',\n",
    "            xticklabels=target_names, yticklabels=target_names)\n",
    "plt.xlabel('Predicted')\n",
    "plt.ylabel('Actual')\n",
    "plt.title('Confusion Matrix')\n",
    "plt.show()"
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
   "version": "3.8.5"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

    # Create requirements.txt
    cat << 'EOF' > "$course_dir/requirements.txt"
# Machine Learning Course Requirements

# Core scientific computing
numpy>=1.21.0
scipy>=1.7.0
pandas>=1.3.0
matplotlib>=3.4.0
seaborn>=0.11.0

# Machine Learning
scikit-learn>=1.0.0
tensorflow-cpu>=2.8.0
torch>=1.11.0
torchvision>=0.12.0
torchaudio>=0.11.0

# Jupyter
jupyter>=1.0.0
jupyterlab>=3.2.0
notebook>=6.4.0

# Data visualization
plotly>=5.3.0
bokeh>=2.4.0
altair>=4.1.0

# Computer vision
opencv-python>=4.5.0
Pillow>=8.3.0
scikit-image>=0.19.0

# NLP
nltk>=3.7.0
spacy>=3.2.0
transformers>=4.11.0
datasets>=1.15.0

# Additional ML tools
xgboost>=1.5.0
lightgbm>=3.3.0
mlflow>=1.23.0
wandb>=0.12.0

# Development
pytest>=6.2.0
black>=21.9.0
flake8>=4.0.0
EOF

    # Create environment setup script
    cat << 'EOF' > "$course_dir/setup-environment.sh"
#!/bin/bash
# Setup ML environment

echo "Setting up ML environment..."

# Create virtual environment
python -m venv ml-env
source ml-env/bin/activate

# Install requirements
pip install -r requirements.txt

# Download NLTK data
python -c "import nltk; nltk.download('punkt'); nltk.download('stopwords'); nltk.download('wordnet')"

# Download spaCy model
python -c "import spacy; spacy.cli.download('en_core_web_sm')"

echo "ML environment setup complete!"
echo "Activate with: source ml-env/bin/activate"
EOF
    chmod +x "$course_dir/setup-environment.sh"

    # Create README
    cat << EOF > "$course_dir/README.md"
# Machine Learning Course

## Course Directory Structure
- \`notebooks/\`: Jupyter notebooks for lectures and exercises
- \`datasets/\`: Sample datasets and data loading scripts
- \`models/\`: Trained models and model artifacts
- \`projects/\`: Course projects and assignments
- \`scripts/\`: Utility scripts and automation
- \`reports/\`: Analysis reports and visualizations

## Getting Started

### 1. Set up the environment
\`\`\`bash
cd ~/dev/current/ml-course
./setup-environment.sh
\`\`\`

### 2. Start Jupyter Lab
\`\`\`bash
source ml-env/bin/activate
jupyter lab
\`\`\`

### 3. Open the sample notebook
Navigate to \`notebooks/ml-basics.ipynb\` in Jupyter Lab

## Frameworks and Libraries

### TensorFlow/Keras
\`\`\`python
import tensorflow as tf
from tensorflow import keras

# Build a simple neural network
model = keras.Sequential([
    keras.layers.Dense(64, activation='relu', input_shape=(784,)),
    keras.layers.Dense(10, activation='softmax')
])

model.compile(optimizer='adam',
              loss='sparse_categorical_crossentropy',
              metrics=['accuracy'])
\`\`\`

### PyTorch
\`\`\`python
import torch
import torch.nn as nn

# Define a simple neural network
class Net(nn.Module):
    def __init__(self):
        super(Net, self).__init__()
        self.fc1 = nn.Linear(784, 64)
        self.fc2 = nn.Linear(64, 10)

    def forward(self, x):
        x = torch.relu(self.fc1(x))
        x = self.fc2(x)
        return x

model = Net()
\`\`\`

### scikit-learn
\`\`\`python
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

# Train a random forest
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)
clf = RandomForestClassifier(n_estimators=100)
clf.fit(X_train, y_train)
predictions = clf.predict(X_test)
print(f"Accuracy: {accuracy_score(y_test, predictions)}")
\`\`\`

## Datasets

### Built-in datasets
\`\`\`python
from sklearn.datasets import load_iris, load_digits, make_classification
from tensorflow.keras.datasets import mnist, cifar10

# Load datasets
iris = load_iris()
digits = load_digits()
(X_train, y_train), (X_test, y_test) = mnist.load_data()
\`\`\`

### External datasets
\`\`\`python
import pandas as pd

# Load CSV
df = pd.read_csv('data.csv')

# Load from URLs
url = "https://raw.githubusercontent.com/mwaskom/seaborn-data/master/iris.csv"
df = pd.read_csv(url)
\`\`\`

## Model Evaluation

### Classification Metrics
\`\`\`python
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score

print(classification_report(y_true, y_pred))
print(confusion_matrix(y_true, y_pred))
\`\`\`

### Regression Metrics
\`\`\`python
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score

print(f"MSE: {mean_squared_error(y_true, y_pred)}")
print(f"MAE: {mean_absolute_error(y_true, y_pred)}")
print(f"R²: {r2_score(y_true, y_pred)}")
\`\`\`

## Visualization

### Matplotlib
\`\`\`python
import matplotlib.pyplot as plt

plt.figure(figsize=(10, 6))
plt.scatter(x, y, c=colors)
plt.xlabel('X axis')
plt.ylabel('Y axis')
plt.title('Scatter Plot')
plt.show()
\`\`\`

### Seaborn
\`\`\`python
import seaborn as sns

sns.set_style("whitegrid")
plt.figure(figsize=(10, 6))
sns.scatterplot(data=df, x='feature1', y='feature2', hue='target')
plt.show()
\`\`\`

### Plotly (Interactive)
\`\`\`python
import plotly.express as px

fig = px.scatter(df, x='feature1', y='feature2', color='target')
fig.show()
\`\`\`

## Best Practices

### 1. Data Preparation
- Always split data into train/validation/test sets
- Handle missing values appropriately
- Scale/normalize features when necessary
- Encode categorical variables

### 2. Model Development
- Start with simple models (baseline)
- Use cross-validation for evaluation
- Monitor for overfitting/underfitting
- Experiment with different algorithms

### 3. Model Evaluation
- Use appropriate metrics for your problem
- Analyze confusion matrices for classification
- Plot learning curves and validation curves
- Perform error analysis

### 4. Production Deployment
- Save models using joblib or pickle
- Create reproducible environments
- Monitor model performance in production
- Implement proper logging and error handling

## GPU Support

If you have an NVIDIA GPU, the setup script should have installed GPU-enabled versions of TensorFlow and PyTorch. To verify:

\`\`\`python
import tensorflow as tf
print("GPU available:", len(tf.config.list_physical_devices('GPU')) > 0)

import torch
print("GPU available:", torch.cuda.is_available())
\`\`\`

## Common Issues

### Memory Errors
- Reduce batch sizes
- Use data generators for large datasets
- Consider using smaller models

### Slow Training
- Use GPU acceleration if available
- Optimize data loading pipelines
- Use mixed precision training

### Package Conflicts
- Use virtual environments
- Check package compatibility
- Update pip and packages regularly

## Resources

### Documentation
- [scikit-learn](https://scikit-learn.org/)
- [TensorFlow](https://www.tensorflow.org/)
- [PyTorch](https://pytorch.org/)
- [pandas](https://pandas.pydata.org/)
- [NumPy](https://numpy.org/)

### Learning Resources
- [Coursera ML Course](https://www.coursera.org/learn/machine-learning)
- [Fast.ai](https://www.fast.ai/)
- [Kaggle Learn](https://www.kaggle.com/learn)

### Communities
- [r/MachineLearning](https://reddit.com/r/MachineLearning)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/machine-learning)
- [Kaggle](https://www.kaggle.com/)
EOF

    log_success "Machine learning course structure created at $course_dir"
}

# Verify installations
verify_installation() {
    log_info "Verifying ML installations..."

    local errors=0

    # Check Python packages
    python_packages=("numpy" "pandas" "matplotlib" "scikit-learn" "jupyter" "tensorflow" "torch")
    for package in "${python_packages[@]}"; do
        if python -c "import $package" 2>/dev/null; then
            log_success "$package: available"
        else
            log_error "$package: NOT FOUND"
            ((errors++))
        fi
    done

    if [[ $errors -eq 0 ]]; then
        log_success "All ML tools verified successfully!"
    else
        log_warning "$errors ML tools failed verification."
    fi
}

# Main function
main() {
    echo -e "${BLUE}🚀 Setting up Machine Learning Course Environment${NC}"
    echo -e "${BLUE}=================================================${NC}"

    detect_platform
    check_python

    install_jupyter
    install_tensorflow
    install_pytorch
    install_scikit_learn
    install_cv_libraries
    install_nlp_libraries
    install_visualization
    install_ml_tools
    install_gpu_support
    create_course_structure
    verify_installation

    echo ""
    echo -e "${GREEN}🎉 Machine Learning course setup complete!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Review the course materials in ~/dev/current/ml-course/"
    echo "2. Set up the environment: cd ~/dev/current/ml-course && ./setup-environment.sh"
    echo "3. Start Jupyter Lab: source ml-env/bin/activate && jupyter lab"
    echo "4. Open the sample notebook: notebooks/ml-basics.ipynb"
    echo "5. If you have a GPU, verify GPU support in the notebook"
    echo ""
    echo -e "${BLUE}Happy learning! 🎯${NC}"
}

# Run main function
main "$@"
