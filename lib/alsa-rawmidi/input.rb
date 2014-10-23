module AlsaRawMIDI

	# Input device class
	class Input

		include Device

		BUFFER_SIZE = 256

		attr_reader :buffer

		#
		# An array of MIDI event hashes as such:
		#   [
		#     { :data => [144, 60, 100], :timestamp => 1024 },
		#     { :data => [128, 60, 100], :timestamp => 1100 },
		#     { :data => [144, 40, 120], :timestamp => 1200 }
		#   ]
		#
		# The MIDI data is an array of Numeric bytes.
		# The timestamp represents the number of millis since this input was enabled
		#
		def gets
			loop until enqueued_messages?
			msgs = enqueued_messages
			@pointer = @buffer.length
			msgs
		end
		alias_method :read, :gets

		# Like Input#gets but returns message data as string of hex digits as such:
		#   [
		#     { :data => "904060", :timestamp => 904 },
		#     { :data => "804060", :timestamp => 1150 },
		#     { :data => "90447F", :timestamp => 1300 }
		#   ]
		#
		def gets_s
			msgs = gets
			msgs.each { |m| m[:data] = numeric_bytes_to_hex_string(m[:data]) }
			msgs
		end
		alias_method :gets_bytestr, :gets_s
		alias_method :gets_hex, :gets_s

		# Enable this the input for use; can be passed a block
		def enable(options = {}, &block)
			unless @enabled
				@start_time = Time.now.to_f
				handle_ptr = FFI::MemoryPointer.new(FFI.type_size(:int))
				API.snd_rawmidi_open(handle_ptr, nil, @system_id, API::CONSTANTS[:SND_RAWMIDI_NONBLOCK])
				@handle = handle_ptr.read_int
				@enabled = true
				initialize_buffer
				spawn_listener
			end
			if block_given?
				begin
					yield(self)
				ensure
					close
				end
			end
			self
		end
		alias_method :open, :enable
		alias_method :start, :enable

		# Close this input
		# @return [Boolean]
		def close
			if @enabled
			  Thread.kill(@listener)
			  API.snd_rawmidi_drain(@handle)
			  API.snd_rawmidi_close(@handle)
			  @enabled = false
		  end
		end

		# The first input available
		# @return [Input]
		def self.first
			Device.first(:input)
		end

		# The last input available
		# @return [Input]
		def self.last
			Device.last(:input)
		end

		# All available inputs
		# @return [Array<Input>]
		def self.all
			Device.all_by_type[:input]
		end

		private

		# Initialize the input buffer
		# @return [Array]
		def initialize_buffer
			@pointer = 0
			@buffer = []
			def @buffer.clear
				super
				@pointer = 0
			end
			@buffer
		end

		# A timestamp for the current time
		# @return [Float]
		def now
			time = Time.now.to_f - @start_time
			time * 1000
		end

		# A message paired with timestamp
		# @param [String] hexstring
		# @param [Float] timestamp
		# @return [Hash]
		def get_message_formatted(hexstring, timestamp)
			{
				:data => hex_string_to_numeric_bytes(hexstring),
				:timestamp => timestamp
			}
		end

		# The messages enqueued in the buffer
		# @return [Array<Hash>]
		def enqueued_messages
			@buffer.slice(@pointer, @buffer.length - @pointer)
		end

		# Are there messages enqueued?
		# @return [Boolean]
		def enqueued_messages?
			@pointer < @buffer.length
		end

		# Launch a background thread that collects messages
		# and holds them for the next call to gets*
		# @return [Thread]
		def spawn_listener
			interval = 1.0/1000
			@listener = Thread.new do
				begin
					loop do
						while (messages = poll_system_buffer).nil?
							sleep(interval)
						end
						populate_local_buffer(messages) unless messages.nil?
					end
				rescue Exception => exception
					Thread.main.raise(exception)
				end
			end
			@listener.abort_on_exception = true
			@listener
		end

		# Collect messages from the system buffer
		def populate_local_buffer(messages)
			@buffer << get_message_formatted(messages, now) unless messages.nil?
		end

		# Get the next bytes from the buffer
		def poll_system_buffer
			buffer = FFI::MemoryPointer.new(:uint8, BUFFER_SIZE)
			if (err = API.snd_rawmidi_read(@handle, buffer, BUFFER_SIZE)) < 0
				raise "Can't read MIDI input: #{API.snd_strerror(err)}" unless err.eql?(-11)
			end
			# Upon success, err is positive and equal to the number of bytes read
			# into the buffer.
			if err > 0
				bytes = buffer.get_bytes(0,err).unpack("a*").first.unpack("H*")
				bytes.first.upcase
			end
		end

		# convert byte str to byte array
		def hex_string_to_numeric_bytes(string)
			string = string.dup
			bytes = []
			until string.length.zero?
				string_byte = string.slice!(0, 2)
				bytes << string_byte.hex
			end
			bytes
		end

		def numeric_bytes_to_hex_string(bytes)
			string_bytes = bytes.map do |byte|
				string_byte = byte.to_s(16).upcase
				string_byte = "0#{string_byte}" if byte < 16
				string_byte
			end
			string_bytes.join
		end

	end

end
