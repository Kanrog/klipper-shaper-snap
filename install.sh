#!/bin/bash
# Klipper Shaper Snap - Installer
# https://github.com/Kanrog/klipper-shaper-snap

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Klipper Shaper Snap - Installer${NC}"
echo -e "${GREEN}================================================${NC}"
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
echo -e "${GREEN}✓ printer_data: $PRINTER_DATA${NC}"

# --- Detect Klipper scripts ---
KLIPPER_SCRIPTS=""
for candidate in "$HOME/klipper/scripts" "/home/pi/klipper/scripts" "/home/mks/klipper/scripts" "/home/biqu/klipper/scripts" "/home/orangepi/klipper/scripts"; do
    if [ -f "$candidate/calibrate_shaper.py" ]; then
        KLIPPER_SCRIPTS="$candidate"
        break
    fi
done

if [ -z "$KLIPPER_SCRIPTS" ]; then
    echo -e "${YELLOW}Could not auto-detect Klipper scripts directory.${NC}"
    echo "Please enter the full path to klipper/scripts (e.g. /home/pi/klipper/scripts):"
    read -r KLIPPER_SCRIPTS
    if [ ! -f "$KLIPPER_SCRIPTS/calibrate_shaper.py" ]; then
        echo -e "${RED}ERROR: calibrate_shaper.py not found in: $KLIPPER_SCRIPTS${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✓ Klipper scripts: $KLIPPER_SCRIPTS${NC}"

# --- Check for gcode_shell_command ---
SHELL_CMD_PATH=""
for candidate in "$HOME/klipper/klippy/extras/gcode_shell_command.py" \
                 "/home/pi/klipper/klippy/extras/gcode_shell_command.py" \
                 "/home/mks/klipper/klippy/extras/gcode_shell_command.py" \
                 "/home/biqu/klipper/klippy/extras/gcode_shell_command.py" \
                 "/home/orangepi/klipper/klippy/extras/gcode_shell_command.py"; do
    if [ -f "$candidate" ]; then
        SHELL_CMD_PATH="$candidate"
        break
    fi
done

if [ -z "$SHELL_CMD_PATH" ]; then
    echo ""
    echo -e "${YELLOW}WARNING: gcode_shell_command.py not found.${NC}"
    echo "This plugin is required. Attempting to download from Kiauh..."

    KIAUH_URL="https://raw.githubusercontent.com/dw-0/kiauh/master/resources/gcode_shell_command.py"
    DEST_PATH="$HOME/klipper/klippy/extras/gcode_shell_command.py"

    if wget -q "$KIAUH_URL" -O "$DEST_PATH"; then
        echo -e "${GREEN}✓ gcode_shell_command.py installed${NC}"
    else
        echo -e "${RED}ERROR: Failed to download gcode_shell_command.py${NC}"
        echo "Please install it manually via Kiauh: Advanced > Install > gcode_shell_command"
        exit 1
    fi
else
    echo -e "${GREEN}✓ gcode_shell_command.py found${NC}"
fi

# --- Set up paths ---
CONFIG_DIR="$PRINTER_DATA/config"
SCRIPTS_DIR="$CONFIG_DIR/scripts"
OUTPUT_DIR="$CONFIG_DIR/resonance_graphs"

echo ""
echo "Creating directories..."
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$OUTPUT_DIR"

# --- Install config files ---
echo "Installing config files..."
cp "$REPO_DIR/resonance_calibration_macros.cfg" "$CONFIG_DIR/resonance_calibration_macros.cfg"

sed \
    -e "s|__SCRIPTS_DIR__|$SCRIPTS_DIR|g" \
    "$REPO_DIR/shell_commands.cfg" > "$CONFIG_DIR/shell_commands.cfg"

# --- Install shell script with real paths substituted ---
echo "Installing shell script..."
sed \
    -e "s|__OUTPUT_DIR__|$OUTPUT_DIR|g" \
    -e "s|__KLIPPER_SCRIPTS__|$KLIPPER_SCRIPTS|g" \
    "$REPO_DIR/generate_resonance_graph.sh" > "$SCRIPTS_DIR/generate_resonance_graph.sh"

chmod +x "$SCRIPTS_DIR/generate_resonance_graph.sh"
echo -e "${GREEN}✓ Files installed${NC}"

# --- Add includes to printer.cfg ---
PRINTER_CFG="$CONFIG_DIR/printer.cfg"

if [ ! -f "$PRINTER_CFG" ]; then
    echo ""
    echo -e "${YELLOW}WARNING: printer.cfg not found at $PRINTER_CFG${NC}"
    echo "Please add these lines to your printer.cfg manually:"
    echo "  [include resonance_calibration_macros.cfg]"
    echo "  [include shell_commands.cfg]"
else
    echo "Updating printer.cfg..."

    add_include() {
        local line="[include $1]"
        if grep -qF "$line" "$PRINTER_CFG"; then
            echo -e "${GREEN}✓ Already included: $1${NC}"
        else
            if grep -q '^\[include' "$PRINTER_CFG"; then
                sed -i "/^\[include/a $line" "$PRINTER_CFG"
            else
                sed -i "1i $line" "$PRINTER_CFG"
            fi
            echo -e "${GREEN}✓ Added include: $1${NC}"
        fi
    }

    add_include "resonance_calibration_macros.cfg"
    add_include "shell_commands.cfg"
fi

# --- Done ---
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Installation complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Graphs will be saved to:  $OUTPUT_DIR"
echo ""
echo "Available macros:"
echo "  CALIBRATE_RESONANCE_X    - Calibrate X axis"
echo "  CALIBRATE_RESONANCE_Y    - Calibrate Y axis"
echo "  CALIBRATE_RESONANCE_BOTH - Calibrate both axes"
echo ""
echo -e "${YELLOW}Restart Klipper to apply changes:${NC}"
echo "  sudo systemctl restart klipper"
echo ""
