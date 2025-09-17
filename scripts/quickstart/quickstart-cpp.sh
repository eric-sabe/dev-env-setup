#!/bin/bash
# C++ Project Quickstart Script
# Creates new C++ projects with CMake

set -Eeuo pipefail
trap 'echo "[ERROR] quickstart-cpp failed at ${BASH_SOURCE[0]}:${LINENO}" >&2' ERR

# Source cross-platform utilities for timing functionality
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/cross-platform.sh"

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

# Show usage
usage() {
    echo "Usage: $0 <project-name> [cpp-standard]"
    echo ""
    echo "Arguments:"
    echo "  project-name    Name of the C++ project to create"
    echo "  cpp-standard    C++ standard to use: 17 (default), 20, 23"
    echo ""
    echo "Examples:"
    echo "  $0 my-app"
    echo "  $0 my-app 20"
    echo "  $0 my-app 23"
    exit 1
}

# Check prerequisites
check_prerequisites() {
    local cpp_standard=$1

    # Check CMake
    if ! command -v cmake &>/dev/null; then
        log_error "CMake is not installed. Please run the platform setup script first."
        exit 1
    fi

    # Check C++ compiler
    local compiler_found=false
    for compiler in g++ clang++; do
        if command -v $compiler &>/dev/null; then
            log_success "Found C++ compiler: $compiler"
            compiler_found=true
            break
        fi
    done

    if [[ "$compiler_found" != true ]]; then
        log_error "No C++ compiler found. Please run the platform setup script first."
        exit 1
    fi

    # Check C++ standard support
    case $cpp_standard in
        17|20|23)
            ;;
        *)
            log_error "Unsupported C++ standard: $cpp_standard. Supported: 17, 20, 23"
            exit 1
            ;;
    esac

    log_success "Prerequisites check passed"
}

# Create CMake project
create_cpp_project() {
    local project_name=$1
    local cpp_standard=${2:-17}

    start_timer "cpp_project_creation"
    log_timed_info "cpp_project_creation" "Creating C++ project: $project_name (C++$cpp_standard)"

    # Create project directory
    mkdir -p "$project_name"
    cd "$project_name"

    # Create CMakeLists.txt
    cat << EOF > CMakeLists.txt
cmake_minimum_required(VERSION 3.16)
project($project_name VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD $cpp_standard)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Compiler flags
if(MSVC)
    add_compile_options(/W4)
else()
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# Create executable
add_executable(\${PROJECT_NAME}
    src/main.cpp
    src/app.cpp
    include/app.hpp
)

# Include directories
target_include_directories(\${PROJECT_NAME} PRIVATE include)

# Dependencies
include(FetchContent)

# Google Test (optional, for testing)
option(BUILD_TESTS "Build tests" ON)
if(BUILD_TESTS)
    FetchContent_Declare(
        googletest
        URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.zip
    )
    FetchContent_MakeAvailable(googletest)

    enable_testing()

    add_executable(\${PROJECT_NAME}_test
        tests/test_app.cpp
        src/app.cpp
        include/app.hpp
    )

    target_include_directories(\${PROJECT_NAME}_test PRIVATE include)
    target_link_libraries(\${PROJECT_NAME}_test gtest_main)

    add_test(NAME \${PROJECT_NAME}_test COMMAND \${PROJECT_NAME}_test)
endif()

# Installation
install(TARGETS \${PROJECT_NAME}
    RUNTIME DESTINATION bin
)
EOF

    # Create source directories
    mkdir -p src include tests build

    # Create main.cpp
    cat << EOF > src/main.cpp
#include <iostream>
#include "app.hpp"

/**
 * @brief Main entry point for the application
 */
int main(int argc, char* argv[]) {
    std::cout << "Hello, World!" << std::endl;

    App app;
    app.run();

    return 0;
}
EOF

    # Create app.hpp
    cat << EOF > include/app.hpp
#pragma once

#include <string>

/**
 * @class App
 * @brief Main application class
 */
class App {
public:
    /**
     * @brief Construct a new App object
     */
    App();

    /**
     * @brief Destroy the App object
     */
    ~App();

    /**
     * @brief Run the application
     */
    void run();

    /**
     * @brief Get a greeting message
     * @return std::string The greeting message
     */
    std::string getGreeting() const;

private:
    std::string greeting_;
};
EOF

    # Create app.cpp
    cat << EOF > src/app.cpp
#include "app.hpp"
#include <iostream>

App::App() : greeting_("Hello, World!") {
    std::cout << "App initialized" << std::endl;
}

App::~App() {
    std::cout << "App destroyed" << std::endl;
}

void App::run() {
    std::cout << getGreeting() << std::endl;
}

std::string App::getGreeting() const {
    return greeting_;
}
EOF

    # Create test file
    cat << EOF > tests/test_app.cpp
#include <gtest/gtest.h>
#include "app.hpp"

/**
 * @brief Test fixture for App class
 */
class AppTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Setup code
    }

    void TearDown() override {
        // Cleanup code
    }

    App app;
};

