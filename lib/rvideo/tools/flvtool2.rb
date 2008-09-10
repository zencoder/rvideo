# Warning:  If you're dealing with large files, you should consider using yamdi instead.
module RVideo
  module Tools
    class Flvtool2
      include AbstractTool::InstanceMethods
      
      attr_reader :raw_metadata
      
      #attr_reader :has_key_frames, :cue_points, :audiodatarate, :has_video, :stereo, :can_seek_to_end, :framerate, :audiosamplerate, :videocodecid, :datasize, :lasttimestamp,
      #  :audiosamplesize, :audiosize, :has_audio, :audiodelay, :videosize, :metadatadate, :metadatacreator, :lastkeyframetimestamp, :height, :filesize, :has_metadata, :audiocodecid,
      #  :duration, :videodatarate, :has_cue_points, :width
      
      def tool_command
        'flvtool2'
      end
      
      private
      
      def parse_result(result)
        if result.empty?
          return true
        end
        
        if m = /ERROR: No such file or directory(.*)\n/.match(result)
          raise TranscoderError::InputFileNotFound, m[0]
        end
        
        if m = /ERROR: IO is not a FLV stream/.match(result)
          raise TranscoderError::InvalidFile, "input must be a valid FLV file"
        end
          
        if m = /Copyright.*Norman Timmler/i.match(result)
          raise TranscoderError::InvalidCommand, "command printed flvtool2 help text (and presumably didn't execute)"
        end
        
        if m = /ERROR: undefined method .?timestamp.? for nil/.match(result)
          raise TranscoderError::InvalidFile, "Output file was empty (presumably)"
        end
        
        if m = /\A---(.*)...\Z/m.match(result)
          @raw_metadata = m[0]
          return true
        end

        raise TranscoderError::UnexpectedResult, result
      end
      
    end
  end
end
