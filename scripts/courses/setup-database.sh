#!/bin/bash
# Database Systems Course Setup Script
# Installs database tools and development environment for database courses

# Strict mode is opt-in for interactive use. Enable with STRICT_MODE=1 or in CI.
if [[ ${STRICT_MODE:-0} == 1 || -n ${CI:-} ]]; then
    set -Eeuo pipefail
else
    # Safer defaults without aborting on every minor issue.
    set -o pipefail
fi
trap 'echo "[ERROR] setup-database failed at ${BASH_SOURCE[0]}:${LINENO}" >&2' ERR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL_DIR="${SCRIPT_DIR%/courses*/}/utils"
[[ -f "$UTIL_DIR/cross-platform.sh" ]] && source "$UTIL_DIR/cross-platform.sh"
[[ -f "$UTIL_DIR/verify.sh" ]] && source "$UTIL_DIR/verify.sh"
[[ -f "$UTIL_DIR/version-resolver.sh" ]] && source "$UTIL_DIR/version-resolver.sh"
[[ -f "$UTIL_DIR/idempotency.sh" ]] && source "$UTIL_DIR/idempotency.sh"

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

    # Consolidated manifest-aware bulk install for core DB services (PostgreSQL, MySQL, Redis)
    install_core_databases_manifest() {
            if ! command -v list_linux_apt_group >/dev/null 2>&1 && ! command -v list_macos_brew_group >/dev/null 2>&1; then
                    return 0
            fi
            log_info "Attempting manifest-driven core database installation..."
            case $PLATFORM in
                macos)
                    if command -v list_macos_brew_group >/dev/null 2>&1; then
                        local group
                            group=$(list_macos_brew_group db 2>/dev/null || true)
                            if [[ -n $group ]]; then
                                # shellcheck disable=SC2086
                                brew install $group || true
                                for svc in postgresql mysql redis; do brew services start "$svc" 2>/dev/null || true; done
                                log_success "Manifest core DB install (macOS) complete"
                                return 0
                            fi
                    fi
                    ;;
                ubuntu)
                    if command -v list_linux_apt_group >/dev/null 2>&1; then
                        local group
                        group=$(list_linux_apt_group db 2>/dev/null || true)
                        if [[ -n $group ]]; then
                            sudo apt update || true
                            # shellcheck disable=SC2086
                            sudo apt install -y $group || true
                            systemctl list-units --type=service 1>/dev/null 2>&1 || true
                            for svc in postgresql mysql redis-server; do sudo systemctl enable "$svc" 2>/dev/null || true; sudo systemctl start "$svc" 2>/dev/null || true; done
                            log_success "Manifest core DB install (Linux) complete"
                            return 0
                        fi
                    fi
                    ;;
            esac
            log_warning "Manifest-driven core DB install not applied (group missing); falling back to granular installers"
    }

# Install PostgreSQL
install_postgresql() {
    log_info "Checking PostgreSQL installation..."

    # Check if PostgreSQL is already installed and running
    if is_command_available psql && is_service_running postgresql; then
        log_success "PostgreSQL already installed and running"
        return 0
    fi

    log_info "Installing PostgreSQL..."

    case $PLATFORM in
        macos)
            ensure_brew_package postgresql "PostgreSQL"
            brew services start postgresql
            ;;
        ubuntu)
            ensure_apt_package postgresql "PostgreSQL"
            ensure_apt_package postgresql-contrib "PostgreSQL contrib"
            ensure_service_running postgresql "PostgreSQL"
            ;;
        redhat)
            if [[ -f /etc/fedora-release ]]; then
                ensure_yum_package postgresql-server "PostgreSQL server"
                ensure_yum_package postgresql-contrib "PostgreSQL contrib"
                sudo postgresql-setup --initdb
            else
                ensure_yum_package postgresql-server "PostgreSQL server"
                ensure_yum_package postgresql-contrib "PostgreSQL contrib"
                sudo postgresql-setup initdb
            fi
            ensure_service_running postgresql "PostgreSQL"
            ;;
        arch)
            ensure_pacman_package postgresql "PostgreSQL"
            sudo -u postgres initdb -D /var/lib/postgres/data
            ensure_service_running postgresql "PostgreSQL"
            ;;
        windows)
            log_info "Please install PostgreSQL manually from https://www.postgresql.org/download/windows/"
            ;;
    esac

    # Verify installation
    if is_command_available psql; then
        log_success "PostgreSQL installed successfully"
    else
        log_error "PostgreSQL installation failed"
        return 1
    fi
}
        # Create default database
        createdb "$USER" 2>/dev/null || log_warning "Database may already exist"
    fi

    log_success "PostgreSQL installed and configured"
}

