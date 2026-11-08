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

export FLUTTER_PORT=$(find-port.py)
echo "Using port $FLUTTER_PORT"

echo "export FLUTTER_PORT=$FLUTTER_PORT" > .env
echo "alias fix_port=\"adb reverse tcp:$FLUTTER_PORT tcp:$FLUTTER_PORT\"" >> .env

export USE_DESKTOP=$workspace
emacs-maybe-client -n -3 notes.txt README.md lib/main.dart

hot-key-start -w $workspace 5 urxvt -geometry 100x28+80-40 -e agy

chrome-hot-key -n personal -w $workspace -g 1700x1000+0+100 9 "http://localhost:$FLUTTER_PORT/#/"
# chrome-hot-key -w $workspace -g +0+26 5 "https://flutter.dev/docs/get-started/codelab"

chrome-hot-key -n personal -w $workspace -g +0+26 t "https://docs.google.com/document/d/19ESr9TL-pdcFNEsN7CH6jGBd29GVWtpy7y3GxRuSSrI/edit#heading=h.7656sd2s1k9z"

chrome-hot-key -n personal -w $workspace -g 980x1010+1500+26 0 "https://console.firebase.google.com/u/0/project/polytope-7d78f/overview"

chrome-hot-key -n personal -w $workspace -g 950x1000+100+30 t \
  "https://docs.google.com/document/d/19ESr9TL-pdcFNEsN7CH6jGBd29GVWtpy7y3GxRuSSrI/edit?tab=t.u9rv3q46yjb"
