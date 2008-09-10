module RVideo
  module Tools
    class Mplayer
      include AbstractTool::InstanceMethods

      attr_reader :raw_metadata

      def tool_command
        'mplayer'
      end

      def parse_result(result)
        if m = /This will likely crash/.match(result)
          raise TranscoderError::InvalidFile, "unknown format"
        end
        
        if m = /Failed to open/.match(result)
          raise TranscoderError::InvalidFile, "I/O error"
        end
        
        if m = /File not found/.match(result)
          raise TranscoderError::InvalidFile, "I/O error"
        end
        
        @raw_metadata = result.empty? ? "No Results" : result
        return true
      end

    end
  end
end
