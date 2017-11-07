#!/bin/bash


# youtube video downloader (youtube-dl) wrapper script
#  It downloads the version of the file marked "best" quality as an mp4 file where underscores replace special characters
#
#
# TODO
#  add comments to functions
#  complete promiseMp4
#  fail checks for download
#
# NOTE:
#  Install instructions for the alternate ffmpeg downloader are in:
#   ffmpeg-install-guide.sh   
#  which is drawn from:
#   trac.ffmpeg.org/wiki/CompilationGuide/Centos
#  Install, Config, Command Line Options & much else see REF[1]
#  "hung process"
#   google.com/search?q=strace+"hung+process"
#   Troubleshooting a hung process on Linux and Solaris operating system using strace or truss
#    kb.juniper.net/InfoCenter/index?page=content&id=KB11254
#    more on this (similar articles) in OneNote
#  previously downloaded marker: [see promiseMp4()]
#   [download] ‘Let Me Go Very, Very Dark on You’ - Michael Hayden Speculates About Trump Wiretapping Claims-7Sf3a1e0RLI.mp4 has already been downloaded
#  complete marker:
#   [download] 100% of 69.24MiB
#
#
# SEE ALSO:
#  "a tool to download videos from edx online university" at
#   github.com/shk3/edx-downloader (a tool to download videos from edx online university)
#
#
# REF:
#  [1] github.com/rg3/youtube-dl/blob/master/README.md
#  [2] manpages.ubuntu.com/manpages/yakkety/man1/youtube-dl.1.html



arg=${1}
dlMsg=''
filename=''
format=43
progName=$(basename $0 .sh)
videoID=${1}
#videoID=7Sf3a1e0RLI



#
#
#
function showHelp() {
 echo $progName is a wrapper for youtube video downloader \(youtube-dl\)
 echo It downloads the version of the file marked "best" quality as an mp4 file where underscores replace special characters
}


#
#
#
function showUsage() {
 echo usage: $progName videoid
 echo $progName -h or $progName --help for help
}


#
#
#
function download() {
 # Options used:
 #  --get-filename
 #   Simulate, quiet but print output filename
 #  -F, --list-formats
 #   List all available formats of requested videos
 #  -- newline
 #   Output progress bar as new lines
 #  --restrict-filenames
 #   Restrict filenames to only ASCII characters, and avoid "&" and spaces in filenames
 #   e.g. #Let_Me_Go_Very_Very_Dark_on_You_-_Michael_Hayden_Speculates_About_Trump_Wiretapping_Claims-7Sf3a1e0RLI.mp4
 #
 # completion test ideas:
 #  all ytdl: google.com/search?q=linux+get+process+id
 #  pgrep
 #  non-zero exit is fail
 #  download - look for 100% in dlMsg

 echo getting the format
 # add completion test (return code should be 0)
 # report error/exit on error
 local tmp=$(youtube-dl -F http://youtube.com/watch?v=${videoID})
 format=$(echo "$tmp" | grep \(best\) | cut -c1-3)
 echo $format

 echo getting the filename
 # add completion test (return code should be 0)
 # report error/exit on error
 # this returned *.webm but the *.mp4 format was downloaded
 filename=$(youtube-dl --get-filename --restrict-filenames http://youtube.com/watch?v=${videoID})
 filename=$(basename "$filename")
 # get filename without extension
 filename="${filename%.*}" 
 echo $filename

 echo downloading [$filename]
 # add completion test (return code should be 0), output should contain 100% on last line
 # report error/exit on error
 dlMsg=$(youtube-dl --restrict-filenames --newline -f${format} http://youtube.com/watch?v=${videoID})
}


#
#
#
promiseMp4() {
 # if extension is not mp4
 # run ffmpeg -i filename.ext filename.mp4
 # if both mp4 and non-mp4 copies exist remove non-mp4 copy
 #
 # have a look at "previously downloaded marker" when writing this function
 echo "filename: "$filename
}


#
#
#
function main() {
 if [[ "$arg" == '-h' || "$arg" == '--help' ]]; then
  showHelp
 elif [ -n "$videoID" ]; then
  download
  promiseMp4
 else
  showUsage
 fi
}



# ###############
main