/**
 * @brief Test the getGreeting method
 */
TEST_F(AppTest, GetGreeting) {
    EXPECT_EQ(app.getGreeting(), "Hello, World!");
}

/**
 * @brief Test the run method (basic functionality)
 */
TEST_F(AppTest, Run) {
    // This test just ensures run() doesn't throw
    EXPECT_NO_THROW(app.run());
}
EOF

    # Create README
    cat << EOF > README.md
# $project_name

A C++ application built with CMake.

## Prerequisites

- C++$cpp_standard compatible compiler (GCC 7+, Clang 5+, MSVC 2017+)
- CMake 3.16+

## Building

\`\`\`bash
# Create build directory
mkdir build
cd build

# Configure
cmake ..

# Build
cmake --build . --config Release
\`\`\`

## Running

\`\`\`bash
# From build directory
./$project_name
\`\`\`

## Testing

\`\`\`bash
# Build tests
cmake --build . --config Release --target $project_name_test

# Run tests
ctest --output-on-failure
\`\`\`

## IDE Support

### Visual Studio Code
Install the "C/C++" and "CMake Tools" extensions.

### CLion
Import the project directory directly.

### Visual Studio
Use "Open Folder" and select the project directory.

## Project Structure

\`\`\`
$project_name/
├── CMakeLists.txt          # CMake configuration
├── README.md              # This file
├── include/               # Header files
│   └── app.hpp
├── src/                   # Source files
│   ├── main.cpp
│   └── app.cpp
├── tests/                 # Test files
│   └── test_app.cpp
└── build/                 # Build artifacts (created during build)
\`\`\`

## Adding New Files

1. Add source files to \`src/\`
2. Add header files to \`include/\`
3. Update \`CMakeLists.txt\` if needed
4. Rebuild the project

## Dependencies

This project uses FetchContent to manage dependencies. To add a new dependency:

\`\`\`cmake
FetchContent_Declare(
    mylib
    GIT_REPOSITORY https://github.com/user/mylib.git
    GIT_TAG v1.0.0
)
FetchContent_MakeAvailable(mylib)
target_link_libraries(\${PROJECT_NAME} mylib)
\`\`\`
EOF

    # Create .gitignore
    cat << EOF > .gitignore
# Build directories
build/
cmake-build-*/
out/
bin/
lib/

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# OS files
.DS_Store
Thumbs.db
*.tmp

# Compiled binaries
*.exe
*.dll
*.so
*.dylib
*.o
*.obj

# CMake generated files
CMakeCache.txt
CMakeFiles/
cmake_install.cmake
install_manifest.txt
compile_commands.json
CTestTestfile.cmake
_deps/

# Test files
*.gcda
*.gcno
*.gcov
coverage.info
*.profraw
EOF

    # Create build script
    cat << EOF > build.sh
#!/bin/bash
# Build script for $project_name


# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "\${BLUE}Building $project_name...\${NC}"

# Create build directory if it doesn't exist
if [[ ! -d "build" ]]; then
    mkdir build
fi

cd build

# Configure
echo -e "\${YELLOW}Configuring...\${NC}"
cmake ..

# Build
echo -e "\${YELLOW}Building...\${NC}"
cmake --build . --config Release

echo -e "\${GREEN}Build complete!\${NC}"
echo -e "\${BLUE}Run with: ./$project_name\${NC}"
EOF

    # Make build script executable
    chmod +x build.sh

    # Create run script
    cat << EOF > run.sh
#!/bin/bash
# Run script for $project_name

if [[ ! -f "build/$project_name" ]]; then
    echo "Binary not found. Building first..."
    ./build.sh
fi

echo "Running $project_name..."
./build/$project_name "\$@"
EOF

    # Make run script executable
    chmod +x run.sh

    stop_timer "cpp_project_creation"
    log_timed_success "cpp_project_creation" "C++ project created successfully"
}

# Main function
main() {
    local project_name=$1
    local cpp_standard=${2:-17}

    # Validate arguments
    if [[ -z "$project_name" ]]; then
        log_error "Project name is required"
        usage
    fi

    # Check if project directory already exists
    if [[ -d "$project_name" ]]; then
        log_error "Directory '$project_name' already exists"
        exit 1
    fi

    echo -e "${BLUE}🚀 Creating C++ Project${NC}"
    echo -e "${BLUE}=====================${NC}"
    echo "Project: $project_name"
    echo "C++ Standard: $cpp_standard"
    echo ""

    # Check prerequisites
    check_prerequisites "$cpp_standard"

    # Create project
    create_cpp_project "$project_name" "$cpp_standard"

    echo ""
    echo -e "${GREEN}🎉 C++ project '$project_name' created successfully!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. cd $project_name"
    echo "2. ./build.sh     # Build the project"
    echo "3. ./run.sh       # Run the application"
    echo "4. To build manually:"
    echo "   mkdir build && cd build"
    echo "   cmake .. && cmake --build . --config Release"
    echo ""
    echo -e "${BLUE}Happy coding! 🎯${NC}"
}

# Run main function
main "$@"
