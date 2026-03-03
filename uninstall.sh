#!/bin/bash
# Klipper Resonance Calibration - Uninstaller

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}================================================${NC}"
echo -e "${RED}  Klipper Resonance Calibration Uninstaller${NC}"
echo -e "${RED}================================================${NC}"
echo ""

# --- Detect printer_data ---
PRINTER_DATA=""
for candidate in "$HOME/printer_data" "/home/pi/printer_data" "/home/mks/printer_data" "/home/biqu/printer_data" "/home/orangepi/printer_data"; do
    if [ -d "$candidate" ]; then
        PRINTER_DATA="$candidate"
        break
    fi
done

if [ -z "$PRINTER_DATA" ]; then
    echo -e "${YELLOW}Could not auto-detect printer_data directory.${NC}"
    echo "Please enter the full path (e.g. /home/pi/printer_data):"
    read -r PRINTER_DATA
    if [ ! -d "$PRINTER_DATA" ]; then
        echo -e "${RED}ERROR: Directory not found: $PRINTER_DATA${NC}"
        exit 1
    fi
fi

CONFIG_DIR="$PRINTER_DATA/config"
PRINTER_CFG="$CONFIG_DIR/printer.cfg"

# --- Remove installed files ---
echo "Removing installed files..."

remove_file() {
    if [ -f "$1" ]; then
        rm "$1"
        echo -e "${GREEN}✓ Removed: $1${NC}"
    else
        echo -e "${YELLOW}  Not found (skipping): $1${NC}"
    fi
}

remove_file "$CONFIG_DIR/resonance_calibration_macros.cfg"
remove_file "$CONFIG_DIR/shell_commands.cfg"
remove_file "$CONFIG_DIR/scripts/generate_resonance_graph.sh"

# Remove scripts dir if empty
if [ -d "$CONFIG_DIR/scripts" ] && [ -z "$(ls -A "$CONFIG_DIR/scripts")" ]; then
    rmdir "$CONFIG_DIR/scripts"
    echo -e "${GREEN}✓ Removed empty scripts directory${NC}"
fi

# --- Remove includes from printer.cfg ---
if [ -f "$PRINTER_CFG" ]; then
    echo "Cleaning up printer.cfg..."
    sed -i '/^\[include resonance_calibration_macros\.cfg\]/d' "$PRINTER_CFG"
    sed -i '/^\[include shell_commands\.cfg\]/d' "$PRINTER_CFG"
    echo -e "${GREEN}✓ Removed includes from printer.cfg${NC}"
fi

# --- Optionally remove graphs ---
GRAPHS_DIR="$CONFIG_DIR/resonance_graphs"
if [ -d "$GRAPHS_DIR" ]; then
    echo ""
    echo -e "${YELLOW}Resonance graphs found at: $GRAPHS_DIR${NC}"
    read -r -p "Delete saved graphs? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -rf "$GRAPHS_DIR"
        echo -e "${GREEN}✓ Graphs deleted${NC}"
    else
        echo "Graphs kept."
    fi
fi

# --- Optionally remove the repo ---
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo ""
read -r -p "Remove the cloned repo at $REPO_DIR? [y/N] " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    rm -rf "$REPO_DIR"
    echo -e "${GREEN}✓ Repo removed${NC}"
fi

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Uninstall complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "${YELLOW}Restart Klipper to apply changes:${NC}"
echo "  sudo systemctl restart klipper"
echo ""
