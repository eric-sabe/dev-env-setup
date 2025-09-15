#!/bin/bash
# Java Project Quickstart Script
# Creates new Java projects with Maven or Gradle

set -Eeuo pipefail
trap 'echo "[ERROR] quickstart-java failed at ${BASH_SOURCE[0]}:${LINENO}" >&2' ERR

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
    echo "Usage: $0 <project-name> [maven|gradle] [java-version]"
    echo ""
    echo "Arguments:"
    echo "  project-name    Name of the Java project to create"
    echo "  build-tool      Build tool to use: maven (default) or gradle"
    echo "  java-version    Java version to use: 17 (default), 21, etc."
    echo ""
    echo "Examples:"
    echo "  $0 my-app"
    echo "  $0 my-app maven 17"
    echo "  $0 my-app gradle 21"
    exit 1
}

# Check prerequisites
check_prerequisites() {
    local build_tool=$1
    local java_version=$2

    # Check Java
    if ! command -v java &>/dev/null; then
        log_error "Java is not installed. Please run the platform setup script first."
        exit 1
    fi

    # Check SDKMAN
    if [[ ! -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
        log_error "SDKMAN is not installed. Please run the platform setup script first."
        exit 1
    fi

    # Load SDKMAN
    source "$HOME/.sdkman/bin/sdkman-init.sh"

    # Check/set Java version
    if [[ -n "$java_version" ]]; then
        if ! sdk list java | grep -q "$java_version"; then
            log_info "Installing Java $java_version..."
            sdk install java "$java_version" || {
                log_error "Failed to install Java $java_version"
                exit 1
            }
        fi
        sdk use java "$java_version"
    fi

    # Check build tool
    case $build_tool in
        maven)
            if ! command -v mvn &>/dev/null; then
                log_error "Maven is not installed. Please run the platform setup script first."
                exit 1
            fi
            ;;
        gradle)
            if ! command -v gradle &>/dev/null; then
                log_error "Gradle is not installed. Please run the platform setup script first."
                exit 1
            fi
            ;;
        *)
            log_error "Unsupported build tool: $build_tool"
            usage
            ;;
    esac

    log_success "Prerequisites check passed"
}

