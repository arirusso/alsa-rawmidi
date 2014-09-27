module AlsaRawMIDI
	
  # Input device class
  class Input

    include Device

    BufferSize = 256
    
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
      loop until queued_messages?
      msgs = queued_messages
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
      handle_ptr = FFI::MemoryPointer.new(FFI.type_size(:int))
      API.snd_rawmidi_open(handle_ptr, nil, @system_id, API::Constants[:SND_RAWMIDI_NONBLOCK])
      @handle = handle_ptr.read_int
      @enabled = true
      @start_time = Time.now.to_f
      initialize_buffer
      spawn_listener!
      unless block.nil?
        begin
          yield(self)
        ensure
          close
        end
      else
        self
      end
    end
    alias_method :open, :enable
    alias_method :start, :enable

    # Close this input
    def close
      Thread.kill(@listener)
      API.snd_rawmidi_drain(@handle)
      API.snd_rawmidi_close(@handle)
      @enabled = false
    end
    
    # The first input
    def self.first
      Device.first(:input)	
    end

    # The last input
    def self.last
      Device.last(:input)	
    end
    
    # All inputs
    def self.all
      Device.all_by_type[:input]
    end

    private
    
    def initialize_buffer
      @pointer = 0
      @buffer = []
      def @buffer.clear          
        super
        @pointer = 0
      end
    end
    
    def now
      ((Time.now.to_f - @start_time) * 1000)
    end

    # give a message its timestamp and package it in a Hash
    def get_message_formatted(raw, time)
      { :data => hex_string_to_numeric_bytes(raw), :timestamp => time }
    end
    
    def queued_messages
      @buffer.slice(@pointer, @buffer.length - @pointer)
    end
    
    def queued_messages?
      @pointer < @buffer.length
    end

    # launch a background thread that collects messages
    # and holds them for the next call to gets*
    def spawn_listener!
      t = 1.0/1000   
      @listener = Thread.fork do       
        loop do
          while (raw = poll_system_buffer!).nil?
            sleep(t)
          end
          populate_local_buffer(raw) unless raw.nil?
        end
      end
    end
    
    # collect messages from the system buffer
    def populate_local_buffer(msgs)      
      @buffer << get_message_formatted(msgs, now) unless msgs.nil?
    end

    # Get the next bytes from the buffer
    def poll_system_buffer!
      buffer = FFI::MemoryPointer.new(:uint8, Input::BufferSize)
      if (err = API.snd_rawmidi_read(@handle, buffer, Input::BufferSize)) < 0
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
    def hex_string_to_numeric_bytes(str)
      str = str.dup
      bytes = []
      until str.eql?("")
        bytes << str.slice!(0, 2).hex
      end
      bytes
    end

    def numeric_bytes_to_hex_string(bytes)
      bytes.map { |b| s = b.to_s(16).upcase; b < 16 ? s = "0" + s : s; s }.join
    end
        
  end

end
