---
layout: post
title: "YTD v5.0, finally..."
date: 2016-09-18 12:35:13 +0200
comments: true
categories: [News]
sharing: true
footer: true
description: "YouTube Downloader for Android - a free and ad-free app - new version"
keywords: "YouTube Downloader, Android, android app, app, free, ad-free, no ads, dentex, XDA, XDA_dentex, twidentex, YouTube, downloader, FFmpeg, audio, music, video, extraction, mp3, easy, dentex, 1080p, 720p, 480p, HD, 4K, 3gp, webm, mp4, m4a, ogg, flv, opus, 360°, 3D"
---
Today I'm finally pushing out version 5.0 for YouTube Downloader.
This version has been tested for long time as a beta (thanks guys @XDA!), always adding new features and resolving bugs, but as with every "major" version bump, when out in the public, something may be still subject to some refining (or worse, fixing). 

Moreover, please not that unfortunately some "known issues" remain; check the release notes on http://dentex.github.io/apps/youtubedownloader/ for further info.

**Changelog:**

     v5.0 - Sep 18 2016
    -----------------------------------
    [x] multi-threaded downloads
    [x] redundant "clear Dashboard" button in action bar
    [x] fix some app's crashes in Android N
    [x] better preview thumbnail in Formats tab
    [x] fix for the "shared?ci=" link type
    [x] fix for the progress bar during FFmpeg operations
    [x] use correct file extension for opus formats
    [x] support for ogg 4.0 ch. and m4a 5.1 ch. new audio-only formats
    [x] do not block age-restricted videos anymore 
        (please note: only some of them will be available for download)
    [x] better Search tab's results sorting dialog
    [x] prevent app's log from becoming too big 


The most notable feature of this build is the **multi-threaded download** mode: it enables a file downloaded from YouTube to be split in more than on part (from 1 to 5; default 3) being downloaded simultaneously.    
This should maximize the bandwidth available from your network connection and minimize YouTube's speed throttling: it's well known that, especially for some low-specs formats, download speed tends to go down after some seconds of download. This is an intended behavior from the server, because allows some buffer and then proceeds with an acceptable speed, according to the quality and length of the media in download.

Another front of development has been patching the app to be ready for **Android N**. It's possible that there's still something to do (i.e., one thing to fix is probably the import function from the dashboard: it's possible that the system dialog shows only the Android data folder... some feedback is needed, from who of you already have an N device).

Other changes are related to the **UI**, as a new "clear Dashboard" button in action bar (while the Dashboard itself is the active tab), or the new Search tab's results sorting dialog (one of the next feature will be using this type of dialog to order entries in the Dashboard: by download date, by state, by size, etc).

Please refer to the *changelog* above for a list containing all changes to this version.
