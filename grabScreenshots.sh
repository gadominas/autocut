#!/bin/bash
echo "Removing previous screenshots"
rm screenshot_*.jpg

echo "Grabbing screenshots from: $1, fps: 1/60"
ffmpeg -i $1 -vf fps=1/60 screenshot_%03d.jpg
