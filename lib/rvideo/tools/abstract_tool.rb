module RVideo # :nodoc:
  module Tools # :nodoc:
    class AbstractTool
      
      #
      # AbstractTool is an interface to every transcoder tool class (e.g. 
      # ffmpeg, flvtool2). Called by the Transcoder class.
      #
      
      def self.assign(cmd, options = {})
        tool_name = cmd.split(" ").first
        begin
          tool = "RVideo::Tools::#{tool_name.classify}".constantize.send(:new, cmd, options)
        # rescue NameError, /uninitialized constant/
          # raise TranscoderError::UnknownTool, "The recipe tried to use the '#{tool_name}' tool, which does not exist."
        rescue => e
          LOGGER.info $!
          LOGGER.info e.backtrace.join("\n")
        end
      end
      
      
      module InstanceMethods
        attr_reader :options, :command, :raw_result
        attr_writer :original
        
        def initialize(raw_command, options = {})
          @raw_command = raw_command
          @options = HashWithIndifferentAccess.new(options)
          @command = interpolate_variables(raw_command)
        end

        #
        # Execute the command and parse the result.
        #
        # def execute
        #   @output_params = {}
        #   final_command = "#{@command} 2>&1"
        #   Transcoder.logger.info("\nExecuting Command: #{final_command}\n")
        #   @raw_result = `#{final_command}`
        #   Transcoder.logger.info("Result: \n#{@raw_result}")
        #   parse_result(@raw_result)
        # end

        def execute
          @output_params = {}
          
          # Dump the log output into a temp file
          log_temp_file_name = "/tmp/transcode_output_#{Time.now.to_i}.txt"
        
          final_command = "#{@command} 2>#{log_temp_file_name}"
          Transcoder.logger.info("\nExecuting Command: #{final_command}\n")
          `#{final_command}`
          
          populate_raw_result(log_temp_file_name)
          
          Transcoder.logger.info("Result: \n#{@raw_result}")
          parse_result(@raw_result)
          
          # Cleanup log file
          begin
            File.delete(log_temp_file_name)
          rescue Exception  => e
            Transcoder.logger.error("Failed to delete output log file: #{log_temp_file_name}, e=#{e}")
          end
        end
        
        #
        # Magic parameters
        #
        def temp_dir
          if @options['output_file']
            "#{File.dirname(@options['output_file'])}/"
          else
            ""
          end
        end
        
        
        def fps
          format_fps(get_fps)
        end
        
        def get_fps
          inspect_original if @original.nil?
          fps = @options['fps'] || ""
          case fps
          when "copy"
            get_original_fps
          else
            get_specific_fps
          end
        end
        
        
        def resolution
          format_resolution(get_resolution)
        end
        
        def get_resolution
          inspect_original if @original.nil?
          resolution_setting = @options['resolution'] || ""
          case resolution_setting
          when "copy"
            get_original_resolution
          when "width"
            get_fit_to_width_resolution
          when "height"
            get_fit_to_height_resolution
          when "letterbox"
            get_letterbox_resolution
          else
            get_specific_resolution
          end
        end
        
        
        def audio_channels
          format_audio_channels(get_audio_channels)
        end

        def get_audio_channels
          channels = @options['audio_channels'] || ""
          case channels
          when "stereo"
            get_stereo_audio
          when "mono"
            get_mono_audio
          else
            {}
          end
        end  
        
        def audio_bit_rate
          format_audio_bit_rate(get_audio_bit_rate)
        end
        
        def get_audio_bit_rate
          bit_rate = @options['audio_bit_rate'] || ""
          case bit_rate
          when ""
            {}
          else
            get_specific_audio_bit_rate
          end
        end
        
        def audio_sample_rate
          format_audio_sample_rate(get_audio_sample_rate)
        end
        
        def get_audio_sample_rate
          sample_rate = @options['audio_sample_rate'] || ""
          case sample_rate
          when ""
            {}
          else
            get_specific_audio_sample_rate
          end
        end
        
        def video_quality
          format_video_quality(get_video_quality)
        end
        
        def get_video_quality
          inspect_original if @original.nil?
          quality = @options['video_quality'] || 'medium'
          video_bit_rate = @options['video_bit_rate'] || nil
          h = {:video_quality => quality, :video_bit_rate => video_bit_rate}
          h.merge!(get_fps).merge!(get_resolution)
        end
        
        
        
        def get_fit_to_width_resolution
          w = @options['width']
          raise TranscoderError::ParameterError, "invalid width of '#{w}' for fit to width" unless valid_dimension?(w)
          h = calculate_height(@original.width, @original.height, w)
          {:scale => {:width => w, :height => h}}
        end
        
        def get_fit_to_height_resolution
          h = @options['height']
          raise TranscoderError::ParameterError, "invalid height of '#{h}' for fit to height" unless valid_dimension?(h)
          w = calculate_width(@original.width, @original.height, h)
          {:scale => {:width => w, :height => h}}
        end
        
        def get_letterbox_resolution
          lw = @options['width'].to_i
          lh = @options['height'].to_i
          raise TranscoderError::ParameterError, "invalid width of '#{lw}' for letterbox" unless valid_dimension?(lw)
          raise TranscoderError::ParameterError, "invalid height of '#{lh}' for letterbox" unless valid_dimension?(lh)
          w = calculate_width(@original.width, @original.height, lh)
          h = calculate_height(@original.width, @original.height, lw)
          if w > lw
            w = lw
            h = calculate_height(@original.width, @original.height, lw)
          else
            h = lh
            w = calculate_width(@original.width, @original.height, lh)
          end
          {:scale => {:width => w, :height => h}, :letterbox => {:width => lw, :height => lh}}
        end
        
        def get_original_resolution
          {:scale => {:width => @original.width, :height => @original.height}}
        end

        def get_specific_resolution
          w = @options['width']
          h = @options['height']
          raise TranscoderError::ParameterError, "invalid width of '#{w}' for specific resolution" unless valid_dimension?(w)
          raise TranscoderError::ParameterError, "invalid height of '#{h}' for specific resolution" unless valid_dimension?(h)
          {:scale => {:width => w, :height => h}}
        end
        
        def get_original_fps
          return {} if @original.fps.nil?
          {:fps => @original.fps}
        end
        
        def get_specific_fps
          {:fps => @options['fps']}
        end
        
        # def get_video_quality
        #   fps = @options['fps'] || @original.fps
        #   raise TranscoderError::ParameterError, "could not find fps in order to determine video quality" if fps.nil?
        #   width = @original.width
        #   height = @
        #   format_video_quality({:quality => @options['video_quality'], :bit_rate => @options['video_bit_rate']})
        # end
        
        def get_stereo_audio
          {:channels => "2"}
        end
        
        def get_mono_audio
          {:channels => "1"}
        end
        
        def get_specific_audio_bit_rate
          {:bit_rate => @options['audio_bit_rate']}
        end
        
        def get_specific_audio_sample_rate
          {:sample_rate => @options['audio_sample_rate']}
        end
        
        def calculate_width(ow, oh, h)
          w = ((ow.to_f / oh.to_f) * h.to_f).to_i
          (w.to_f / 16).round * 16
        end

        def calculate_height(ow, oh, w)
          h = (w.to_f / (ow.to_f / oh.to_f)).to_i
          (h.to_f / 16).round * 16
        end
          

        def valid_dimension?(dim)
          return false if dim.to_i <= 0
          return true
        end
        
        def format_resolution(params={})
          raise ParameterError, "The #{self.class} tool has not implemented the format_resolution method."
        end

        def format_fps(params={})
          raise ParameterError, "The #{self.class} tool has not implemented the format_fps method."
        end

        def format_audio_channels(params={})
          raise ParameterError, "The #{self.class} tool has not implemented the format_audio_channels method."
        end

        def format_audio_bit_rate(params={})
          raise ParameterError, "The #{self.class} tool has not implemented the format_audio_bit_rate method."
        end

        def format_audio_sample_rate(params={})
          raise ParameterError, "The #{self.class} tool has not implemented the format_audio_sample_rate method."
        end

        private
        
        
        #
        # Look for variables surrounded by $, and interpolate with either 
        # variables passed in the options hash, or special methods provided by
        # the tool class (e.g. "$original_fps$" with ffmpeg).
        #
        # $foo$ should match
        # \$foo or $foo\$ or \$foo\$ should not

        def interpolate_variables(raw_command)
          raw_command.scan(/[^\\]\$[-_a-zA-Z]+\$/).each do |match|
            match = match[0..0] == "$" ? match : match[1..(match.size - 1)]
            match.strip!
            raw_command.gsub!(match, matched_variable(match))
          end
          raw_command.gsub("\\$", "$")
        end
        
        #
        # Strip the $s. First, look for a supplied option that matches the
        # variable name. If one is not found, look for a method that matches.
        # If not found, raise ParameterError exception.
        # 
        
        def matched_variable(match)
          variable_name = match.gsub("$","")
          if self.respond_to? variable_name
            self.send(variable_name)
          elsif @options.key?(variable_name) 
            @options[variable_name] || ""
          else
            raise TranscoderError::ParameterError, "command is looking for the #{variable_name} parameter, but it was not provided. (Command: #{@raw_command})"
          end
        end
        
        def inspect_original
          @original = Inspector.new(:file => options[:input_file])
        end
        
        # Pulls the interesting bits of the temp log file into memory.  This is fairly tool-specific, so
        # it's doubtful that this default version is going to work without being overridded.
        def populate_raw_result(temp_file_name)
          @raw_result = `tail -n 500 #{temp_file_name}`
        end
        
      end
    
    end
  end
end
