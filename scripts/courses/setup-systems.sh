#!/bin/bash
# Systems Programming Course Setup Script
# Installs systems programming tools and development environment

set -Eeuo pipefail  # Exit on any error, unset var error, pipefail
trap 'echo "[ERROR] setup-systems failed at ${BASH_SOURCE[0]}:${LINENO}" >&2' ERR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTIL_DIR="${SCRIPT_DIR%/courses*/}/utils"
[[ -f "$UTIL_DIR/cross-platform.sh" ]] && source "$UTIL_DIR/cross-platform.sh"
[[ -f "$UTIL_DIR/verify.sh" ]] && source "$UTIL_DIR/verify.sh"
pip_install() { (python3 -m pip install --user "$@" || python -m pip install --user "$@") || true; }

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

# Install debugging tools
install_debugging_tools() {
    log_info "Installing debugging tools..."

    case $PLATFORM in
        macos)
            # GDB is not available on macOS, use LLDB
            brew install lldb
            ;;
        ubuntu)
            sudo apt install -y gdb lldb clang-format clang-tidy
            ;;
        redhat)
            sudo yum install -y gdb lldb clang-tools-extra
            ;;
        arch)
            sudo pacman -S --noconfirm gdb lldb clang
            ;;
        windows)
            log_info "Install debugging tools manually or use WSL"
            ;;
    esac

    log_success "Debugging tools installed"
}

# Install memory debugging tools
install_memory_tools() {
    log_info "Installing memory debugging tools..."

    case $PLATFORM in
        macos)
            # Valgrind is not available on macOS
            log_info "Valgrind not available on macOS, consider using Instruments"
            ;;
        ubuntu)
            sudo apt install -y valgrind massif-visualizer
            ;;
        redhat)
            sudo yum install -y valgrind
            ;;
        arch)
            sudo pacman -S --noconfirm valgrind
            ;;
        windows)
            log_info "Memory debugging tools not available on Windows"
            ;;
    esac

    log_success "Memory debugging tools installed"
}

# Install performance analysis tools
install_performance_tools() {
    log_info "Installing performance analysis tools..."

    case $PLATFORM in
        macos)
            brew install perf
            ;;
        ubuntu)
            sudo apt install -y linux-tools-common linux-tools-generic
            sudo apt install -y perf-tools-unstable
            sudo apt install -y htop iotop sysstat
            ;;
        redhat)
            sudo yum install -y perf
            sudo yum install -y htop iotop sysstat
            ;;
        arch)
            sudo pacman -S --noconfirm perf htop iotop sysstat
            ;;
        windows)
            log_info "Performance tools not available on Windows"
            ;;
    esac

    log_success "Performance analysis tools installed"
}

# Install system monitoring tools
install_system_tools() {
    log_info "Installing system monitoring tools..."

    case $PLATFORM in
        macos)
            brew install htop
            ;;
        ubuntu)
            sudo apt install -y htop iotop ncdu tree
            sudo apt install -y strace ltrace
            ;;
        redhat)
            sudo yum install -y htop iotop ncdu tree
            sudo yum install -y strace ltrace
            ;;
        arch)
            sudo pacman -S --noconfirm htop iotop ncdu tree
            sudo pacman -S --noconfirm strace ltrace
            ;;
        windows)
            log_info "System monitoring tools not available on Windows"
            ;;
    esac

    log_success "System monitoring tools installed"
}

# Install build tools and compilers
install_build_tools() {
    log_info "Installing build tools and compilers..."

    case $PLATFORM in
        macos)
            brew install cmake ninja make autoconf automake
            brew install gcc llvm
            ;;
        ubuntu)
            sudo apt install -y build-essential cmake ninja-build
            sudo apt install -y gcc-multilib g++-multilib
            sudo apt install -y clang llvm lld
            ;;
        redhat)
            sudo yum groupinstall -y "Development Tools"
            sudo yum install -y cmake ninja-build
            sudo yum install -y clang llvm
            ;;
        arch)
            sudo pacman -S --noconfirm base-devel cmake ninja
            sudo pacman -S --noconfirm gcc clang llvm
            ;;
        windows)
            log_info "Build tools should be available in WSL or MSYS2"
            ;;
    esac

    log_success "Build tools and compilers installed"
}

