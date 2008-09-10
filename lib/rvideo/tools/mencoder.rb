module RVideo
  module Tools
    class Mencoder
      include AbstractTool::InstanceMethods

      attr_reader :frame, :size, :time, :bitrate, :video_size, :audio_size, :output_fps
      
      def tool_command
        'mencoder'
      end

      def format_fps(params={})
        " -ofps #{params[:fps]}" 
      end

      def format_resolution(params={})
        p = " -vf scale=#{params[:scale][:width]}:#{params[:scale][:height]}"
        if params[:letterbox]
          p += ",expand=#{params[:letterbox][:width]}:#{params[:letterbox][:height]}"
        end
        p += ",harddup"
      end

      def format_audio_channels(params={})
        " -channels #{params[:channels]}"
      end
      
      def format_audio_bit_rate(params={})
        " br=#{params[:bit_rate]}:"
      end
      
      def format_audio_sample_rate(params={})
        " -srate #{params[:sample_rate]}"
      end
      
      def format_video_quality(params={})
        bitrate = params[:video_bit_rate].blank? ? nil : params[:video_bit_rate]
        factor = (params[:scale][:width].to_f * params[:scale][:height].to_f * params[:fps].to_f)
        case params[:video_quality]
        when 'low'
          bitrate ||= (factor / 12000).to_i
          " -x264encopts threads=auto:subq=1:me=dia:frameref=1:crf=30:bitrate=#{bitrate} "
        when 'medium'
          bitrate ||= (factor / 9000).to_i
          " -x264encopts threads=auto:subq=3:me=hex:frameref=2:crf=22:bitrate=#{bitrate} "
        when 'high'
          bitrate ||= (factor / 3600).to_i
          " -x264encopts threads=auto:subq=6:me=dia:frameref=3:crf=18:bitrate=#{bitrate} "
        else
          ""
        end
      end  
      


      private
      
      def parse_result(result)
        if m = /Exiting.*No output file specified/.match(result)
          raise TranscoderError::InvalidCommand, "no command passed to mencoder, or no output file specified"
        end
        
        if m = /counldn't set specified parameters, exiting/.match(result)
          raise TranscoderError::InvalidCommand, "a combination of the recipe parameters is invalid: #{result}"
        end

        if m = /Sorry, this file format is not recognized\/supported/.match(result)
          raise TranscoderError::InvalidFile, "unknown format"
        end
        
        if m = /Cannot open file\/device./.match(result)
          raise TranscoderError::InvalidFile, "I/O error"
        end
        
        if m = /File not found:$/.match(result)
          raise TranscoderError::InvalidFile, "I/O error"
        end
        
        video_details = result.match /Video stream:(.*)$/
        if video_details
          @bitrate = sanitary_match(/Video stream:\s*([0-9.]*)/, video_details[0])
          @video_size = sanitary_match(/size:\s*(\d*)\s*(\S*)/, video_details[0])
          @time = sanitary_match(/bytes\s*([0-9.]*)/, video_details[0])
          @frame = sanitary_match(/secs\s*(\d*)/, video_details[0])
          @output_fps = (@frame.to_f / @time.to_f).round_to(3)
        elsif result =~ /Video stream is mandatory/
          raise TranscoderError::InvalidFile, "Video stream required, and no video stream found"
        end
        
        audio_details = result.match /Audio stream:(.*)$/
        if audio_details
          @audio_size = sanitary_match(/size:\s*(\d*)\s*(\S*)/, audio_details[0])
        else
          @audio_size = 0
        end
        @size = (@video_size.to_i + @audio_size.to_i).to_s
      end

      def sanitary_match(regexp, string)
        match = regexp.match(string)
        return match[1] if match
      end
      
    end
  end
end
