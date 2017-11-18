#!/bin/bash
#set -eo pipefail

# enable for debuging
#set -vx

# functions
FN_REKEY="rekey"
FN_FADEINOUT="fade"
FN_SLICE="slice"
FN_ADJUSTTEMPO="tempo"
FN_CUT="cut"
FN_RECAP="recap"
FN_JOIN="join"

# commont arguments
input=undefined.mp4
ffmpegLogLevel=quiet

# rekey arguments
rekeyInterval=7

# fadeInOut arguments
fadeFrames=30

# slice arguments
sliceFromFrame=0
sliceToFrame=100

# adjustTempo arguments (tempo in %)
tempoFactor=120

# join arguments
segmentsDir="output/*.mp4"

# recap arguments
durationOfMovie=261
maxSecInFrame=21
sliceOffset=10
recapOutputDir=output

offsetArray=(
  0 #0
  0 #1
  0 #2
  0 #3
  0 #4
  0 #5
  0 #6
  0 #7
  0 #8
  0 #9
  0 #10
  0 #11
  0 #12
  0 #13
  0 #14
  0 #15
  0 #16
  0 #17
  0 #18
  0 #19
  0 #20
  0 #21
  0 #22
  0 #23
  0 #24
  0 #25
  0 #26
  0 #27
  0 #28
  0 #29
  0 #30
)

blacklist=(
  0 #0
  0 #1
  0 #2
  0 #3
  0 #4
  0 #5
  0 #6
  0 #7
  0 #8
  0 #9
  0 #10
  0 #11
  0 #12
  0 #13
  0 #14
  0 #15
  0 #16
  0 #17
  0 #18
  0 #19
  0 #20
  0 #21
  0 #22
  0 #23
  0 #24
  0 #25
  0 #26
  0 #27
  0 #28
  0 #29
  0 #30
)

# AUTO CUT API -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# slice API
function slice(){
    out="sliced_"$sliceFromFrame"_"$sliceToFrame"_"$input
    duration=$(echo "$sliceToFrame - $sliceFromFrame"|bc)

    log "Slicing from: "$sliceFromFrame
    log "Slicing to: "$sliceToFrame
    log "Slice duration: "$duration
    log "Input: $input"
    log "Output: $out"

    ffmpeg -y -loglevel $ffmpegLogLevel -i $input -ss $sliceFromFrame -t $duration  -c copy $out
    input=$out
}

# fade API
function fade(){
    out="fade_"$fadeFrames"_"$input
    outputFrames=$(ffprobe -select_streams v -show_streams $input 2>/dev/null | grep nb_frames | sed -e 's/nb_frames=//')
    log "FadeInOut frames: $fadeFrames"
    log "Input $input has $outputFrames frames in total"
    log "Input: $input"
    log "Output: $out"

    outputFrames=$(echo "$outputFrames - $fadeFrames"|bc)
    log "Fading in: [0:$fadeFrames], out: [$outputFrames:$fadeFrames]"

    ffmpeg -y -loglevel $ffmpegLogLevel -i $input -y -vf fade=in:0:$fadeFrames,fade=out:$outputFrames:$fadeFrames $out
    input=$out
}

# rekey API
function rekey(){
    out="rekeyed_"$rekeyInterval"_"$input
    log "Rekey interval: $rekeyInterval"
    log "Input: $input"
    log "Output: $out"

    ffmpeg -y -loglevel $ffmpegLogLevel -i $input -vcodec libx264 -x264-params keyint=7 -acodec copy $out
    input=$out
}

# tempo API
function tempo(){
    pts=$(echo "scale=2; 100/$tempoFactor" | bc)
    atempo=$(echo "scale=2; 1/$pts" | bc)
    out="tempo_"$tempoFactor"_"$input

    log "Requested tempo readjusment(%): $tempoFactor"
    log "Video speed: $pts"
    log "Audio speed: $atempo"
    log "Input: $input"
    log "Output: $out"

    ffmpeg -y -loglevel $ffmpegLogLevel -i $input -filter_complex "[0:v]setpts=$pts*PTS[v];[0:a]atempo=$atempo[a]" -map "[v]" -map "[a]" $out
    input=$out
}

# recap API
function recapOutputDirCheck(){
  if [ -d $recapOutputDir ]; then
    log "$recapOutputDir directory already exist."
  else
    mkdir $recapOutputDir
  fi
}

clean(){
  rm $recapOutputDir/cut*.mp4
}

