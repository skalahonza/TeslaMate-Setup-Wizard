#!/bin/bash

generate_password() {
    local length=$1

    if [ -z "$length" ]; then
        echo "Error: Please provide the password length as an argument."
        return 1
    fi

    if ! [[ "$length" =~ ^[0-9]+$ ]]; then
        echo "Error: Password length must be a positive integer."
        return 1
    fi

    # Define character sets for password generation
    lowercase="abcdefghijklmnopqrstuvwxyz"
    uppercase="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    numbers="0123456789"
    special_chars="@#$%&*_+="

    # Combine character sets
    all_chars="$lowercase$uppercase$numbers$special_chars"

    # Generate password
    password=$(tr -dc "$all_chars" < /dev/urandom | head -c "$length")

    echo "$password"
}


# Check if Docker is already installed
if [ -x "$(command -v docker)" ]; then
    echo "Docker is already installed."
else
    # Install Docker
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo rm get-docker.sh
    echo "Docker installation completed."
fi

# Check if Docker Compose is already installed
if [ -x "$(command -v docker-compose)" ]; then
    echo "Docker Compose is already installed."
else
    # Install Docker Compose
    if [ -x "$(command -v docker)" ]; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | cut -d ',' -f1)
        DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/download/${DOCKER_VERSION}/docker-compose-$(uname -s)-$(uname -m)"
    else
        DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)"
    fi

    echo "Installing Docker Compose..."
    sudo curl -L $DOCKER_COMPOSE_URL -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installation completed."
fi

# Add the current user to the docker group
if [ $(id -u) -ne 0 ]; then
    if groups $USER | grep &>/dev/null '\bdocker\b'; then
        echo "Current user ($USER) is already a member of the docker group."
    else
        echo "Adding current user ($USER) to the docker group..."
        sudo usermod -aG docker $USER
        echo "User $USER added to the docker group. Please log out and log back in to apply the changes."
    fi
else
    echo "Please log out and log back in to apply the changes for running Docker without using sudo."
fi


# Check if .env file exists
if [ -f ".env" ]; then
    echo ".env file already exists."
else
    # Create .env file
    echo "Creating .env file..."
    echo "ENCRYPTION_KEY=$(generate_password 32)" >> .env
    echo "DATABASE_PASS=$(generate_password 32)" >> .env
    echo ".env file created."
fi


# Run the solution using docker-compose
echo "Running the solution using docker-compose..."
docker-compose up -d
echo "Solution is up and running."
echo "Open the web interface http://localhost:4000"