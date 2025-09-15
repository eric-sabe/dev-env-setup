#!/bin/bash
# Database Systems Course Setup Script
# Installs database tools and development environment for database courses

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

# Install PostgreSQL
install_postgresql() {
    log_info "Installing PostgreSQL..."

    case $PLATFORM in
        macos)
            brew install postgresql
            brew services start postgresql
            ;;
        ubuntu)
            sudo apt install -y postgresql postgresql-contrib
            sudo systemctl enable postgresql
            sudo systemctl start postgresql
            ;;
        redhat)
            if [[ -f /etc/fedora-release ]]; then
                sudo dnf install -y postgresql-server postgresql-contrib
                sudo postgresql-setup --initdb
            else
                sudo yum install -y postgresql-server postgresql-contrib
                sudo postgresql-setup initdb
            fi
            sudo systemctl enable postgresql
            sudo systemctl start postgresql
            ;;
        arch)
            sudo pacman -S --noconfirm postgresql
            sudo -u postgres initdb -D /var/lib/postgres/data
            sudo systemctl enable postgresql
            sudo systemctl start postgresql
            ;;
        windows)
            log_info "Please install PostgreSQL manually from https://www.postgresql.org/download/windows/"
            ;;
    esac

    # Configure PostgreSQL
    if [[ "$PLATFORM" != "windows" ]]; then
        # Create database user
        sudo -u postgres createuser --createdb --superuser "$USER" 2>/dev/null || log_warning "User may already exist"
        # Create default database
        createdb "$USER" 2>/dev/null || log_warning "Database may already exist"
    fi

    log_success "PostgreSQL installed and configured"
}

# Install MySQL/MariaDB
install_mysql() {
    log_info "Installing MySQL/MariaDB..."

    case $PLATFORM in
        macos)
            brew install mysql
            brew services start mysql
            ;;
        ubuntu)
            sudo apt install -y mysql-server
            sudo systemctl enable mysql
            sudo systemctl start mysql
            ;;
        redhat)
            sudo yum install -y mariadb-server
            sudo systemctl enable mariadb
            sudo systemctl start mariadb
            ;;
        arch)
            sudo pacman -S --noconfirm mariadb
            sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
            sudo systemctl enable mariadb
            sudo systemctl start mariadb
            ;;
        windows)
            log_info "Please install MySQL manually from https://dev.mysql.com/downloads/mysql/"
            ;;
    esac

    log_success "MySQL/MariaDB installed"
}

# Install MongoDB
install_mongodb() {
    log_info "Installing MongoDB..."

    case $PLATFORM in
        macos)
            brew tap mongodb/brew
            brew install mongodb-community
            brew services start mongodb-community
            ;;
        ubuntu)
            # Install MongoDB 7.0
            curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
            echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
            sudo apt update
            sudo apt install -y mongodb-org
            sudo systemctl enable mongod
            sudo systemctl start mongod
            ;;
        redhat)
            # MongoDB installation on RHEL/CentOS is complex, skip for now
            log_warning "MongoDB installation on RHEL/CentOS requires manual setup"
            log_info "Please visit: https://docs.mongodb.com/manual/tutorial/install-mongodb-on-red-hat/"
            ;;
        arch)
            sudo pacman -S --noconfirm mongodb
            sudo systemctl enable mongodb
            sudo systemctl start mongodb
            ;;
        windows)
            log_info "Please install MongoDB manually from https://www.mongodb.com/try/download/community"
            ;;
    esac

    log_success "MongoDB installed"
}

# Install Redis
install_redis() {
    log_info "Installing Redis..."

    case $PLATFORM in
        macos)
            brew install redis
            brew services start redis
            ;;
        ubuntu)
            sudo apt install -y redis-server
            sudo systemctl enable redis-server
            sudo systemctl start redis-server
            ;;
        redhat)
            sudo yum install -y redis
            sudo systemctl enable redis
            sudo systemctl start redis
            ;;
        arch)
            sudo pacman -S --noconfirm redis
            sudo systemctl enable redis
            sudo systemctl start redis
            ;;
        windows)
            log_info "Please install Redis manually from https://redis.io/download"
            ;;
    esac

    log_success "Redis installed"
}

# Install database client tools
install_client_tools() {
    log_info "Installing database client tools..."

    # Install Python packages for database access
    pip install --user psycopg2-binary pymysql pymongo redis

    # Install command-line clients
    case $PLATFORM in
        macos)
            brew install pgcli mycli
            ;;
        ubuntu)
            sudo apt install -y postgresql-client mysql-client redis-tools
            pip install --user pgcli mycli
            ;;
        redhat)
            sudo yum install -y postgresql mysql redis
            pip install --user pgcli mycli
            ;;
        arch)
            sudo pacman -S --noconfirm postgresql mysql redis
            pip install --user pgcli mycli
            ;;
        windows)
            pip install --user pgcli mycli
            ;;
    esac

    log_success "Database client tools installed"
}

