module RVideo
  module Tools
    class Ffmpeg2theora
      include AbstractTool::InstanceMethods

      attr_reader :raw_metadata

      def tool_command
        'ffmpeg2theora'
      end

      def format_video_quality(params={})
        bitrate = params[:video_bit_rate].blank? ? nil : params[:video_bit_rate]
        factor = (params[:scale][:width].to_f * params[:scale][:height].to_f * params[:fps].to_f)
        case params[:video_quality]
        when 'low'
          " -v 1 "
        when 'medium'
          "-v 5 "
        when 'high'
          "-v 10 "
        else
          ""
        end
      end  

      def parse_result(result)
        if m = /does not exist or has an unknown data format/.match(result)
          raise TranscoderError::InvalidFile, "I/O error"
        end
        
        if m = /General output options/.match(result)
          raise TranscoderError::InvalidCommand, "no command passed to ffmpeg2theora, or no output file specified"
        end
        
        @raw_metadata = result.empty? ? "No Results" : result
        return true
      end

    end
  end
end
