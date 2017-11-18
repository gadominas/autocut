#ffmpeg -i $1 -vcodec copy -acodec copy $1.mp4
#ffmpeg -framerate 24 -i $1 -c copy output.mp4
ffmpeg -i $1 -c:v copy -f mp4 $1.mp4