# Install MySQL/MariaDB
install_mysql() {
    log_info "Checking MySQL/MariaDB installation..."

    # Check if MySQL/MariaDB is already installed and running
    if (is_command_available mysql || is_command_available mariadb) && (is_service_running mysql || is_service_running mariadb); then
        log_success "MySQL/MariaDB already installed and running"
        return 0
    fi

    log_info "Installing MySQL/MariaDB..."

    case $PLATFORM in
        macos)
            ensure_brew_package mysql "MySQL"
            brew services start mysql
            ;;
        ubuntu)
            ensure_apt_package mysql-server "MySQL Server"
            ensure_service_running mysql "MySQL"
            ;;
        redhat)
            ensure_yum_package mariadb-server "MariaDB Server"
            ensure_service_running mariadb "MariaDB"
            ;;
        arch)
            ensure_pacman_package mariadb "MariaDB"
            sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
            ensure_service_running mariadb "MariaDB"
            ;;
        windows)
            log_info "Please install MySQL manually from https://dev.mysql.com/downloads/mysql/"
            ;;
    esac

    # Verify installation
    if is_command_available mysql || is_command_available mariadb; then
        log_success "MySQL/MariaDB installed successfully"
    else
        log_error "MySQL/MariaDB installation failed"
        return 1
    fi
}

# Optional MySQL secure installation (interactive guidance or automated)
mysql_secure_hardening() {
        if ! command -v mysql &>/dev/null; then
                log_warning "MySQL client not found; skipping hardening"
                return
        fi

        echo ""
        log_info "MySQL hardening options:"
        echo "1) Interactive (run mysql_secure_installation)"
        echo "2) Automated (set root password, remove test DB, disable remote root)"
        echo "3) Skip"
        read -r -p "Choose hardening option [3]: " hard_opt
        hard_opt=${hard_opt:-3}

        case $hard_opt in
            1)
                if command -v mysql_secure_installation &>/dev/null; then
                    log_info "Launching mysql_secure_installation..."
                    mysql_secure_installation || log_warning "mysql_secure_installation exited with non-zero status"
                else
                    log_warning "mysql_secure_installation utility not available on this platform"
                fi
                ;;
            2)
                read -r -s -p "Enter desired MySQL root password: " MYSQL_ROOT_PW; echo
                [[ -z $MYSQL_ROOT_PW ]] && { log_error "Empty password provided; aborting automated hardening"; return; }
                # Attempt passwordless root auth first; fallback to sudo
                if mysql -u root -e 'SELECT 1;' 2>/dev/null; then
                    AUTH_CMD="mysql -u root"
                elif sudo mysql -u root -e 'SELECT 1;' 2>/dev/null; then
                    AUTH_CMD="sudo mysql -u root"
                else
                    log_error "Unable to authenticate as root for automated hardening"; return 1
                fi
                log_info "Applying automated secure configuration..."
                $AUTH_CMD <<EOF || log_warning "Some hardening statements may have failed"
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PW}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
                log_success "Automated MySQL hardening applied"
                ;;
            3)
                log_info "Skipping MySQL hardening (can run later with mysql_secure_installation)"
                ;;
            *)
                log_warning "Unknown option; skipping MySQL hardening"
                ;;
        esac
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
            # Install MongoDB 7.0 (dynamic codename + idempotent repo add)
            if ! command -v lsb_release &>/dev/null && [[ -f /etc/lsb-release ]]; then
                # shellcheck disable=SC1091
                . /etc/lsb-release || true
            fi
            CODENAME=""
            if command -v lsb_release &>/dev/null; then
                CODENAME="$(lsb_release -cs 2>/dev/null || true)"
            fi
            if [[ -z "$CODENAME" && -f /etc/os-release ]]; then
                # shellcheck disable=SC1091
                . /etc/os-release || true
                CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-jammy}}"
            fi
            # Map some derivative codenames to supported Ubuntu base if needed
            case "$CODENAME" in
                focal|jammy|noble) : ;; # supported directly
                vera|victoria) CODENAME="jammy" ;; # Linux Mint mapping examples
                *)
                    log_warning "Unsupported/unknown Ubuntu codename '$CODENAME' for MongoDB repo; defaulting to 'jammy' (may fail)."
                    CODENAME="jammy"
                    ;;
            esac
            if [[ -f /etc/apt/sources.list.d/mongodb-org-7.0.list ]] && grep -q "mongodb-org/7.0" /etc/apt/sources.list.d/mongodb-org-7.0.list 2>/dev/null; then
                log_info "MongoDB apt repository already present (codename $(grep -oE 'ubuntu [a-z]+' /etc/apt/sources.list.d/mongodb-org-7.0.list | awk '{print $2}' || echo '?')). Skipping repo add."
            else
                curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
                echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu ${CODENAME}/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
            fi
            sudo apt update
            if dpkg -s mongodb-org &>/dev/null; then
                log_info "mongodb-org already installed; skipping install"
            else
                sudo apt install -y mongodb-org || {
                    log_warning "mongodb-org package failed to install; attempting fallback to 'mongodb' if available"; \
                    sudo apt install -y mongodb || true; }
            fi
            sudo systemctl enable mongod || true
            sudo systemctl start mongod || true
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

