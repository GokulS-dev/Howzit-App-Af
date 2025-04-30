#!/bin/bash

# Run the build process
npm run build

# Check if the build was successful by checking if the dist folder exists
if [ -d "dist" ]; then
    echo "Build successful. Copying files..."

    # Copy private-key.pem, public-key.pem, and .env into the dist folder
    cp private-key.pem dist/
    cp public-key.pem dist/
    cp .env dist/

    echo "Files copied to the dist folder successfully."
else
    echo "Build failed or dist folder not found."
fi