function recap(){
  recapOutputDirCheck
  clean

  cutFrameStep=$(echo "scale=0; $durationOfMovie/$maxSecInFrame" | bc)
  durationFloat=$(ffprobe $input -show_format 2>&1 | sed -n 's/duration=//p')
  duration=$(echo "scale=0; $durationFloat/1" | bc)
  cutStep=$(echo "scale=0; $duration/$cutFrameStep" | bc)

  log "Input: $input"
  log "Duration of movie: $durationOfMovie"
  log "Max sec for cut: $maxSecInFrame"
  log "Offset: $sliceOffset"

  counter=$sliceOffset
  index=0

  rule "-"
  while [  $counter -lt $duration ]; do
     goodCutIndicator="GOOD"

     ssTime=$(echo "scale=0; $counter+${offsetArray[$index]}" | bc)
     ssTime=$(echo "scale=0; $ssTime/$maxSecInFrame" | bc)
     ssTime=$(echo "scale=0; $ssTime*$maxSecInFrame" | bc)
     ssTime_display=$(printf "%04d" $ssTime)

     fileIndex=$(printf "%02d" $index)
     frameFix_display=$(printf "%02d" ${offsetArray[$index]})

     cutFrameDuration=$(echo "scale=0; $maxSecInFrame" | bc)
     cutFrameDuration_display=$(printf "%02d" $cutFrameDuration)

     output=$recapOutputDir/cut_$fileIndex.mp4
     ## local props

     # skip segment in case it's blacklisted
     if [ ${blacklist[$index]} -eq 0 ]; then
       ffmpeg -y -loglevel $ffmpegLogLevel -i $input -ss $ssTime -t $cutFrameDuration  -c copy $output

       outputFileSize="$(wc -c <"$output")"
       outputFileSize=$(printf "%08d" $outputFileSize)

       if [ $outputFileSize -lt 420000 ]; then
         goodCutIndicator="BAD!"
       fi
     else
         goodCutIndicator="SKIP"
         outputFileSize=0
     fi

     log "#$fileIndex:[$goodCutIndicator] framefix: $frameFix_display cut offset: $ssTime_display cut duration: $cutFrameDuration_display output: $output output size: $outputFileSize"

     let counter+=$cutStep
     let index++
   done

   log "Removing last segment as potencial end title: $output"
   rm $output

   rule "-"
   segmentsDir=$recapOutputDir"/*.mp4"
   join
}

# join API
join(){
  output="joined_$input"
  log "Concatenating files:"
  log "Segments directory: $segmentsDir"
  log "Output: $output"

  [ -e list.txt ] && rm list.txt

  for f in $segmentsDir
  do
     echo "file $f" >> list.txt
  done

  cat list.txt
  ffmpeg -y -loglevel $ffmpegLogLevel -f concat -i list.txt -c copy $output

  rm list.txt
  input=$output
}

# INVOCATION WRAPPER API
function welcome(){
    echo " ______     __  __     ______   ______     ______     __  __     ______  "
    echo "/\  __ \   /\ \/\ \   /\__  _\ /\  __ \   /\  ___\   /\ \/\ \   /\__  _\ "
    echo "\ \  __ \  \ \ \_\ \  \/_/\ \/ \ \ \/\ \  \ \ \____  \ \ \_\ \  \/_/\ \/ "
    echo " \ \_\ \_\  \ \_____\    \ \_\  \ \_____\  \ \_____\  \ \_____\    \ \_\ "
    echo "  \/_/\/_/   \/_____/     \/_/   \/_____/   \/_____/   \/_____/     \/_/ "
    rule "="
}

function log(){
  echo "INFO[ "$1" ]"
}

function error(){
  echo "ERROR[ "$1" ]"
}

function rule(){
  eval printf %.0s$1 '{1..'"${COLUMNS:-$(tput cols)}"\}; echo
}

