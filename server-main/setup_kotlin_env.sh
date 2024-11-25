#!/bin/bash

# Exit on any error
set -e

echo "Setting up environment for Kotlin scripting..."

# Function to check and install dependencies
install_dependency() {
    local package_name=$1
    if ! command -v "$package_name" &> /dev/null; then
        echo "Installing $package_name..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if command -v apt-get &> /dev/null; then
                sudo apt-get update
                sudo apt-get install -y "$package_name"
            elif command -v yum &> /dev/null; then
                sudo yum install -y "$package_name"
            else
                echo "Unsupported package manager. Install $package_name manually."
                exit 1
            fi
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            if command -v brew &> /dev/null; then
                brew install "$package_name"
            else
                echo "Homebrew is not installed. Install Homebrew and try again."
                exit 1
            fi
        else
            echo "Unsupported OS. Install $package_name manually."
            exit 1
        fi
    else
        echo "$package_name is already installed."
    fi
}

# Install Java JDK
install_dependency "java"

# Check and install Kotlin if not already installed
if ! command -v kotlinc &> /dev/null; then
    echo "Installing Kotlin compiler..."
    if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* ]]; then
        curl -s https://get.sdkman.io | bash
        source "$HOME/.sdkman/bin/sdkman-init.sh"
        sdk install kotlin
    else
        echo "Unsupported OS. Install Kotlin manually."
        exit 1
    fi
else
    echo "Kotlin compiler is already installed."
fi

# Set up environment variables
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
export PATH=$JAVA_HOME/bin:$PATH
echo "JAVA_HOME is set to $JAVA_HOME"
echo "PATH is updated to include Kotlin and Java binaries."

# Confirm installation
echo "Java version:"
java -version
echo "Kotlin version:"
kotlinc -version

echo "Environment setup complete. You can now run Kotlin scripts."
