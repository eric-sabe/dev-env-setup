#!/bin/bash
# Node.js Project Quickstart Script
# Creates a comprehensive Node.js project with best practices

set -Eeuo pipefail
trap 'echo "[ERROR] quickstart-node failed at ${BASH_SOURCE[0]}:${LINENO}" >&2' ERR

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
    echo -e "${PURPLE}📦 $1${NC}"
    echo -e "${PURPLE}$(printf '%.0s=' {1..50})${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v node &>/dev/null; then
        log_error "Node.js is not installed. Please install it first."
        exit 1
    fi

    if ! command -v npm &>/dev/null; then
        log_error "npm is not installed. Please install it first."
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
    echo "1. Web API (Express.js)"
    echo "2. CLI Tool"
    echo "3. NPM Package/Library"
    echo "4. Full-Stack Web App"
    echo "5. Minimal (Basic setup)"
    read -p "Choose project type [1]: " PROJECT_TYPE
    PROJECT_TYPE=${PROJECT_TYPE:-1}

    # Project description
    read -p "Enter project description: " PROJECT_DESC
    PROJECT_DESC=${PROJECT_DESC:-"A Node.js project"}

    # Author
    read -p "Enter author name: " AUTHOR
    AUTHOR=${AUTHOR:-"$(whoami)"}

    # Git repository
    read -p "Enter git repository URL (optional): " GIT_REPO

    # Package manager
    echo ""
    echo "Select package manager:"
    echo "1. npm"
    echo "2. yarn"
    read -p "Choose package manager [1]: " PKG_MANAGER
    PKG_MANAGER=${PKG_MANAGER:-1}

    case $PKG_MANAGER in
        1) PKG_CMD="npm" ;;
        2) PKG_CMD="yarn" ;;
        *) PKG_CMD="npm" ;;
    esac

    # TypeScript
    read -p "Use TypeScript? (y/N): " USE_TS
    if [[ $USE_TS =~ ^[Yy]$ ]]; then
        USE_TYPESCRIPT=true
    else
        USE_TYPESCRIPT=false
    fi

    # Testing framework
    echo ""
    echo "Select testing framework:"
    echo "1. Jest"
    echo "2. Mocha + Chai"
    echo "3. None"
    read -p "Choose testing framework [1]: " TEST_FRAMEWORK
    TEST_FRAMEWORK=${TEST_FRAMEWORK:-1}

    # Linting
    read -p "Include ESLint? (Y/n): " USE_ESLINT
    if [[ $USE_ESLINT =~ ^[Nn]$ ]]; then
        USE_ESLINT=false
    else
        USE_ESLINT=true
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

# Initialize package.json
initialize_package_json() {
    log_info "Initializing package.json..."

    # Determine scripts JSON block
    if [[ "$USE_TYPESCRIPT" == "true" ]]; then
      START_SCRIPT='npm run build && node dist/index.js'
      DEV_SCRIPT='ts-node src/index.ts'
      BUILD_SCRIPT='"build": "tsc",'
      MAIN_FIELD='dist/index.js'
    else
      START_SCRIPT='node index.js'
      DEV_SCRIPT='node index.js'
      BUILD_SCRIPT=''
      MAIN_FIELD='index.js'
    fi

    # Optional fields
    local author_field="" repo_field=""
    [[ -n "$AUTHOR" ]] && author_field="  \"author\": \"$AUTHOR\","
    if [[ -n "$GIT_REPO" ]]; then
      repo_field=$(cat <<EOF
  "repository": {
    "type": "git",
    "url": "$GIT_REPO"
  },
EOF
)
    fi

    cat > package.json <<EOF
{
  "name": "$PROJECT_NAME",
  "version": "1.0.0",
  "description": "$PROJECT_DESC",
  "main": "$MAIN_FIELD",
  "scripts": {
    $BUILD_SCRIPT
    "start": "$START_SCRIPT",
    "dev": "$DEV_SCRIPT",
    "test": "jest",
    "lint": "eslint src/**/*.js",
    "lint:fix": "eslint src/**/*.js --fix"
  },
${author_field}
${repo_field}  "license": "MIT",
  "keywords": ["nodejs"],
  "engines": { "node": ">=14.0.0" }
}
EOF

    # Compact JSON if jq present
    if command -v jq &>/dev/null; then
      tmpfile=$(mktemp)
      if jq . package.json > "$tmpfile" 2>/dev/null; then
        mv "$tmpfile" package.json
      else
        rm -f "$tmpfile"
        log_warning "jq failed to validate JSON; keeping original"
      fi
    fi

    log_success "package.json created"
}

