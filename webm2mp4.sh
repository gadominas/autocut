#!/bin/bash
outputDir=mp4output

function outputDirCheck(){
  if [ -d $outputDir ]; then
    log "$outputDir directory already exist."
  else
    mkdir $outputDir
  fi
}

convert(){
  outputDirCheck

  local inputDir="$1"

  [ -e list.txt ] && rm list.txt
  for f in $inputDir
  do
     echo "file $f" >> list.txt
     echo "Converting file: $f"
     ffmpeg -loglevel 0 -i $f -c:v copy -c:a aac $outputDir/$f.mp4
  done

  rm list.txt
}

run(){
  #clean
  convert "./*.mkv"
  #convert "./*.webm"
}

run