function usage() {
  echo "Usage: autoCut -a APPLICATION[,APPLICATION][,..] -i %file% [ -r ] [ -t ] [ -f ] [ -s ] [ -e ] [ -d ] [ -m ] [ -o ] [ -z ] [ -j ] [ -l ] "
  echo "Applications (any order):"
  printf "  $FN_REKEY %-12s-- rekey every n seconds (default $rekeyInterval sec)\n"
  printf "  $FN_ADJUSTTEMPO %-12s-- change audio & video tempo (default $tempoFactor percentage)\n"
  printf "  $FN_FADEINOUT  %-12s-- fade In&Out (default $fadeFrames frames)\n"
  printf "  $FN_SLICE %-12s-- slice video (from/to frame is set to from: $sliceFromFrame to: $sliceToFrame)\n"
  printf "  $FN_RECAP %-12s-- create recap video\n"
  printf "  $FN_JOIN  %-12s-- join video segments\n"
  echo "Options:"
  echo "  -a APPLICATION    Comma-delimited list from above in the order of execution"
  echo "  -i INPUT_FILE     Input file"
  echo "  [$FN_REKEY] arguments:"
  echo "    -r  [$FN_REKEY] Rekey interval. Example: autocut -a rekey -i input -r 5"
  echo "  [$FN_ADJUSTTEMPO] arguments:"
  echo "    -t  [$FN_ADJUSTTEMPO] Tempo reajustment factor. Example: autocut -a tempo -i input -t 50 'would slowdown video&autio to 50%'"
  echo "  [$FN_FADEINOUT] arguments:"
  echo "    -f  [$FN_FADEINOUT] Fade In/Out frame count. Example: autocut -a fade -i input -f 10 'would fade in 10 frames from the begging & 10 frames from the end'"
  echo "  [$FN_SLICE] arguments:"
  echo "    -s  [$FN_SLICE] Slice from frame. Example: autocut -a slice -i input -s 200 e 500. Slicing from 200 to 500 frames"
  echo "    -e  [$FN_SLICE] Slice to frame. Example: autocut -a slice -i input -e 2000. Where start frame would be defaulted to 0"
  echo "  [$FN_RECAP] arguments:"
  echo "    -d  [$FN_RECAP] Duration of the video (sec) (default: $durationOfMovie)"
  echo "    -m  [$FN_RECAP] Max duration per cut (sec) (default: $maxSecInFrame)"
  echo "    -o  [$FN_RECAP] Offset of the cut (sec) (default: $sliceOffset)"
  echo "    -z  [$FN_RECAP] Working directory for recap process (default: $recapOutputDir)"
  echo "  [$FN_JOIN] arguments:"
  echo "    -j  [$FN_JOIN] Join video segments (default directory/mask: $segmentsDir)"
  echo "  [ffmpeg] arguments:"
  echo "    -l  ffmpeg log level {panic,fatal,error,warning,info,verbose,debug}. Default is $ffmpegLogLevel"
  exit
}

welcome

while getopts "a:i:r:l:t:f:s:e:d:m:o:z:j:" opt; do
  case $opt in
    a)  IFS=',' read -a FUNCTIONS <<< ${OPTARG}
        ;;
    i) input=$OPTARG;;
    r) if [[ $OPTARG -ge 1 ]]; then
          rekeyInterval=$OPTARG
        else
          error "Rekey interval should be positive value"
          usage
          exit 1
        fi
        ;;
    l) ffmpegLogLevel=$OPTARG;;
    t) if [[ $OPTARG -ge 1 && $OPTARG -le 200 ]]; then
          tempoFactor=$OPTARG
        else
          error "Tempo range is [1..100]"
          usage
          exit 1
        fi
        ;;
    f) if [[ $OPTARG -ge 1 && $OPTARG -le 999 ]]; then
          fadeFrames=$OPTARG
       else
          error "Fade frames range is [1..999]"
          usage
          exit 1
          fi
        ;;
    s) if [[ $OPTARG -ge 1 ]]; then
         sliceFromFrame=$OPTARG
       else
          error "Slice from frame # should be postive"
          usage
          exit 1
          fi
        ;;
    e) if [[ $OPTARG -ge 1 ]]; then
          sliceToFrame=$OPTARG
       else
          error "Slice to frame # should be positive"
          usage
          exit 1
          fi
        ;;
    d) if [[ $OPTARG -ge 1 ]]; then
          durationOfMovie=$OPTARG
       else
          error "Duration of the movie should be positive"
          usage
          exit 1
          fi
        ;;
    m) if [[ $OPTARG -ge 1 ]]; then
          maxSecInFrame=$OPTARG
        else
          error "Max cut interval should be positive"
          usage
          exit 1
          fi
        ;;
    o) if [[ $OPTARG -ge 1 ]]; then
          sliceOffset=$OPTARG
       else
          error "Slice offset should be positive"
          usage
          exit 1
          fi
        ;;
    z) recapOutputDir=$OPTARG;;
    j) segmentsDir=$OPTARG;;
    *)  usage
        ;;
  esac
done

### If no apps specified, exit ###
[[ -n "$FUNCTIONS" ]] || usage

log "Processing pipe: { $(echo $FUNCTIONS|sed 's/ / > /g') }"

for cmd in ${FUNCTIONS[@]}; do
  rule "-"
  log "Running: $cmd"

  if [ "$cmd" == "$FN_FADEINOUT" ] ; then
    fade
  elif [ "$cmd" == "$FN_ADJUSTTEMPO" ] ; then
    tempo
  elif [ "$cmd" == "$FN_REKEY" ] ; then
    rekey
  elif [ "$cmd" == "$FN_SLICE" ] ; then
    slice
  elif [ "$cmd" == "$FN_RECAP" ] ; then
    recap
  elif [ "$cmd" == "$FN_JOIN" ] ; then
    join
  else
    usage
  fi

  log "Finished: $cmd"
done