# Install GUI tools
install_gui_tools() {
    log_info "Installing GUI database tools..."

    case $PLATFORM in
        macos)
            brew install --cask dbeaver-community
            brew install --cask mongodb-compass
            ;;
        ubuntu)
            # DBeaver
            wget -O - https://dbeaver.io/debs/dbeaver.gpg.key | sudo apt-key add -
            echo "deb https://dbeaver.io/debs/dbeaver-ce /" | sudo tee /etc/apt/sources.list.d/dbeaver.list
            sudo apt update
            sudo apt install -y dbeaver-ce

            # MongoDB Compass (if available)
            log_info "MongoDB Compass may need manual installation on Ubuntu"
            ;;
        redhat)
            log_info "GUI tools may need manual installation on RHEL/CentOS"
            ;;
        arch)
            sudo pacman -S --noconfirm dbeaver
            ;;
        windows)
            log_info "Please install DBeaver from https://dbeaver.io/download/"
            log_info "Please install MongoDB Compass from https://www.mongodb.com/products/compass"
            ;;
    esac

    log_success "GUI database tools installed"
}

# Install database development libraries
install_dev_libraries() {
    log_info "Installing database development libraries..."

    case $PLATFORM in
        macos)
            brew install libpq mysql-client
            ;;
        ubuntu)
            sudo apt install -y libpq-dev libmysqlclient-dev libsqlite3-dev unixodbc-dev
            ;;
        redhat)
            sudo yum install -y postgresql-devel mysql-devel sqlite-devel unixODBC-devel
            ;;
        arch)
            sudo pacman -S --noconfirm postgresql-libs mysql-libs sqlite unixodbc
            ;;
        windows)
            log_info "Development libraries are included with database installations"
            ;;
    esac

    log_success "Database development libraries installed"
}

# Create database course directory structure
create_course_structure() {
    log_info "Creating database course directory structure..."

    local course_dir="$HOME/dev/current/database-course"
    mkdir -p "$course_dir"/{sql-scripts,schemas,data,projects,notes}

    # Create sample SQL files
    cat << 'EOF' > "$course_dir/sql-scripts/sample-postgres.sql"
-- Sample PostgreSQL script for Database Systems course

-- Create a sample database
CREATE DATABASE university_db;

-- Connect to the database
\c university_db;

-- Create tables
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    enrollment_date DATE DEFAULT CURRENT_DATE
);

CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_name VARCHAR(100) NOT NULL,
    course_code VARCHAR(10) UNIQUE NOT NULL,
    credits INTEGER CHECK (credits > 0)
);

CREATE TABLE enrollments (
    enrollment_id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(student_id),
    course_id INTEGER REFERENCES courses(course_id),
    grade CHAR(1),
    enrollment_date DATE DEFAULT CURRENT_DATE
);

-- Insert sample data
INSERT INTO students (first_name, last_name, email) VALUES
('John', 'Doe', 'john.doe@university.edu'),
('Jane', 'Smith', 'jane.smith@university.edu');

INSERT INTO courses (course_name, course_code, credits) VALUES
('Database Systems', 'CS301', 3),
('Data Structures', 'CS201', 3);

-- Sample queries
-- List all students
SELECT * FROM students;

-- List all courses
SELECT * FROM courses;

-- Show enrollments with student and course names
SELECT s.first_name, s.last_name, c.course_name, e.grade
FROM enrollments e
JOIN students s ON e.student_id = s.student_id
JOIN courses c ON e.course_id = c.course_id;
EOF

    cat << 'EOF' > "$course_dir/sql-scripts/sample-mysql.sql"
-- Sample MySQL script for Database Systems course

-- Create a sample database
CREATE DATABASE IF NOT EXISTS company_db;
USE company_db;

-- Create tables
CREATE TABLE employees (
    employee_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    hire_date DATE DEFAULT (CURRENT_DATE),
    salary DECIMAL(10,2)
);

CREATE TABLE departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    location VARCHAR(100)
);

-- Add foreign key to employees table
ALTER TABLE employees
ADD COLUMN department_id INT,
ADD CONSTRAINT fk_department
FOREIGN KEY (department_id) REFERENCES departments(department_id);

-- Insert sample data
INSERT INTO departments (department_name, location) VALUES
('Engineering', 'Building A'),
('Sales', 'Building B');

INSERT INTO employees (first_name, last_name, email, salary, department_id) VALUES
('Alice', 'Johnson', 'alice@company.com', 75000.00, 1),
('Bob', 'Wilson', 'bob@company.com', 65000.00, 2);

