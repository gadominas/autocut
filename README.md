```
 ______     __  __     ______   ______     ______     __  __     ______
/\  __ \   /\ \/\ \   /\__  _\ /\  __ \   /\  ___\   /\ \/\ \   /\__  _\
\ \  __ \  \ \ \_\ \  \/_/\ \/ \ \ \/\ \  \ \ \____  \ \ \_\ \  \/_/\ \/
 \ \_\ \_\  \ \_____\    \ \_\  \ \_____\  \ \_____\  \ \_____\    \ \_\
  \/_/\/_/   \/_____/     \/_/   \/_____/   \/_____/   \/_____/     \/_/
=======================================================================================================================================================================
Usage: autoCut -f FUNCTION[,FUNCTION][,..] -i %file% [ -r ] [ -t ] [ -f ] [ -s ] [ -e ] [ -d ] [ -m ] [ -o ] [ -z ] [ -j ] [ -l ]
Functions (any order):
  rekey             -- rekey every n seconds (default 7 sec)
  tempo             -- change audio & video tempo (default 120 percentage)
  fade              -- fade In&Out (default 30 frames)
  slice             -- slice video (from/to frame is set to from: 0 to: 100)
  recap             -- create recap video
  join              -- join video segments
  mkv2mp4           -- convert mkv to mp4
_______________________________________________________________________________________________________________________________________________________________________
Options:
  -f FUNCTION       Comma-delimited list from above in the order of execution
  -i INPUT_FILE     Input file
  [rekey] arguments:
        -r  [rekey] Rekey interval. Example: autocut -a rekey -i input -r 5
  [tempo] arguments:
        -t  [tempo] Tempo reajustment factor. Example: autocut -a tempo -i input -t 50 'would slowdown video&autio to 50%'
  [fade] arguments:
        -h  [fade] Fade In/Out frame count. Example: autocut -a fade -i input -f 10 'would fade in 10 frames from the begging & 10 frames from the end'
  [slice] arguments:
        -s  [slice] Slice from frame. Example: autocut -a slice -i input -s 200 e 500. Slicing from 200 to 500 frames
        -e  [slice] Slice to frame. Example: autocut -a slice -i input -e 2000. Where start frame would be defaulted to 0
  [recap] arguments:
        -d  [recap] Duration of the video (sec) (default: 261)
        -m  [recap] Max duration per cut (sec) (default: 21)
        -o  [recap] Offset of the cut (sec) (default: 10)
        -z  [recap] Working directory for recap process (default: output)
  [join] arguments:
        -j  [join] Join video segments (default directory/mask: output/*.mp4)
  [ffmpeg] arguments:
        -l  ffmpeg log level {panic,fatal,error,warning,info,verbose,debug}. Default is quiet

```

In case you want to convert mkv to mp4, cut small fragment, accelerate video&audio by 20% and apply fadeIn and fadeOut filters that can be converted to onne-liner cli cmd:
```
autocut -f mkv2mp4,slice,tempo,fade -i input_video_file.mkv -s 0 -e 200 - t 120
```

As result input video will be converted, small fragment of 200 frames starting from the begging will be sliced and accelerated by 20% applying fadeIn/Out filters.

Recap function basically was the main purpose of such ffmpeg cli. Recap function takes video input file cuts fragments equally distributing the cut time and then joins them together.
It's important to rekey video according to your fragment duration in order to have clean cut on keyframe. For example:
```
autocut -f mkv2mp4,recap -i input_video_file.mkv -d 120 -m 10 -0 10
```

As a result recap video will be made out of input file. Duration of result video is 2 minutes (120sec) composing of small fragments of 10 seconds. Offset can be applied in order to skip titles or etc.
Like whole Silicon Valley Season4 was sliced using such approach: https://www.youtube.com/watch?v=pfg-uCFGF3w&list=PLnbD0OU7iJ_-24yY169dowgYQZ294HX7m

I hope this helps someone who needs simple and flexible ffmpeg cli.
Enjoy!
