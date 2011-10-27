#!/bin/bash

# compress the recorded kinect data - encode video, delete original raw files

datestamp=`date +"%Y.%m.%d.%H%M%S"`

zip -9 -r "$datestamp"rec.zip ./rec/*
# rm -rf ./rec/
