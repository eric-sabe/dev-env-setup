#!/bin/bash
# Web Development Course Setup Script
# Installs web development tools and frameworks for web dev courses

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

# Check Node.js
check_nodejs() {
    if ! command -v node &>/dev/null; then
        log_error "Node.js is required. Please run the platform setup script first."
        exit 1
    fi

    if ! command -v npm &>/dev/null; then
        log_error "npm is required. Please run the platform setup script first."
        exit 1
    fi

    log_success "Node.js $(node --version) and npm $(npm --version) found"
}

# Install Python for Django
install_python_web() {
    log_info "Setting up Python for web development..."

    # Check if pyenv is available
    if command -v pyenv &>/dev/null; then
        pyenv install 3.11.7 || log_warning "Python 3.11.7 already installed"
        pyenv global 3.11.7
    fi

    # Install pip packages for web development
    pip install --user django flask fastapi uvicorn requests beautifulsoup4 selenium pytest

    log_success "Python web development packages installed"
}

# Install global Node.js packages
install_nodejs_packages() {
    log_info "Installing global Node.js packages..."

    # Web development tools
    npm install -g npm@latest
    npm install -g yarn pnpm
    npm install -g typescript @types/node
    npm install -g nodemon
    npm install -g concurrently
    npm install -g http-server
    npm install -g live-server

    # Testing frameworks
    npm install -g jest
    npm install -g cypress
    npm install -g playwright

    # Build tools
    npm install -g webpack webpack-cli
    npm install -g parcel
    npm install -g vite

    # Linting and formatting
    npm install -g eslint prettier
    npm install -g stylelint

    log_success "Global Node.js packages installed"
}

# Install React development tools
install_react_tools() {
    log_info "Installing React development tools..."

    npm install -g create-react-app
    npm install -g @storybook/cli
    npm install -g react-devtools

    log_success "React tools installed"
}

# Install Vue.js development tools
install_vue_tools() {
    log_info "Installing Vue.js development tools..."

    npm install -g @vue/cli
    npm install -g @vue/devtools

    log_success "Vue.js tools installed"
}

# Install Angular development tools
install_angular_tools() {
    log_info "Installing Angular development tools..."

    npm install -g @angular/cli

    log_success "Angular tools installed"
}

# Install additional web servers and tools
install_web_servers() {
    log_info "Installing web servers and tools..."

    case $PLATFORM in
        macos)
            brew install nginx
            ;;
        ubuntu)
            sudo apt install -y nginx apache2
            ;;
        redhat)
            sudo yum install -y nginx httpd
            ;;
        arch)
            sudo pacman -S --noconfirm nginx apache
            ;;
        windows)
            log_info "Web servers need manual installation on Windows"
            ;;
    esac

    # Install certbot for SSL
    if [[ "$PLATFORM" != "windows" ]]; then
        case $PLATFORM in
            ubuntu)
                sudo apt install -y certbot python3-certbot-nginx
                ;;
            redhat)
                sudo yum install -y certbot python3-certbot-nginx
                ;;
        esac
    fi

    log_success "Web servers installed"
}

# Install databases for web development
install_web_databases() {
    log_info "Installing databases for web development..."

    # SQLite is usually included
    # PostgreSQL for production apps
    case $PLATFORM in
        macos)
            brew install sqlite postgresql
            ;;
        ubuntu)
            sudo apt install -y sqlite3 postgresql postgresql-contrib
            ;;
        redhat)
            sudo yum install -y sqlite postgresql postgresql-contrib
            ;;
        arch)
            sudo pacman -S --noconfirm sqlite postgresql
            ;;
        windows)
            log_info "Install PostgreSQL manually if needed"
            ;;
    esac

    # Install database drivers
    pip install --user psycopg2-binary sqlite3

    log_success "Web databases installed"
}