# Install cross-compilation tools
install_cross_compilation() {
    log_info "Installing cross-compilation tools..."

    case $PLATFORM in
        ubuntu)
            sudo apt install -y gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf
            sudo apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
            ;;
        redhat)
            sudo yum install -y gcc-arm-linux-gnu gcc-c++-arm-linux-gnu
            ;;
        arch)
            sudo pacman -S --noconfirm arm-linux-gnueabihf-gcc
            ;;
        macos)
            log_info "Cross-compilation tools may require manual installation on macOS"
            ;;
        windows)
            log_info "Cross-compilation tools not available on Windows"
            ;;
    esac

    log_success "Cross-compilation tools installed"
}

# Install QEMU for emulation
install_qemu() {
    log_info "Installing QEMU for system emulation..."

    case $PLATFORM in
        macos)
            brew install qemu
            ;;
        ubuntu)
            sudo apt install -y qemu qemu-system qemu-user
            ;;
        redhat)
            sudo yum install -y qemu qemu-system qemu-user
            ;;
        arch)
            sudo pacman -S --noconfirm qemu
            ;;
        windows)
            log_info "QEMU not available on Windows"
            ;;
    esac

    log_success "QEMU installed"
}

# Install additional development tools
install_dev_tools() {
    log_info "Installing additional development tools..."

    # Install Python for scripting and testing
    pip_install pytest gdbgui

    # Install additional utilities
    case $PLATFORM in
        ubuntu)
            sudo apt install -y shellcheck cppcheck flawfinder
            ;;
        redhat)
            sudo yum install -y ShellCheck cppcheck
            ;;
        arch)
            sudo pacman -S --noconfirm shellcheck cppcheck
            ;;
        macos)
            brew install shellcheck cppcheck
            ;;
    esac

    log_success "Additional development tools installed"
}

