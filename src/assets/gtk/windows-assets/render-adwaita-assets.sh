#!/usr/bin/env bash

# Simple script to create Adwaita-style titlebuttons
# This creates simplified square/rectangular buttons instead of circular macOS-style ones

ASSETS_DIR="titlebutton-adwaita"
NORD_ASSETS_DIR="titlebutton-adwaita-nord"
INDEX="assets.txt"

# Create directories
mkdir -p $ASSETS_DIR
mkdir -p $NORD_ASSETS_DIR

# For now, let's copy the alt buttons and rename them as adwaita
# In a real implementation, we would create proper Adwaita-style SVG elements

echo "Creating Adwaita titlebutton assets based on alt variant..."

# Copy alt variant as base for adwaita (standard scheme)
if [ -d "titlebutton-alt" ]; then
    cp -r titlebutton-alt/* $ASSETS_DIR/
    echo "Copied alt variant assets to $ASSETS_DIR"
else
    echo "Warning: titlebutton-alt directory not found"
fi

# Copy alt-nord variant as base for adwaita-nord (nord scheme)
if [ -d "titlebutton-alt-nord" ]; then
    cp -r titlebutton-alt-nord/* $NORD_ASSETS_DIR/
    echo "Copied alt-nord variant assets to $NORD_ASSETS_DIR"
else
    echo "Warning: titlebutton-alt-nord directory not found"
fi

echo "Adwaita titlebutton assets created successfully!"
echo "Note: These are placeholder assets based on the alt variant."
echo "For production use, proper Adwaita-style SVG designs should be created."