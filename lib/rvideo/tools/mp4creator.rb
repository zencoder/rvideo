module RVideo
  module Tools
    class Mp4creator
      include AbstractTool::InstanceMethods

      attr_reader :raw_metadata

      def tool_command
        'mp4creator'
      end

      def format_fps(params={})
          " -rate=#{params[:fps]}" 
      end

      def parse_result(result)
        if m = /can't open file/.match(result)
          raise TranscoderError::InvalidFile, "I/O error"
        end
        
        if m = /unknown file type/.match(result)
          raise TranscoderError::InvalidFile, "I/O error"
        end
        
        if @options['output_file'] && !File.exist?(@options['output_file'])
          raise TranscoderError::UnexpectedResult, "An unknown error has occured with mp4creator:#{result}"
        end

        @raw_metadata = result.empty? ? "No Results" : result
        return true
      end

    end
  end
end
