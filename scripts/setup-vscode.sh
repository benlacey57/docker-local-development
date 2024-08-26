#!/bin/bash

# Function to display a banner
display_banner() {
    clear
    echo "======================================="
    echo "   Installing Visual Studio Code"
    echo "======================================="
}

# Display banner
display_banner

# Update package list and install dependencies
echo "Installing Dependencies..."
sudo apt-get update -y
sudo apt-get install -y wget gpg

# Update package list and install dependencies
echo "Updating package list and installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y wget gpg

# Download the latest Visual Studio Code .deb package
echo "Downloading Visual Studio Code .deb package..."
wget -q https://go.microsoft.com/fwlink/?LinkID=760868 -O "$HOME/Downloads/vscode.deb" || { echo "Failed to download Visual Studio Code .deb package"; exit 1; }

# Install the .deb package
echo "Installing Visual Studio Code..."
sudo apt-get install -y "$HOME/Downloads/vscode.deb"

# Clean up by removing the downloaded .deb file
rm vscode.deb

# Verify the installation
if command -v code &> /dev/null; then
    echo "Visual Studio Code installed successfully."
else
    echo "Error: Visual Studio Code installation failed."
    exit 1
fi

# Update the package list
sudo apt-get update -y || { echo "Failed to update package list"; exit 1; }
sudo apt-get install -y code

# Configure auto-linting on save and other settings
echo ""
echo "Configuring VS Code Settings..."
mkdir -p "$HOME/.vscode"
cat <<EOL > "$HOME/.vscode/settings.json"
{
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.fixAll.eslint": true,
        "source.fixAll": true
    },
    "[php]": {
        "editor.defaultFormatter": "bmewburn.vscode-intelephense-client",
        "editor.formatOnSave": true
    },
    "[python]": {
        "editor.defaultFormatter": "ms-python.python",
        "editor.formatOnSave": true
    },
    "[javascript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode",
        "editor.formatOnSave": true
    },
    "[typescript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode",
        "editor.formatOnSave": true
    },
    "terminal.integrated.fontSize": 14,
    "terminal.integrated.lineHeight": 1.5,
    "editor.fontSize": 15,
    "workbench.colorTheme": "Default Dark+",
    "workbench.iconTheme": "vscode-icons",
    "editor.minimap.enabled": false
}
EOL

# Install VS Code extensions
echo ""
echo "Installing VS Code Extensions..."
extensions=(
    ms-azuretools.vscode-docker
    ms-vscode-remote.remote-containers
    felixfbecker.php-debug
    bmewburn.vscode-intelephense-client
    cjhowe7.laravel-blade
    onecentlin.laravel5-snippets
    amiralizadeh9480.laravel-extra-intellisense
    vscode-icons-team.vscode-icons
    bradlc.vscode-tailwindcss
    octref.vetur
    hollowtree.vue-snippets
    esbenp.prettier-vscode
    zobo.php-intellisense
    xdebug.php-debug
    yzhang.markdown-all-in-one
    eamodio.gitlens
    mhutchie.git-graph
    ms-vscode.vscode-typescript-next
    rido3.wordpresstools
    ahmadawais.shades-of-purple
    pkief.material-icon-theme
    CoenraadS.bracket-pair-colorizer
)

for extension in "${extensions[@]}"; do
    code --install-extension "$extension" --force || { echo "Failed to install $extension"; }
done

# Output success message
echo ""
echo "Visual Studio Code and required extensions have been successfully installed."