# Install dependencies
install_dependencies() {
    log_info "Installing dependencies..."

    local deps=()
    local dev_deps=()

    # Core dependencies based on project type
    case $PROJECT_TYPE in
        1) # Web API
            deps=("express" "cors" "helmet" "dotenv")
            ;;
        2) # CLI Tool
            deps=("commander" "chalk" "inquirer")
            ;;
        3) # NPM Package
            deps=()
            ;;
        4) # Full-Stack
            deps=("express" "cors" "helmet" "dotenv")
            ;;
        5) # Minimal
            deps=()
            ;;
    esac

    # TypeScript dependencies
    if [[ "$USE_TYPESCRIPT" == "true" ]]; then
        dev_deps=("typescript" "@types/node" "ts-node")
        if [[ $PROJECT_TYPE -eq 1 ]] || [[ $PROJECT_TYPE -eq 4 ]]; then
            dev_deps+=("@types/express" "@types/cors")
        fi
    fi

    # Testing dependencies
    case $TEST_FRAMEWORK in
        1) # Jest
            dev_deps+=("jest")
            if [[ "$USE_TYPESCRIPT" == "true" ]]; then
                dev_deps+=("@types/jest" "ts-jest")
            fi
            ;;
        2) # Mocha + Chai
            dev_deps+=("mocha" "chai")
            ;;
    esac

    # ESLint
    if [[ "$USE_ESLINT" == "true" ]]; then
        dev_deps+=("eslint")
        if [[ "$USE_TYPESCRIPT" == "true" ]]; then
            dev_deps+=("@typescript-eslint/parser" "@typescript-eslint/eslint-plugin")
        fi
    fi

    # Install dependencies
    if [[ ${#deps[@]} -gt 0 ]]; then
        log_info "Installing production dependencies: ${deps[*]}"
        if [[ "$PKG_CMD" == "yarn" ]]; then
            yarn add "${deps[@]}"
        else
            npm install "${deps[@]}"
        fi
    fi

    if [[ ${#dev_deps[@]} -gt 0 ]]; then
        log_info "Installing development dependencies: ${dev_deps[*]}"
        if [[ "$PKG_CMD" == "yarn" ]]; then
            yarn add -D "${dev_deps[@]}"
        else
            npm install -D "${dev_deps[@]}"
        fi
    fi

    log_success "Dependencies installed"
}

# Create project structure
create_project_structure() {
    log_info "Creating project structure..."

    # Create directories
    mkdir -p src tests docs scripts

    # Create source files
    case $PROJECT_TYPE in
        1) # Web API
            create_web_api_files
            ;;
        2) # CLI Tool
            create_cli_files
            ;;
        3) # NPM Package
            create_library_files
            ;;
        4) # Full-Stack
            create_fullstack_files
            ;;
        5) # Minimal
            create_minimal_files
            ;;
    esac

    # Create configuration files
    create_config_files

    log_success "Project structure created"
}

