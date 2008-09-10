module RVideo
  module Tools
    class Yamdi
      include AbstractTool::InstanceMethods
      
      attr_reader :raw_metadata
      
      def tool_command
        'yamdi'
      end
      
      private
      
      def parse_result(result)
        if result.empty?
          return true
        end
        
        if m = /Couldn't stat on (.*)/.match(result)
          raise TranscoderError::InputFileNotFound, m[0]
        end
        
        if m = /The input file is not a FLV./.match(result)
          raise TranscoderError::InvalidFile, "input must be a valid FLV file"
        end
          
        if m = /\(c\) \d{4} Ingo Oppermann/i.match(result)
          raise TranscoderError::InvalidCommand, "command printed yamdi help text (and presumably didn't execute)"
        end
        
        if m = /Please provide at least one output file/i.match(result)
          raise TranscoderError::InvalidCommand, "command did not contain a valid output file. Yamdi expects a -o switch."
        end
        
        if m = /ERROR: undefined method .?timestamp.? for nil/.match(result)
          raise TranscoderError::InvalidFile, "Output file was empty (presumably)"
        end

        raise TranscoderError::UnexpectedResult, result
      end
      
    end
  end
end