# Create systems programming course structure
create_course_structure() {
    log_info "Creating systems programming course directory structure..."

    local course_dir="$HOME/dev/current/systems-course"
    mkdir -p "$course_dir"/{src,include,tests,build,docs,scripts}

    # Create sample C program
    cat << 'EOF' > "$course_dir/src/hello.c"
/*
 * Hello World in C
 * Demonstrates basic C programming concepts
 */

#include <stdio.h>
#include <stdlib.h>
#include "hello.h"

int main(int argc, char *argv[]) {
    printf("Hello, Systems Programming!\n");

    if (argc > 1) {
        printf("Arguments:\n");
        for (int i = 1; i < argc; i++) {
            printf("  %d: %s\n", i, argv[i]);
        }
    }

    // Demonstrate memory allocation
    int *numbers = malloc(sizeof(int) * 10);
    if (numbers == NULL) {
        fprintf(stderr, "Memory allocation failed\n");
        return EXIT_FAILURE;
    }

    // Initialize array
    for (int i = 0; i < 10; i++) {
        numbers[i] = i * i;
        printf("numbers[%d] = %d\n", i, numbers[i]);
    }

    // Clean up
    free(numbers);

    return EXIT_SUCCESS;
}
EOF

    # Create header file
    cat << 'EOF' > "$course_dir/include/hello.h"
/*
 * Header file for hello.c
 */

#ifndef HELLO_H
#define HELLO_H

#include <stdio.h>

// Function declarations would go here

#endif /* HELLO_H */
EOF

    # Create Makefile
    cat << 'EOF' > "$course_dir/Makefile"
# Makefile for Systems Programming Course

CC = gcc
CFLAGS = -Wall -Wextra -Wpedantic -std=c11 -g -O0
LDFLAGS =

# Directories
SRC_DIR = src
INC_DIR = include
BUILD_DIR = build
TEST_DIR = tests

# Files
SRCS = $(wildcard $(SRC_DIR)/*.c)
OBJS = $(patsubst $(SRC_DIR)/%.c, $(BUILD_DIR)/%.o, $(SRCS))
TARGET = $(BUILD_DIR)/hello

# Default target
all: $(TARGET)

# Link object files
$(TARGET): $(OBJS)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(LDFLAGS) $^ -o $@

# Compile source files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -I$(INC_DIR) -c $< -o $@

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)/*.o $(TARGET)

# Run the program
run: $(TARGET)
	./$(TARGET)

# Debug with gdb
debug: $(TARGET)
	gdb ./$(TARGET)

# Memory check with valgrind
memcheck: $(TARGET)
	valgrind --leak-check=full ./$(TARGET)

# Format code
format:
	clang-format -i $(SRC_DIR)/*.c $(INC_DIR)/*.h

# Static analysis
analyze:
	cppcheck --enable=all --std=c11 $(SRC_DIR)/ $(INC_DIR)/

.PHONY: all clean run debug memcheck format analyze
EOF

    # Create CMakeLists.txt
    cat << 'EOF' > "$course_dir/CMakeLists.txt"
cmake_minimum_required(VERSION 3.10)
project(SystemsProgrammingCourse C)

# Set C standard
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Compiler flags
if(MSVC)
    add_compile_options(/W4)
else()
    add_compile_options(-Wall -Wextra -Wpedantic -g -O0)
endif()

# Include directories
include_directories(include)

# Source files
file(GLOB SOURCES "src/*.c")

# Create executable
add_executable(${PROJECT_NAME} ${SOURCES})

# Testing
enable_testing()

# Custom targets
add_custom_target(format
    COMMAND clang-format -i src/*.c include/*.h
    COMMENT "Formatting code"
)

add_custom_target(analyze
    COMMAND cppcheck --enable=all --std=c11 src/ include/
    COMMENT "Static analysis"
)
EOF

    # Create test file
    cat << 'EOF' > "$course_dir/tests/test_memory.c"
/*
 * Memory management test
 */

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

void test_memory_allocation() {
    // Test successful allocation
    int *ptr = malloc(sizeof(int) * 100);
    assert(ptr != NULL);

    // Test memory access
    for (int i = 0; i < 100; i++) {
        ptr[i] = i;
    }

    // Test free
    free(ptr);
    printf("Memory allocation test passed\n");
}

void test_null_pointers() {
    int *ptr = NULL;

    // This should cause a segmentation fault if uncommented
    // *ptr = 42;

    printf("Null pointer test passed (no crash)\n");
}

int main() {
    printf("Running memory tests...\n");

    test_memory_allocation();
    test_null_pointers();

    printf("All tests passed!\n");
    return 0;
}
EOF

    # Create build script
    cat << 'EOF' > "$course_dir/build.sh"
#!/bin/bash
# Build script for systems programming course

set -e

echo "Building systems programming examples..."

# Create build directory
mkdir -p build

# Build with Make
echo "Building with Make..."
make clean
make

# Build with CMake
echo "Building with CMake..."
cd build
cmake ..
cmake --build .

cd ..

echo "Build complete!"
echo "Run with: ./build/hello"
echo "Debug with: make debug"
echo "Memory check with: make memcheck"
EOF
    chmod +x "$course_dir/build.sh"

    # Create README
    cat << EOF > "$course_dir/README.md"
# Systems Programming Course

## Course Directory Structure
- \`src/\`: Source code files (.c, .cpp)
- \`include/\`: Header files (.h, .hpp)
- \`tests/\`: Test programs and unit tests
- \`build/\`: Build artifacts and executables
- \`docs/\`: Documentation and notes
- \`scripts/\`: Build scripts and utilities

## Building and Running

### Using Make
\`\`\`bash
# Build the project
make

# Run the program
make run

# Debug with gdb
make debug

# Check for memory leaks
make memcheck

# Format code
make format

# Static analysis
make analyze

# Clean build artifacts
make clean
\`\`\`

### Using CMake
\`\`\`bash
# Create build directory
mkdir build
cd build

# Configure
cmake ..

# Build
cmake --build .

# Run
./SystemsProgrammingCourse
\`\`\`

### Manual Compilation
\`\`\`bash
# Compile single file
gcc -Wall -Wextra -g -o hello src/hello.c

# Compile with debugging
gcc -Wall -Wextra -g -O0 -o hello src/hello.c

# Compile with optimizations
gcc -Wall -Wextra -O2 -o hello src/hello.c
\`\`\`

## Debugging

### GDB Commands
\`\`\`bash
# Start gdb
gdb ./hello

# Set breakpoint
break main

# Run program
run

# Step through code
next
step

# Print variables
print variable_name

# Continue execution
continue

# Quit
quit
\`\`\`

### Valgrind (Memory Debugging)
\`\`\`bash
# Check for memory leaks
valgrind --leak-check=full ./hello

# Track memory usage
valgrind --tool=massif ./hello
ms_print massif.out.*

# Check for uninitialized memory
valgrind --track-origins=yes ./hello
\`\`\`

## Performance Analysis

### Using perf
\`\`\`bash
# Profile program execution
perf record ./hello
perf report

# Sample CPU performance
perf stat ./hello
\`\`\`

### Using strace
\`\`\`bash
# Trace system calls
strace ./hello

# Count system calls
strace -c ./hello
\`\`\`

## Code Quality Tools

### Static Analysis
\`\`\`bash
# Cppcheck
cppcheck --enable=all --std=c11 src/ include/

# Clang Static Analyzer
scan-build gcc -c src/hello.c
\`\`\`

### Code Formatting
\`\`\`bash
# Clang-format
clang-format -i src/*.c include/*.h

# View diff
clang-format --dry-run -Werror src/*.c include/*.h
\`\`\`

## Common C Programming Concepts

### Memory Management
\`\`\`c
// Stack allocation (automatic)
int numbers[100];

// Heap allocation
int *ptr = malloc(sizeof(int) * 100);
if (ptr == NULL) {
    // Handle allocation failure
}

// Use the memory
for (int i = 0; i < 100; i++) {
    ptr[i] = i * i;
}

// Free the memory
free(ptr);
\`\`\`

### File I/O
\`\`\`c
#include <stdio.h>

FILE *file = fopen("data.txt", "r");
if (file == NULL) {
    perror("Error opening file");
    return 1;
}

char buffer[256];
while (fgets(buffer, sizeof(buffer), file)) {
    printf("%s", buffer);
}

fclose(file);
\`\`\`

### Error Handling
\`\`\`c
#include <errno.h>
#include <string.h>

int result = some_function();
if (result == -1) {
    fprintf(stderr, "Error: %s\n", strerror(errno));
    exit(EXIT_FAILURE);
}
\`\`\`

## Best Practices

### 1. Memory Management
- Always check return values from malloc/calloc/realloc
- Free allocated memory when no longer needed
- Use valgrind to check for memory leaks
- Initialize pointers to NULL

### 2. Error Handling
- Check return values from system calls
- Use errno and strerror for error reporting
- Handle errors gracefully, don't just exit
- Log errors appropriately

### 3. Code Organization
- Use header files for function declarations
- Split code into logical modules
- Use consistent naming conventions
- Document your code with comments

### 4. Performance
- Profile your code with perf
- Use appropriate data structures
- Minimize memory allocations in loops
- Use const where possible

### 5. Security
- Validate input data
- Use safe string functions (strncpy, strncat)
- Be careful with buffer sizes
- Use static analysis tools

## System Calls

### Process Management
\`\`\`c
#include <unistd.h>
#include <sys/wait.h>

pid_t pid = fork();
if (pid == 0) {
    // Child process
    execl("/bin/ls", "ls", "-l", NULL);
} else if (pid > 0) {
    // Parent process
    int status;
    waitpid(pid, &status, 0);
} else {
    // Error
    perror("fork");
}
\`\`\`

### File Operations
\`\`\`c
#include <fcntl.h>
#include <unistd.h>

int fd = open("file.txt", O_RDONLY);
if (fd == -1) {
    perror("open");
    return 1;
}

char buffer[1024];
ssize_t bytes_read = read(fd, buffer, sizeof(buffer));
close(fd);
\`\`\`

## Cross-Platform Development

### Conditional Compilation
\`\`\`c
#ifdef _WIN32
    // Windows-specific code
    #include <windows.h>
#elif __linux__
    // Linux-specific code
    #include <unistd.h>
#elif __APPLE__
    // macOS-specific code
    #include <unistd.h>
#endif
\`\`\`

## Resources

### Documentation
- [C Programming Language](https://en.wikipedia.org/wiki/C_(programming_language))
- [POSIX Standard](https://pubs.opengroup.org/onlinepubs/9699919799/)
- [Linux Manual Pages](https://man7.org/linux/man-pages/)

### Tools
- [GDB Documentation](https://sourceware.org/gdb/documentation/)
- [Valgrind Documentation](https://valgrind.org/docs/manual/)
- [CMake Documentation](https://cmake.org/documentation/)

### Learning Resources
- [Beej's Guide to C Programming](https://beej.us/guide/bgc/)
- [Linux System Programming](https://www.oreilly.com/library/view/linux-system-programming/9781449341534/)
- [The C Programming Language (K&R)](https://en.wikipedia.org/wiki/The_C_Programming_Language)
EOF

    log_success "Systems programming course structure created at $course_dir"
}

run_verification() {
    log_info "Running post-install verification checks..."
    verify_command gcc "GCC compiler"
    verify_command g++ "G++ compiler" || true
    verify_command clang "Clang compiler" || true
    verify_command make "Make build tool"
    verify_command cmake "CMake build system"
    verify_command ninja "Ninja build system" || true
    verify_command gdb "GDB debugger" || true
    verify_command lldb "LLDB debugger" || true
    verify_command valgrind "Valgrind memory checker" || true
    verify_command perf "perf profiler" || true
    verify_command qemu-system-x86_64 "QEMU x86_64" || true
    verify_command qemu-system-aarch64 "QEMU aarch64" || true
    # small compile smoke test
    if command -v gcc &>/dev/null; then
        tmpdir=$(mktemp -d)
        echo 'int main(){return 0;}' > "$tmpdir/test.c"
        if gcc "$tmpdir/test.c" -o "$tmpdir/a.out" 2>/dev/null && "$tmpdir/a.out"; then
            log_success "GCC compilation smoke test passed"
        else
            log_warning "GCC compilation smoke test failed"
        fi
        rm -rf "$tmpdir"
    fi
    print_verification_summary || log_warning "Some systems programming components failed verification"
}

# Main function
main() {
    echo -e "${BLUE}🚀 Setting up Systems Programming Course Environment${NC}"
    echo -e "${BLUE}=====================================================${NC}"

    detect_platform

    install_build_tools
    install_debugging_tools
    install_memory_tools
    install_performance_tools
    install_system_tools
    install_cross_compilation
    install_qemu
    install_dev_tools
    create_course_structure
    run_verification

    echo ""
    echo -e "${GREEN}🎉 Systems Programming course setup complete!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Review the course materials in ~/dev/current/systems-course/"
    echo "2. Build the sample program: cd ~/dev/current/systems-course && ./build.sh"
    echo "3. Run the program: make run"
    echo "4. Debug the program: make debug"
    echo "5. Check for memory leaks: make memcheck"
    echo ""
    echo -e "${BLUE}Happy systems programming! 🎯${NC}"
}

# Run main function
main "$@"