# Run post-install verification
run_verification() {
    echo ""
    log_info "Running post-install verification checks..."
    verify_command psql "PostgreSQL client"
    verify_command mysql "MySQL client"
    verify_command mongod "MongoDB server binary"
    verify_command redis-server "Redis server binary"
    verify_service_active postgresql || true
    verify_service_active mysql || verify_service_active mariadb || true
    verify_service_active mongod || true
    verify_service_active redis-server || verify_service_active redis || true
    verify_port_listening 5432 || true
    verify_port_listening 3306 || true
    verify_port_listening 6379 || true
    verify_port_listening 27017 || true
    print_verification_summary || log_warning "Some database components failed verification"
}

# Install database client tools
install_client_tools() {
    log_info "Installing database client tools..."

    # Install Python packages for database access
    if command -v build_pip_install_args >/dev/null 2>&1; then
        db_pkgs=$(build_pip_install_args db || true)
        if [[ -n $db_pkgs ]]; then
          (python3 -m pip install --user $db_pkgs || python -m pip install --user $db_pkgs) || true
        fi
    else
        (python3 -m pip install --user psycopg2-binary pymysql pymongo redis || python -m pip install --user psycopg2-binary pymysql pymongo redis) || true
    fi

    # Install command-line clients
    case $PLATFORM in
        macos)
            brew install pgcli mycli
            ;;
        ubuntu)
            sudo apt install -y postgresql-client mysql-client redis-tools
            if command -v build_pip_install_args >/dev/null 2>&1; then
                : # pgcli/mycli could be added to a future 'db-tools' group
            else
                (python3 -m pip install --user pgcli mycli || python -m pip install --user pgcli mycli) || true
            fi
            ;;
        redhat)
            sudo yum install -y postgresql mysql redis
            (python3 -m pip install --user pgcli mycli || python -m pip install --user pgcli mycli) || true
            ;;
        arch)
            sudo pacman -S --noconfirm postgresql mysql redis
            (python3 -m pip install --user pgcli mycli || python -m pip install --user pgcli mycli) || true
            ;;
        windows)
            (python3 -m pip install --user pgcli mycli || python -m pip install --user pgcli mycli) || true
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
            # DBeaver (use keyring + signed-by)
            curl -fsSL https://dbeaver.io/debs/dbeaver.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/dbeaver.gpg
            echo "deb [signed-by=/usr/share/keyrings/dbeaver.gpg] https://dbeaver.io/debs/dbeaver-ce /" | sudo tee /etc/apt/sources.list.d/dbeaver.list
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

    install_core_databases_manifest || true
    install_postgresql
    install_mysql
    mysql_secure_hardening
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
