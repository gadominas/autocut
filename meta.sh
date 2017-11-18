#!/bin/bash
echo "File: $1"
echo "Duration: "$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 -sexagesimal $1)
echo "Frame rate: "$(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of default=noprint_wrappers=1:nokey=1 $1)
echo "Video frame dimension: "$(ffprobe -v error -of flat=s=_ -select_streams v:0 -show_entries stream=height,width $1)
echo "Codecs: "$(ffprobe -v error -show_format -show_streams $1| grep codec_name)
echo "Frames: "$(ffprobe -v error -show_format -show_streams $1 | grep nb_frames)
