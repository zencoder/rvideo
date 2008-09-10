module RVideo
  module Tools
    class Mp4box
      include AbstractTool::InstanceMethods
      attr_reader :raw_metadata

      def tool_command
        'MP4Box'
      end
      
      private
      
      def parse_result(result)
        #currently, no useful info returned in result to determine if successful or not
        @raw_metadata = result.empty? ? "No Results" : result
        return true
      end
      
    end
  end
end
