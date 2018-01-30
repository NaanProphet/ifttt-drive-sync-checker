#!/bin/bash

# Uses a combination of Mountain Duck and PhantomJSCloud to check if
# files are synchronized between a Google Drive and Amazon Cloud Drive
# folder. Triggers an IFTTT event if the two do not match (which could 
# e.g. send an email notification).

# Tested on a MacBook Air running 10.12.6 Sierra

IFTTT_TRIGGER=thu_class_publish_reminder
#IFTTT_API_KEY <-- define as environment variable for security
#PHANTOMJSCLOUD_API_KEY <-- define as environment variable for security

# after mounting the Google drive with Mountain Duck, use `df` to find the path
GOOGLE_DRIVE_BOOKMARK_NAME="" # <-- Mountain Duck bookmark name
MOUNTAIN_DUCK_MOUNT_LOCATION="$HOME/Library/Group Containers/G69SCX94XU.duck/Library/Application Support/duck/Volumes"
GOOGLE_DRIVE_LOC="$MOUNTAIN_DUCK_MOUNT_LOCATION/$GOOGLE_DRIVE_BOOKMARK_NAME"
AMAZON_CLOUD_DRIVE_URL="" # <-- specify public URL to Amazon share folder
AUDIO_EXTENSION=m4a
WAIT_TIMEOUT=20

echo "Google drive location is: $GOOGLE_DRIVE_LOC"

# Use Mountain Duck to mount Google Drive folder
open /Applications/Mountain\ Duck.app/

while [ "$SECONDS" -lt $WAIT_TIMEOUT ]
do
if [ ! -d "$GOOGLE_DRIVE_LOC" ]; then
  echo "Waiting for folder(s) to be mounted..." 
  sleep 2
else
  break # while
fi
done

if [ ! -d "$GOOGLE_DRIVE_LOC" ]; then
  echo "ERROR could not find Mountain Duck folder ${GOOGLE_DRIVE_LOC}"
  exit 1
fi

# *.m4a concatenation tricky, so grepping them out instead
_num_files_published=`ls -1 "$GOOGLE_DRIVE_LOC" | sort | uniq | grep "$AUDIO_EXTENSION" | wc -l | xargs`

echo "$_num_files_published files found published in Google Drive"

# note {} and "" need to be escaped to run from command line curl
# second line contains total folder count
_num_files_staged=$(curl -s "https://PhantomJsCloud.com/api/browser/v2/${PHANTOMJSCLOUD_API_KEY}/?request=\{url:%22${AMAZON_CLOUD_DRIVE_URL}%22,renderType:%22plainText%22,renderType:\"plainText\"\}" | sed -n 2p)
echo "$_num_files_staged files found staged in Amazon Cloud Drive"

# just in case we want to cancel
sleep 4

if [ $_num_files_published -ne $_num_files_staged ]; then
  echo "Preparing reminder trigger..."

  values=()
  values+=('"value1":"'$_num_files_staged'"')
  values+=(',')
  values+=('"value2":"'$_num_files_published'"')

  curl -X POST \
       --header 'Content-Type:application/json' \
       --data '{'"${values[*]}"'}' \
    "https://maker.ifttt.com/trigger/${IFTTT_TRIGGER}/with/key/${IFTTT_API_KEY}"
  printf "\n"
fi

echo "Goodbye!"


## special thanks to:
# https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable
# https://stackoverflow.com/questions/1429556/shell-bash-command-to-get-nth-line-of-stdout
# https://phantomjscloud.com
# https://gist.github.com/HokieGeek/b7fd3dbe011a47df9f8f09dee43044ea
# https://unix.stackexchange.com/questions/102286/ls-gives-no-such-file-or-directory-message
# https://serverfault.com/questions/417252/check-if-directory-exists-using-home-character-in-bash-fails