#!/bin/bash -i
#
# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if [ -z "$workspace" ]; then 
  export workspace=`sawfish-client -e current-workspace`
fi

if [ `hostname -s` == "raven" ]; then
  #  export FLUTTER_PORT=$(find-port.py)
  # This needs to be registered w/the cloud api console? So we hard code a port.
  export FLUTTER_PORT=5525
  echo "Using port $FLUTTER_PORT"
  echo "Starting local emacs:"
  export USE_DESKTOP=$workspace
  echo "Working on $workspace"
  emacs-maybe-client -n -3 notes.txt README.md lib/main.dart
  hot-key-start -w $workspace 5 urxvt -geometry 100x28+80-40 -e agy
else
  # This needs to be registered w/the cloud api console?
  export FLUTTER_PORT=5010
  echo "Using port $FLUTTER_PORT"
  echo "Starting remote tmux:"
  export REMOTE=personal
  ssh-remote start-tmux-in-dir published/polytope polytope
  ~/setup/setup-ssh-jeeves.sh --no-remember polytope
fi

echo "export FLUTTER_PORT=$FLUTTER_PORT" > .env
echo "alias fix_port=\"adb reverse tcp:$FLUTTER_PORT tcp:$FLUTTER_PORT\"" >> .env

chrome-hot-key -n personal -w $workspace -g 1200x1000+0+50 9 "http://localhost:$FLUTTER_PORT"

chrome-hot-key -n personal -w $workspace -g 980x1010-1+30 0 \
  "https://console.firebase.google.com/u/0/project/polytope-7d78f/overview"

chrome-hot-key -n personal -w $workspace -g 950x1000+100+30 t \
  "https://docs.google.com/document/d/19ESr9TL-pdcFNEsN7CH6jGBd29GVWtpy7y3GxRuSSrI/edit?tab=t.u9rv3q46yjb"
