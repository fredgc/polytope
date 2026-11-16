#!/bin/bash -i
# Used to setup work on the local machine.

if [ -z "$workspace" ]; then 
  export workspace=`sawfish-client -e current-workspace`
fi

PROJECT="polytope"
FIREBASE_PROJECT="polytope-7d78f"
TODO_URL="https://docs.google.com/document/d/19ESr9TL-pdcFNEsN7CH6jGBd29GVWtpy7y3GxRuSSrI/edit?tab=t.u9rv3q46yjb"

export FLUTTER_PORT=$(find-port.py)
echo "Using port $FLUTTER_PORT"

if [ `hostname -s` == "raven" ]; then
  echo "Starting local emacs:"
  export USE_DESKTOP=$workspace
  emacs-maybe-client -n -3 plan.md lib/main.dart
  hot-key-start -w $workspace 5 urxvt -geometry 100x84-0+25 -e agy
else
  echo "Starting remote tmux:"
  export REMOTE=personal
  ssh-remote start-tmux-in-dir published/$PROJECT $PROJECT
  ~/setup/setup-ssh-jeeves.sh --no-remember $PROJECT
fi

echo "export FLUTTER_PORT=$FLUTTER_PORT" > .env
echo "alias fix_port=\"adb reverse tcp:$FLUTTER_PORT tcp:$FLUTTER_PORT\"" >> .env

chrome-hot-key -n personal -w $workspace -g 1200x1000+0+50 9 "http://localhost:$FLUTTER_PORT"

chrome-hot-key -n personal -w $workspace -g 980x1010-1+30 0 \
  "https://console.firebase.google.com/u/0/project/$FIREBASE_PROJECT/overview"

chrome-hot-key -n personal -w $workspace -g 950x1000+100+30 t \
  "$TODO_URL"
