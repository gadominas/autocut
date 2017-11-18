#!/bin/bash
#https://github.com/tokland/youtube-upload
## config part
durationOfMovie=307
maxSecInFrame=21
sliceOffset=$2

##
outputDir=output
input=$1
outputFile=$input"_joined.mp4"
outputFileFadeInOut=$input"_final.mp4"

#effects
fadeInFrames=30
fadeOutFrames=50

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

cutFrameStep=$(echo "scale=0; $durationOfMovie/$maxSecInFrame" | bc)
durationFloat=$(ffprobe $input -show_format 2>&1 | sed -n 's/duration=//p')
duration=$(echo "scale=0; $durationFloat/1" | bc)
cutStep=$(echo "scale=0; $duration/$cutFrameStep" | bc)

function outputDirCheck(){
  if [ -d $outputDir ]; then
    log "$outputDir directory already exist."
  else
    mkdir $outputDir
  fi
}

function log(){
  echo "INFO[ "$1" ]"
}

function error(){
  echo "ERROR[ "$1" ]"
}

function rule(){
  rulec "-"
}

function rulec(){
  eval printf %.0s$1 '{1..'"${COLUMNS:-$(tput cols)}"\}; echo
}

clean(){
  rm $outputDir/cut*.mp4
  rm $outputFile
  rm $outputFileFadeInOut
}

slice(){
  #set -vx
    counter=$sliceOffset
    index=0

    while [  $counter -lt $duration ]; do
      ## local props
      goodCutIndicator="GOOD"

      ssTime=$(echo "scale=0; $counter+${offsetArray[$index]}" | bc)
      ssTime=$(echo "scale=0; $ssTime/$maxSecInFrame" | bc)
      ssTime=$(echo "scale=0; $ssTime*$maxSecInFrame" | bc)
      ssTime_display=$(printf "%04d" $ssTime)

      fileIndex=$(printf "%02d" $index)
      frameFix_display=$(printf "%02d" ${offsetArray[$index]})

      cutFrameDuration=$(echo "scale=0; $maxSecInFrame" | bc)
      cutFrameDuration_display=$(printf "%02d" $cutFrameDuration)

      output=$outputDir/cut_$fileIndex.mp4
      ## local props

      # skip segment in case it's blacklisted
      if [ ${blacklist[$index]} -eq 0 ]; then
        ffmpeg -loglevel 3 -i $input -ss $ssTime -t $cutFrameDuration  -c copy $output

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

    rulec
    log "Removing last segment as potencial end title: $output"
    rm $output

    rulec
  #set +vx
}

join(){
  rulec
  log "Concatenating files:"
  [ -e list.txt ] && rm list.txt

  for f in $outputDir/*.mp4
  do
     echo "file $f" >> list.txt
  done

  cat list.txt
  ffmpeg -loglevel 0 -f concat -i list.txt -c copy $outputFile

  rm list.txt
}

fadeInOut(){
  rulec
  outputFrames=$(ffprobe -select_streams v -show_streams $outputFile 2>/dev/null | grep nb_frames | sed -e 's/nb_frames=//')
  log "Fading in/out"
  log "Output $outputFile has $outputFrames frames in total"

  outputFrames=$(echo "$outputFrames - $fadeOutFrames"|bc)
  log "Fading in: [0:$fadeInFrames], out: [$outputFrames:$fadeOutFrames]"

  ffmpeg -loglevel 3 -i $outputFile -y -vf fade=in:0:$fadeInFrames,fade=out:$outputFrames:$fadeOutFrames $outputFileFadeInOut
}

run() {
  log "Input file: "$input
  log "Input duration (sec): $duration"
  log "Duration of cut movie: $durationOfMovie"
  log "Frame size (sec): $maxSecInFrame"
  log "Frame size (frames): $cutFrameStep"
  log "Cut step (): $cutStep"

  rulec

  clean
  outputDirCheck
  slice
  join

  log "Output duration: "$(ffprobe $outputFileFadeInOut -show_format 2>&1 | sed -n 's/duration=//p')
}

run
exit 0
