# Klipper Resonance Calibration

One-click resonance calibration macros for Klipper. Runs the test and saves a PNG graph directly to your config folder, viewable from Mainsail/Fluidd.

## Requirements

- ADXL345 (or compatible) accelerometer configured in Klipper
- `gcode_shell_command` plugin *(installer will attempt to auto-install this)*

## Install

SSH into your printer and run:

```bash
cd ~ && git clone https://github.com/Kanrog/klipper-resonance-calibration.git && bash ~/klipper-resonance-calibration/install.sh
```

Then restart Klipper:

```bash
sudo systemctl restart klipper
```

## Usage

```
CALIBRATE_RESONANCE_X       # Calibrate X axis
CALIBRATE_RESONANCE_Y       # Calibrate Y axis
CALIBRATE_RESONANCE_BOTH    # Calibrate both axes
```

Graphs are saved to `printer_data/config/resonance_graphs/` and visible in the Mainsail/Fluidd file browser.

## Update

```bash
cd ~/klipper-resonance-calibration && git pull && bash install.sh
```