# Install browser automation tools
install_browser_tools() {
    log_info "Installing browser automation tools..."

    # Chrome/Chromium for testing
    case $PLATFORM in
        macos)
            brew install --cask google-chrome
            ;;
        ubuntu)
            curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chromium.gpg
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chromium.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
            sudo apt update
            sudo apt install -y google-chrome-stable
            ;;
        redhat)
            sudo yum install -y google-chrome-stable
            ;;
        arch)
            sudo pacman -S --noconfirm google-chrome
            ;;
        windows)
            log_info "Install Google Chrome manually"
            ;;
    esac

    log_success "Browser tools installed"
}

# Create web development course structure
create_course_structure() {
    log_info "Creating web development course directory structure..."

    local course_dir="$HOME/dev/current/webdev-course"
    mkdir -p "$course_dir"/{frontend,backend,fullstack,projects,notes,assets}

    # Create sample React app
    cat << 'EOF' > "$course_dir/frontend/create-react-app.sh"
#!/bin/bash
# Create a new React application

echo "Creating React app..."
npx create-react-app my-react-app
cd my-react-app
npm start
EOF
    chmod +x "$course_dir/frontend/create-react-app.sh"

    # Create sample Vue app
    cat << 'EOF' > "$course_dir/frontend/create-vue-app.sh"
#!/bin/bash
# Create a new Vue.js application

echo "Creating Vue app..."
npm install -g @vue/cli
vue create my-vue-app
cd my-vue-app
npm run serve
EOF
    chmod +x "$course_dir/frontend/create-vue-app.sh"

    # Create sample Angular app
    cat << 'EOF' > "$course_dir/frontend/create-angular-app.sh"
#!/bin/bash
# Create a new Angular application

echo "Creating Angular app..."
npm install -g @angular/cli
ng new my-angular-app
cd my-angular-app
ng serve
EOF
    chmod +x "$course_dir/frontend/create-angular-app.sh"

    # Create sample Express.js app
    cat << 'EOF' > "$course_dir/backend/package.json"
{
  "name": "express-app",
  "version": "1.0.0",
  "description": "Sample Express.js application",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "morgan": "^1.10.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF

    cat << 'EOF' > "$course_dir/backend/server.js"
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// Routes
app.get('/', (req, res) => {
  res.json({ message: 'Hello, World!' });
});

app.get('/api/users', (req, res) => {
  res.json([
    { id: 1, name: 'John Doe', email: 'john@example.com' },
    { id: 2, name: 'Jane Smith', email: 'jane@example.com' }
  ]);
});

app.post('/api/users', (req, res) => {
  const user = req.body;
  // In a real app, you'd save to a database
  res.status(201).json({ id: Date.now(), ...user });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
EOF

    # Create sample Django app
    cat << 'EOF' > "$course_dir/backend/create-django-app.sh"
#!/bin/bash
# Create a new Django application

echo "Creating Django app..."
python -m venv django-env
source django-env/bin/activate
pip install django djangorestframework
django-admin startproject myproject
cd myproject
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
EOF
    chmod +x "$course_dir/backend/create-django-app.sh"

    # Create README
    cat << EOF > "$course_dir/README.md"
# Web Development Course

## Course Directory Structure
- \`frontend/\`: Frontend frameworks and examples
- \`backend/\`: Backend frameworks and APIs
- \`fullstack/\`: Full-stack application examples
- \`projects/\`: Course projects and assignments
- \`notes/\`: Lecture notes and documentation
- \`assets/\`: Images, stylesheets, and other assets

## Frontend Frameworks

### React
\`\`\`bash
cd frontend
./create-react-app.sh
\`\`\`

### Vue.js
\`\`\`bash
cd frontend
./create-vue-app.sh
\`\`\`

### Angular
\`\`\`bash
cd frontend
./create-angular-app.sh
\`\`\`

## Backend Frameworks

### Express.js
\`\`\`bash
cd backend
npm install
npm start
# Or for development:
npm run dev
\`\`\`

### Django
\`\`\`bash
cd backend
./create-django-app.sh
\`\`\`

## Useful Commands

### npm/yarn
\`\`\`bash
# Install dependencies
npm install
yarn install

# Start development server
npm start
yarn start

# Build for production
npm run build
yarn build

# Run tests
npm test
yarn test
\`\`\`

### Django
\`\`\`bash
# Create new project
django-admin startproject myproject

# Create new app
python manage.py startapp myapp

# Run migrations
python manage.py makemigrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Run development server
python manage.py runserver
\`\`\`

## Development Tools

### VS Code Extensions (install via setup-vscode.sh)
- ES7+ React/Redux/React-Native snippets
- Prettier - Code formatter
- ESLint
- Auto Rename Tag
- Bracket Pair Colorizer
- Live Server

### Browser DevTools
- Chrome DevTools (F12)
- React DevTools
- Vue DevTools

## Testing

### Frontend Testing
\`\`\`bash
# Jest (React)
npm test

# Cypress (E2E)
npx cypress open
\`\`\`

### Backend Testing
\`\`\`bash
# Django
python manage.py test

# Express with Jest
npm test
\`\`\`

## Deployment

### Frontend
\`\`\`bash
# Build for production
npm run build

# Serve static files
npx serve -s build
\`\`\`

### Backend
\`\`\`bash
# Express
npm start

# Django
python manage.py collectstatic
python manage.py runserver 0.0.0.0:8000
\`\`\`

## APIs to Learn

### REST APIs
- GET /api/users - Get all users
- POST /api/users - Create user
- GET /api/users/:id - Get user by ID
- PUT /api/users/:id - Update user
- DELETE /api/users/:id - Delete user

### GraphQL
\`\`\`graphql
query GetUsers {
  users {
    id
    name
    email
  }
}
\`\`\`

## Best Practices

### Frontend
- Use functional components (React)
- Follow component composition patterns
- Implement proper state management
- Use CSS-in-JS or utility-first CSS
- Optimize bundle size

### Backend
- Follow RESTful API design
- Implement proper error handling
- Use environment variables for config
- Implement authentication/authorization
- Write comprehensive tests

### Full Stack
- Use consistent naming conventions
- Implement proper logging
- Handle CORS properly
- Implement input validation
- Use HTTPS in production
EOF

    log_success "Web development course structure created at $course_dir"
}

# Verify installations
verify_installation() {
    log_info "Verifying web development installations..."

    local errors=0

    # Check Node.js tools
    for tool in node npm yarn tsc; do
        if command -v $tool &>/dev/null; then
            log_success "$tool: available"
        else
            log_error "$tool: NOT FOUND"
            ((errors++))
        fi
    done

    # Check Python web packages
    if python -c "import django" 2>/dev/null; then
        log_success "Django: available"
    else
        log_warning "Django: NOT FOUND (install with: pip install django)"
    fi

    # Check global npm packages
    if npm list -g create-react-app 2>/dev/null; then
        log_success "Create React App: available"
    else
        log_warning "Create React App: NOT FOUND"
    fi

    if [[ $errors -eq 0 ]]; then
        log_success "All web development tools verified successfully!"
    else
        log_warning "$errors web development tools failed verification."
    fi
}

# Main function
main() {
    echo -e "${BLUE}🚀 Setting up Web Development Course Environment${NC}"
    echo -e "${BLUE}=================================================${NC}"

    detect_platform
    check_nodejs

    install_python_web
    install_nodejs_packages
    install_react_tools
    install_vue_tools
    install_angular_tools
    install_web_servers
    install_web_databases
    install_browser_tools
    create_course_structure
    verify_installation

    echo ""
    echo -e "${GREEN}🎉 Web Development course setup complete!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Review the course materials in ~/dev/current/webdev-course/"
    echo "2. Try creating sample applications:"
    echo "   cd ~/dev/current/webdev-course/frontend && ./create-react-app.sh"
    echo "   cd ~/dev/current/webdev-course/backend && npm install && npm start"
    echo "3. Install VS Code extensions for web development"
    echo "4. Set up your preferred browser for development"
    echo ""
    echo -e "${BLUE}Happy coding! 🎯${NC}"
}

# Run main function
main "$@"