-- Sample queries
-- List all employees with department names
SELECT e.first_name, e.last_name, d.department_name, e.salary
FROM employees e
JOIN departments d ON e.department_id = d.department_id;

-- Calculate average salary by department
SELECT d.department_name, AVG(e.salary) as avg_salary
FROM employees e
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.department_name;
EOF

    # Create README
    cat << EOF > "$course_dir/README.md"
# Database Systems Course

## Course Directory Structure
- \`sql-scripts/\`: SQL scripts and examples
- \`schemas/\`: Database schemas and ER diagrams
- \`data/\`: Sample data files
- \`projects/\`: Course projects and assignments
- \`notes/\`: Lecture notes and documentation

## Database Connections

### PostgreSQL
- Host: localhost
- Port: 5432
- Database: $USER
- User: $USER

### MySQL/MariaDB
- Host: localhost
- Port: 3306
- User: root

### MongoDB
- Host: localhost
- Port: 27017

### Redis
- Host: localhost
- Port: 6379

## Useful Commands

### PostgreSQL
\`\`\`bash
# Connect to database
psql

# Connect to specific database
psql university_db

# Run SQL script
psql -f sql-scripts/sample-postgres.sql
\`\`\`

### MySQL
\`\`\`bash
# Connect to database
mysql -u root

# Connect to specific database
mysql -u root company_db

# Run SQL script
mysql -u root < sql-scripts/sample-mysql.sql
\`\`\`

### MongoDB
\`\`\`bash
# Start MongoDB shell
mongosh

# Show databases
show dbs

# Use database
use mydb
\`\`\`

### Redis
\`\`\`bash
# Start Redis CLI
redis-cli

# Set a key
SET mykey "Hello World"

# Get a key
GET mykey
\`\`\`

## GUI Tools
- **DBeaver**: Universal database client
- **MongoDB Compass**: MongoDB GUI client
- **pgAdmin**: PostgreSQL web interface (may need separate installation)

## Python Database Access

### PostgreSQL
\`\`\`python
import psycopg2

conn = psycopg2.connect(
    dbname="$USER",
    user="$USER",
    host="localhost"
)
\`\`\`

### MySQL
\`\`\`python
import pymysql

conn = pymysql.connect(
    host="localhost",
    user="root",
    database="company_db"
)
\`\`\`

### MongoDB
\`\`\`python
from pymongo import MongoClient

client = MongoClient('localhost', 27017)
db = client.mydb
\`\`\`

### Redis
\`\`\`python
import redis

r = redis.Redis(host='localhost', port=6379)
r.set('mykey', 'Hello World')
\`\`\`
EOF

    log_success "Database course structure created at $course_dir"
}

# Verify installations
verify_installation() {
    log_info "Verifying database installations..."

    local errors=0

    # Check PostgreSQL
    if command -v psql &>/dev/null; then
        log_success "PostgreSQL client: available"
    else
        log_error "PostgreSQL client: NOT FOUND"
        ((errors++))
    fi

    # Check MySQL
    if command -v mysql &>/dev/null; then
        log_success "MySQL client: available"
    else
        log_error "MySQL client: NOT FOUND"
        ((errors++))
    fi

    # Check MongoDB (if installed)
    if command -v mongosh &>/dev/null || command -v mongo &>/dev/null; then
        log_success "MongoDB client: available"
    else
        log_warning "MongoDB client: NOT FOUND (may not be installed)"
    fi

    # Check Redis
    if command -v redis-cli &>/dev/null; then
        log_success "Redis client: available"
    else
        log_error "Redis client: NOT FOUND"
        ((errors++))
    fi

    if [[ $errors -eq 0 ]]; then
        log_success "All database tools verified successfully!"
    else
        log_warning "$errors database tools failed verification."
    fi
}

# Main function
main() {
    echo -e "${BLUE}🚀 Setting up Database Systems Course Environment${NC}"
    echo -e "${BLUE}=================================================${NC}"

    detect_platform

    install_postgresql
    install_mysql
    install_mongodb
    install_redis
    install_client_tools
    install_gui_tools
    install_dev_libraries
    create_course_structure
    verify_installation

    echo ""
    echo -e "${GREEN}🎉 Database Systems course setup complete!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Review the course materials in ~/dev/current/database-course/"
    echo "2. Start database services if not already running:"
    echo "   - PostgreSQL: sudo systemctl start postgresql"
    echo "   - MySQL: sudo systemctl start mysql"
    echo "   - MongoDB: sudo systemctl start mongod"
    echo "   - Redis: sudo systemctl start redis"
    echo "3. Open DBeaver to explore databases"
    echo "4. Run sample SQL scripts to get started"
    echo ""
    echo -e "${BLUE}Happy querying! 🎯${NC}"
}

# Run main function
main "$@"
