#!/bin/bash

# Rapidly simulate 1000 left mouse clicks using ydotool

for i in {1..5}; do
ydotool key 42:1 42:0
sleep 2
done
