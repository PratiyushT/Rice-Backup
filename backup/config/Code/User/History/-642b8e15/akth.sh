#!/usr/bin/env bash

# Usage: set-conservation-mode.sh [0|1]
# This script must be run via pkexec

echo "$1" > /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
