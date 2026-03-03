#!/bin/bash
# generate_resonance_graph.sh [x|y]
# Paths are substituted by install.sh at install time

AXIS="${1:-x}"
AXIS_UPPER=$(echo "$AXIS" | tr '[:lower:]' '[:upper:]')

OUTPUT_DIR="__CONFIG_DIR__/resonance_graphs"
KLIPPER_SCRIPTS="__KLIPPER_SCRIPTS__"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="${OUTPUT_DIR}/resonance_${AXIS_UPPER}_${TIMESTAMP}.png"

mkdir -p "$OUTPUT_DIR"

LATEST_CSV=$(ls -t /tmp/resonances_${AXIS}_*.csv 2>/dev/null | head -1)

if [ -z "$LATEST_CSV" ]; then
    echo "ERROR: No resonance data file found for axis ${AXIS_UPPER}"
    echo "Expected files matching: /tmp/resonances_${AXIS}_*.csv"
    exit 1
fi

echo "Processing: $LATEST_CSV"
echo "Output: $OUTPUT_FILE"

"$KLIPPER_SCRIPTS/calibrate_shaper.py" "$LATEST_CSV" -o "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo "SUCCESS: Graph saved to $OUTPUT_FILE"
    cp "$OUTPUT_FILE" "${OUTPUT_DIR}/resonance_${AXIS_UPPER}_latest.png"
else
    echo "ERROR: Failed to generate graph"
    exit 1
fi
