= RVideo

== DESCRIPTION:

RVideo allows you to inspect and process video files.

== INSTALL:

Installation is a little involved. First, install the gem:

  sudo gem install rvideo
  
Next, install ffmpeg and (possibly) other related libraries. This is
documented elsewhere on the web, and can be a headache. If you are on OS X,
the Darwinports build is reasonably good (though not perfect). Install with:

  sudo port install ffmpeg

Or, for a better build (recommended), add additional video- and audio-related
libraries, like this:

  sudo port install ffmpeg +lame +libogg +vorbis +faac +faad +xvid +x264 +a52
  
Most package management systems include a build of ffmpeg, but many include a
poor build. So you may need to compile from scratch.

If you want to create Flash Video files, also install flvtool2:

  sudo gem install flvtool2

Once ffmpeg and RVideo are installed, you're set. 

== SYNOPSIS:

To inspect a file, initialize an RVideo file inspector object. See the 
documentation for details.

A few examples:

  file = RVideo::Inspector.new(:file => "#{APP_ROOT}/files/input.mp4")
  
  file = RVideo::Inspector.new(:raw_response => @existing_response)
  
  file = RVideo::Inspector.new(:file => "#{APP_ROOT}/files/input.mp4",
                                :ffmpeg_binary => "#{APP_ROOT}/bin/ffmpeg")

  file.fps        # "29.97"
  file.duration   # "00:05:23.4"

To transcode a video, initialize a Transcoder object.

  transcoder = RVideo::Transcoder.new

Then pass a command and valid options to the execute method

  recipe = "ffmpeg -i $input_file$ -ar 22050 -ab 64 -f flv -r 29.97 -s"
  recipe += " $resolution$ -y $output_file$"
  recipe += "\nflvtool2 -U $output_file$"
  begin
    transcoder.execute(recipe, {:input_file => "/path/to/input.mp4",
      :output_file => "/path/to/output.flv", :resolution => "640x360"})
  rescue TranscoderError => e
    puts "Unable to transcode file: #{e.class} - #{e.message}"
  end

If the job succeeds, you can access the metadata of the input and output
files with:

  transcoder.original     # RVideo::Inspector object
  transcoder.processed    # RVideo::Inspector object

If the transcoding succeeds, the file may still have problems. RVideo
will populate an errors array if the duration of the processed video
differs from the duration of the original video, or if the processed
file is unreadable.

== FEATURES/PROBLEMS:

== REQUIREMENTS:

Thanks to Peter Boling for early work on RVideo.

Contribute to RVideo! If you want to help out, there are a few things you can 
do.

- Use, test, and submit bugs/patches
- We need a RVideo::Tools::Mencoder class to add mencoder support.
- Other tool classes would be great - On2, mp4box, Quicktime (?), etc.
- Submit other fixes, features, optimizations, and refactorings

If RVideo is useful to you, you may also be interested in RMovie, another Ruby
video library. See http://rmovie.rubyforge.org/ for more.

Finally, watch for Zencoder, a commercial video transcoder built by Slantwise 
Design. Zencoder uses RVideo for its video processing, but adds file queuing,  
distributed transcoding, a web-based transcoder dashboard, and more. See 
http://zencoder.tv or http://slantwisedesign.com for more.

Copyright (c) 2007 Jonathan Dahl and Slantwise Design. Released under the MIT 
license.