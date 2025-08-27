#!/bin/bash

# Rapidly simulate 1000 left mouse clicks using ydotool

for i in {1..1000}; do
    ydotool click 1
done
