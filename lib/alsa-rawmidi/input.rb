#!/usr/bin/env ruby

module AlsaRawMIDI
	
  #
  # Input device class
  #
  class Input

    include Device

    BufferSize = 256
    
    attr_reader :buffer
        
    #
    # returns an array of MIDI event hashes as such:
    #   [
    #     { :data => [144, 60, 100], :timestamp => 1024 },
    #     { :data => [128, 60, 100], :timestamp => 1100 },
    #     { :data => [144, 40, 120], :timestamp => 1200 }
    #   ]
    #
    # the data is an array of Numeric bytes
    # the timestamp is the number of millis since this input was enabled
    #
    def gets
      @report = true
      @listener.join
      @report = false
      msgs = @buffer.slice(@pointer, @buffer.length - @pointer)
      @pointer = @buffer.length
      spawn_listener
      msgs
    end
    alias_method :read, :gets
    
    #def buffer
    #  @buffer
    #end
    
    # same as gets but returns message data as string of hex digits as such:
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

    # enable this the input for use; can be passed a block
    def enable(options = {}, &block)
      handle_ptr = FFI::MemoryPointer.new(FFI.type_size(:int))
      Map.snd_rawmidi_open(handle_ptr, nil, @id, Map::Constants[:SND_RAWMIDI_NONBLOCK])
      @handle = handle_ptr.read_int
      @enabled = true
      @report = false
      @start_time = Time.now.to_f
      initialize_buffer
      spawn_listener
      unless block.nil?
        begin
          block.call(self)
        ensure
          close
        end
      else
        self
      end
    end
    alias_method :open, :enable
    alias_method :start, :enable

    # close this input
    def close
      Thread.kill(@listener)
      Map.snd_rawmidi_drain(@handle)
      Map.snd_rawmidi_close(@handle)
      @enabled = false
    end
    
    def self.first
      Device.first(:input)	
    end

    def self.last
      Device.last(:input)	
    end
    
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
      ((Time.now.to_f - @start_time) * 1000).to_i # same time format as winmm
    end

    # give a message its timestamp and package it in a Hash
    def get_message_formatted(raw, time)
      { :data => hex_string_to_numeric_bytes(raw), :timestamp => time }
    end

    # launch a background thread that collects messages
    # and holds them for the next call to gets*
    def spawn_listener
      @listener = Thread.fork do
        while !@report
          while (raw = poll_system_buffer).nil? && !@report
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
    def poll_system_buffer
      b = FFI::MemoryPointer.new(:uint8, Input::BufferSize)
      if (err = Map.snd_rawmidi_read(@handle, b, Input::BufferSize)) < 0
        raise "Can't read MIDI input: #{Map.snd_strerror(err)}" unless err.eql?(-11)
      end
      rawstr = b.get_bytes(0,Input::BufferSize)
      str = rawstr.unpack("A*").first.unpack("H*").first.upcase 
      str.nil? || str.eql?("") ? nil : str
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