# Create Web API files
create_web_api_files() {
    local main_file="src/index.js"
    if [[ "$USE_TYPESCRIPT" == "true" ]]; then
        main_file="src/index.ts"
    fi

    cat << EOF > "$main_file"
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to $PROJECT_NAME API',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

app.listen(PORT, () => {
  console.log(\`🚀 $PROJECT_NAME API is running on port \${PORT}\`);
  console.log(\`📚 API Documentation: http://localhost:\${PORT}\`);
});

export default app;
EOF

    # Create environment file
    cat << EOF > .env.example
# Environment Variables
PORT=3000
NODE_ENV=development

# Database (if needed)
# DATABASE_URL=postgresql://user:password@localhost:5432/dbname

# JWT Secret (if needed)
# JWT_SECRET=your-secret-key-here

# API Keys (if needed)
# API_KEY=your-api-key-here
EOF

    cp .env.example .env
}

# Create CLI tool files
create_cli_files() {
    local main_file="src/index.js"
    if [[ "$USE_TYPESCRIPT" == "true" ]]; then
        main_file="src/index.ts"
    fi

    cat << EOF > "$main_file"
#!/usr/bin/env node

import { Command } from 'commander';
import chalk from 'chalk';
import inquirer from 'inquirer';

const program = new Command();

program
  .name('$PROJECT_NAME')
  .description('$PROJECT_DESC')
  .version('1.0.0');

program
  .command('greet')
  .description('Greet someone')
  .argument('<name>', 'name to greet')
  .option('-c, --color <color>', 'color for the greeting', 'green')
  .action((name, options) => {
    const color = options.color;
    console.log(chalk[color](\`Hello, \${name}!\`));
  });

program
  .command('interactive')
  .description('Interactive greeting')
  .action(async () => {
    const answers = await inquirer.prompt([
      {
        type: 'input',
        name: 'name',
        message: 'What is your name?',
        default: 'World'
      },
      {
        type: 'list',
        name: 'color',
        message: 'Choose a color:',
        choices: ['red', 'green', 'blue', 'yellow', 'magenta']
      }
    ]);

    console.log(chalk[answers.color](\`Hello, \${answers.name}!\`));
  });

program.parse();
EOF

    # Make CLI executable
    chmod +x "$main_file"
}

# Create library files
create_library_files() {
    local main_file="src/index.js"
    if [[ "$USE_TYPESCRIPT" == "true" ]]; then
        main_file="src/index.ts"
    fi

    cat << EOF > "$main_file"
/**
 * $PROJECT_NAME - $PROJECT_DESC
 * @module $PROJECT_NAME
 */

/**
 * A simple greeting function
 * @param {string} name - The name to greet
 * @returns {string} The greeting message
 */
export function greet(name = 'World') {
  return \`Hello, \${name}!\`;
}

/**
 * Calculate the sum of two numbers
 * @param {number} a - First number
 * @param {number} b - Second number
 * @returns {number} The sum
 */
export function sum(a, b) {
  if (typeof a !== 'number' || typeof b !== 'number') {
    throw new Error('Both arguments must be numbers');
  }
  return a + b;
}

/**
 * Check if a number is even
 * @param {number} num - The number to check
 * @returns {boolean} True if even, false otherwise
 */
export function isEven(num) {
  if (typeof num !== 'number') {
    throw new Error('Argument must be a number');
  }
  return num % 2 === 0;
}

export default {
  greet,
  sum,
  isEven
};
EOF
}

# Create full-stack files
create_fullstack_files() {
    # Similar to Web API but with more structure
    create_web_api_files

    # Add additional directories
    mkdir -p public views routes models middleware

    # Create additional route file
    cat << EOF > src/routes/api.js
import express from 'express';

const router = express.Router();

// API routes
router.get('/users', (req, res) => {
  // TODO: Implement user listing
  res.json({ users: [] });
});

router.post('/users', (req, res) => {
  // TODO: Implement user creation
  const { name, email } = req.body;
  res.json({ message: 'User created', user: { name, email } });
});

export default router;
EOF

    # Update main file to use routes
    local main_file="src/index.js"
    if [[ "$USE_TYPESCRIPT" == "true" ]]; then
        main_file="src/index.ts"
    fi

    # Add route import to main file
    sed -i '4a import apiRoutes from '\''./routes/api.js'\'';' "$main_file"
    sed -i '18a app.use('\''/api'\'', apiRoutes);' "$main_file"
}

# Create minimal files
create_minimal_files() {
    local main_file="src/index.js"
    if [[ "$USE_TYPESCRIPT" == "true" ]]; then
        main_file="src/index.ts"
    fi

    cat << EOF > "$main_file"
/**
 * $PROJECT_NAME - $PROJECT_DESC
 * Main entry point
 */

console.log('Hello from $PROJECT_NAME!');
console.log('Description: $PROJECT_DESC');
console.log('Author: $AUTHOR');
console.log('Version: 1.0.0');

// Your code here
EOF
}

# Create configuration files
create_config_files() {
    # TypeScript config
    if [[ "$USE_TYPESCRIPT" == "true" ]]; then
        cat << EOF > tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
EOF
    fi

    # ESLint config
    if [[ "$USE_ESLINT" == "true" ]]; then
        if [[ "$USE_TYPESCRIPT" == "true" ]]; then
            cat << EOF > .eslintrc.json
{
  "parser": "@typescript-eslint/parser",
  "extends": [
    "eslint:recommended",
    "@typescript-eslint/recommended"
  ],
  "parserOptions": {
    "ecmaVersion": 2020,
    "sourceType": "module"
  },
  "env": {
    "node": true,
    "es6": true
  },
  "rules": {
    "no-console": "off",
    "@typescript-eslint/no-unused-vars": ["error", { "argsIgnorePattern": "^_" }]
  }
}
EOF
        else
            cat << EOF > .eslintrc.json
{
  "env": {
    "node": true,
    "es6": true
  },
  "extends": "eslint:recommended",
  "parserOptions": {
    "ecmaVersion": 2020,
    "sourceType": "module"
  },
  "rules": {
    "no-console": "off",
    "no-unused-vars": ["error", { "argsIgnorePattern": "^_" }]
  }
}
EOF
        fi
    fi

    # Jest config
    if [[ $TEST_FRAMEWORK -eq 1 ]]; then
        if [[ "$USE_TYPESCRIPT" == "true" ]]; then
            cat << EOF > jest.config.js
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src', '<rootDir>/tests'],
  testMatch: ['**/__tests__/**/*.ts', '**/?(*.)+(spec|test).ts'],
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts'
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html']
};
EOF
        else
            cat << EOF > jest.config.js
module.exports = {
  testEnvironment: 'node',
  roots: ['<rootDir>/src', '<rootDir>/tests'],
  testMatch: ['**/__tests__/**/*.js', '**/?(*.)+(spec|test).js'],
  collectCoverageFrom: [
    'src/**/*.js'
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html']
};
EOF
        fi
    fi

    # .gitignore
    cat << EOF > .gitignore
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/
*.lcov

# nyc test coverage
.nyc_output

# Grunt intermediate storage (https://gruntjs.com/creating-plugins#storing-task-files)
.grunt

# Bower dependency directory (https://bower.io/)
bower_components

# node-waf configuration
.lock-wscript

# Compiled binary addons (https://nodejs.org/api/addons.html)
build/Release

# Dependency directories
jspm_packages/

# TypeScript cache
*.tsbuildinfo

# Optional npm cache directory
.npm

# Optional eslint cache
.eslintcache

# Microbundle cache
.rpt2_cache/
.rts2_cache_cjs/
.rts2_cache_es/
.rts2_cache_umd/

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# dotenv environment variables file
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# parcel-bundler cache (https://parceljs.org/)
.cache
.parcel-cache

# Next.js build output
.next

# Nuxt.js build / generate output
.nuxt
dist

# Gatsby files
.cache/
public

# Storybook build outputs
.out
.storybook-out

# Temporary folders
tmp/
temp/

# Logs
logs
*.log

# OS generated files
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
# $PROJECT_NAME

$PROJECT_DESC

## Installation

\`\`\`bash
$PKG_CMD install
\`\`\`

## Usage

\`\`\`bash
$PKG_CMD start
\`\`\`

## Development

\`\`\`bash
$PKG_CMD run dev
\`\`\`

## Testing

\`\`\`bash
$PKG_CMD test
\`\`\`

## Building

\`\`\`bash
$PKG_CMD run build
\`\`\`

## Linting

\`\`\`bash
$PKG_CMD run lint
\`\`\`

## Project Structure

\`\`\`
$PROJECT_NAME/
├── src/                 # Source code
├── tests/               # Test files
├── docs/                # Documentation
├── scripts/             # Build scripts
├── package.json         # Project configuration
├── tsconfig.json        # TypeScript configuration (if applicable)
├── jest.config.js       # Test configuration (if applicable)
└── README.md           # This file
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

$AUTHOR
EOF

    # Create basic test file
    if [[ $TEST_FRAMEWORK -eq 1 ]]; then
        local test_file="tests/index.test.js"
        if [[ "$USE_TYPESCRIPT" == "true" ]]; then
            test_file="tests/index.test.ts"
        fi

        cat << EOF > "$test_file"
/**
 * Basic test suite for $PROJECT_NAME
 */

describe('$PROJECT_NAME', () => {
  test('should work', () => {
    expect(true).toBe(true);
  });
});
EOF
    fi
}

# Initialize git repository
initialize_git() {
    if [[ -n "$GIT_REPO" ]]; then
        log_info "Initializing Git repository..."

        git init
        git add .
        git commit -m "Initial commit"

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

    echo "🚀 Quick Start:"
    echo "  cd $PROJECT_NAME"
    echo "  $PKG_CMD install"
    echo "  $PKG_CMD run dev"
    echo ""

    if [[ $TEST_FRAMEWORK -eq 1 ]]; then
        echo "🧪 Testing:"
        echo "  $PKG_CMD test"
        echo ""
    fi

    if [[ "$USE_ESLINT" == "true" ]]; then
        echo "🔍 Linting:"
        echo "  $PKG_CMD run lint"
        echo ""
    fi

    echo "📚 Next Steps:"
    echo "  1. Review and customize the generated files"
    echo "  2. Add your application logic to src/"
    echo "  3. Write tests in tests/"
    echo "  4. Update documentation in README.md"
    echo ""

    log_success "Happy coding! 🎉"
}

# Main function
main() {
    log_header "Node.js Project Quickstart"

    check_prerequisites
    get_project_info "$@"
    create_project_directory
    initialize_package_json
    install_dependencies
    create_project_structure
    initialize_git
    display_summary
}

# Run main function
main "$@"