# Create Maven project
create_maven_project() {
    local project_name=$1
    local java_version=${2:-17}

    log_info "Creating Maven project: $project_name"

    # Create project directory
    mkdir -p "$project_name"
    cd "$project_name"

    # Create Maven wrapper
    mvn wrapper:wrapper

    # Create pom.xml
    cat << EOF > pom.xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>$project_name</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name>$project_name</name>
    <description>A Java application</description>

    <properties>
        <maven.compiler.source>$java_version</maven.compiler.source>
        <maven.compiler.target>$java_version</maven.compiler.target>
        <maven.compiler.release>$java_version</maven.compiler.release>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <junit.version>5.10.0</junit.version>
        <maven-surefire-plugin.version>3.1.2</maven-surefire-plugin.version>
    </properties>

    <dependencies>
        <!-- JUnit 5 -->
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter</artifactId>
            <version>\${junit.version}</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.11.0</version>
                <configuration>
                    <source>\${maven.compiler.source}</source>
                    <target>\${maven.compiler.target}</target>
                    <release>\${maven.compiler.release}</release>
                </configuration>
            </plugin>

            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>\${maven-surefire-plugin.version}</version>
            </plugin>

            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-jar-plugin</artifactId>
                <version>3.3.0</version>
                <configuration>
                    <archive>
                        <manifest>
                            <mainClass>com.example.App</mainClass>
                        </manifest>
                    </archive>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
EOF

    # Create source directories
    mkdir -p src/main/java/com/example
    mkdir -p src/test/java/com/example
    mkdir -p src/main/resources
    mkdir -p src/test/resources

    # Create main class
    cat << EOF > src/main/java/com/example/App.java
package com.example;

/**
 * Hello world Java application
 */
public class App {
    public static void main(String[] args) {
        System.out.println("Hello World!");
    }

    public String getGreeting() {
        return "Hello World!";
    }
}
EOF

    # Create test class
    cat << EOF > src/test/java/com/example/AppTest.java
package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit test for App
 */
class AppTest {
    @Test
    void testGetGreeting() {
        App app = new App();
        assertEquals("Hello World!", app.getGreeting());
    }
}
EOF

    # Create README
    cat << EOF > README.md
# $project_name

A Java application built with Maven.

## Prerequisites

- Java $java_version+
- Maven 3.6+

## Building

\`\`\`bash
./mvnw clean compile
\`\`\`

## Running

\`\`\`bash
./mvnw exec:java -Dexec.mainClass="com.example.App"
\`\`\`

## Testing

\`\`\`bash
./mvnw test
\`\`\`

## Packaging

\`\`\`bash
./mvnw package
\`\`\`

## Running the JAR

\`\`\`bash
java -jar target/$project_name-1.0.0-SNAPSHOT.jar
\`\`\`
EOF

    # Create .gitignore
    cat << EOF > .gitignore
# Compiled class file
*.class

# Log file
*.log

# BlueJ files
*.ctxt

# Mobile Tools for Java (J2ME)
.mtj.tmp/

# Package Files #
*.jar
*.war
*.nar
*.ear
*.zip
*.tar.gz
*.rar

# virtual machine crash logs, see http://www.java.com/en/download/help/error_hotspot.xml
hs_err_pid*
replay_pid*

# Maven
target/
pom.xml.tag
pom.xml.releaseBackup
pom.xml.versionsBackup
pom.xml.next
release.properties
dependency-reduced-pom.xml
buildNumber.properties
.mvn/timing.properties
.mvn/wrapper/maven-wrapper.jar

# Gradle
.gradle
build/

# Eclipse
.project
.classpath
.settings/

# IntelliJ IDEA
.idea/
*.iws
*.iml
*.ipr

# VS Code
.vscode/

# OS
.DS_Store
Thumbs.db
EOF

    log_success "Maven project created successfully"
}

# Create Gradle project
create_gradle_project() {
    local project_name=$1
    local java_version=${2:-17}

    log_info "Creating Gradle project: $project_name"

    # Create project directory
    mkdir -p "$project_name"
    cd "$project_name"

    # Create Gradle wrapper
    gradle wrapper

    # Create settings.gradle
    cat << EOF > settings.gradle
rootProject.name = '$project_name'
EOF

    # Create build.gradle
    cat << EOF > build.gradle
plugins {
    id 'java'
    id 'application'
}

group = 'com.example'
version = '1.0.0-SNAPSHOT'
sourceCompatibility = '$java_version'
targetCompatibility = '$java_version'

repositories {
    mavenCentral()
}

dependencies {
    testImplementation 'org.junit.jupiter:junit-jupiter:5.10.0'
    testRuntimeOnly 'org.junit.platform:junit-platform-launcher'
}

application {
    mainClassName = 'com.example.App'
}

test {
    useJUnitPlatform()
}

jar {
    manifest {
        attributes 'Main-Class': 'com.example.App'
    }
}
EOF

    # Create source directories
    mkdir -p src/main/java/com/example
    mkdir -p src/test/java/com/example
    mkdir -p src/main/resources
    mkdir -p src/test/resources

    # Create main class
    cat << EOF > src/main/java/com/example/App.java
package com.example;

/**
 * Hello world Java application
 */
public class App {
    public static void main(String[] args) {
        System.out.println("Hello World!");
    }

    public String getGreeting() {
        return "Hello World!";
    }
}
EOF

    # Create test class
    cat << EOF > src/test/java/com/example/AppTest.java
package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit test for App
 */
class AppTest {
    @Test
    void testGetGreeting() {
        App app = new App();
        assertEquals("Hello World!", app.getGreeting());
    }
}
EOF

    # Create README
    cat << EOF > README.md
# $project_name

A Java application built with Gradle.

## Prerequisites

- Java $java_version+
- Gradle 7.0+

## Building

\`\`\`bash
./gradlew build
\`\`\`

## Running

\`\`\`bash
./gradlew run
\`\`\`

## Testing

\`\`\`bash
./gradlew test
\`\`\`

## Creating JAR

\`\`\`bash
./gradlew jar
\`\`\`

## Running the JAR

\`\`\`bash
java -jar build/libs/$project_name-1.0.0-SNAPSHOT.jar
\`\`\`
EOF

    # Create .gitignore (same as Maven)
    cat << EOF > .gitignore
# Compiled class file
*.class

# Log file
*.log

# BlueJ files
*.ctxt

# Mobile Tools for Java (J2ME)
.mtj.tmp/

# Package Files #
*.jar
*.war
*.nar
*.ear
*.zip
*.tar.gz
*.rar

# virtual machine crash logs, see http://www.java.com/en/download/help/error_hotspot.xml
hs_err_pid*
replay_pid*

# Maven
target/
pom.xml.tag
pom.xml.releaseBackup
pom.xml.versionsBackup
pom.xml.next
release.properties
dependency-reduced-pom.xml
buildNumber.properties
.mvn/timing.properties
.mvn/wrapper/maven-wrapper.jar

# Gradle
.gradle
build/

# Eclipse
.project
.classpath
.settings/

# IntelliJ IDEA
.idea/
*.iws
*.iml
*.ipr

# VS Code
.vscode/

# OS
.DS_Store
Thumbs.db
EOF

    log_success "Gradle project created successfully"
}

# Main function
main() {
    local project_name=$1
    local build_tool=${2:-maven}
    local java_version=${3:-17}

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

    echo -e "${BLUE}🚀 Creating Java Project${NC}"
    echo -e "${BLUE}=======================${NC}"
    echo "Project: $project_name"
    echo "Build Tool: $build_tool"
    echo "Java Version: $java_version"
    echo ""

    # Check prerequisites
    check_prerequisites "$build_tool" "$java_version"

    # Create project based on build tool
    case $build_tool in
        maven)
            create_maven_project "$project_name" "$java_version"
            ;;
        gradle)
            create_gradle_project "$project_name" "$java_version"
            ;;
    esac

    echo ""
    echo -e "${GREEN}🎉 Java project '$project_name' created successfully!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. cd $project_name"
    if [[ "$build_tool" == "maven" ]]; then
        echo "2. ./mvnw compile  # Compile the project"
        echo "3. ./mvnw test     # Run tests"
        echo "4. ./mvnw exec:java -Dexec.mainClass=\"com.example.App\"  # Run the application"
    else
        echo "2. ./gradlew build  # Build the project"
        echo "3. ./gradlew test   # Run tests"
        echo "4. ./gradlew run    # Run the application"
    fi
    echo ""
    echo -e "${BLUE}Happy coding! 🎯${NC}"
}

# Run main function
main "$@"
