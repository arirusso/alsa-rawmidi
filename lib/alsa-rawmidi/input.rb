#!/usr/bin/env ruby

module AlsaRawMIDI
	
  #
  # Input device class
  #
  class Input

    include Device

    BufferSize = 2048
    
    #
    # returns an array of MIDI event hashes as such:
    # [
    #   { :data => [144, 60, 100], :timestamp => 1024 },
    #   { :data => [128, 60, 100], :timestamp => 1100 },
    #   { :data => [144, 40, 120], :timestamp => 1200 }
    # ]
    #
    # the data is an array of Numeric bytes
    # the timestamp is the number of millis since this input was enabled
    #
    def gets
      msgs = gets_bytestr
      msgs.each { |msg| msg[:data] = message_to_hex(msg[:data]) } 
      msgs	
    end
    alias_method :read, :gets
    
    # same as gets but returns message data as String of hex digits
    def gets_bytestr
      @listener.join
      msgs = @buffer.dup
      @buffer.clear
      spawn_listener
      msgs
    end

    # enable this the input for use; can be passed a block
    def enable(options = {}, &block)
      handle_ptr = FFI::MemoryPointer.new(FFI.type_size(:int))
      Map.snd_rawmidi_open(handle_ptr, nil, @id, Map::Constants[:SND_RAWMIDI_NONBLOCK])
      @handle = handle_ptr.read_int
      @enabled = true
      @start_time = Time.now.to_f
      @buffer = []
      spawn_listener
      unless block.nil?
        begin
          block.call(self)
        ensure
          close
        end
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

	# give a message its timestamp and package it in a Hash
    def get_message_formatted(raw)
      time = ((Time.now.to_f - @start_time) * 1000).to_i # same time format as winmm
      { :data => raw, :timestamp => time }
    end

    # launch a background thread that collects messages
    def spawn_listener
      @listener = Thread.fork do
        while (raw = get_buffer).nil? do
          sleep(0.1)
        end
        @buffer << get_message_formatted(raw)
      end
    end

    # Get the next bytes from the buffer
    def get_buffer
      buffer = FFI::MemoryPointer.new(:char, Input::BufferSize)
      if (err = Map.snd_rawmidi_read(@handle, buffer, Input::BufferSize)) < 0
        raise "Can't read MIDI input: #{Map.snd_strerror(err)}" unless err.eql?(-11)
      end
      rawstr = buffer.get_bytes(0,Input::BufferSize)
      str = rawstr.unpack("A*").first.unpack("H*").first.upcase 
      str.eql?("") ? nil : str
    end
    
    private
    
    # convert byte str to byte array 
    def message_to_hex(m)
      s = []
      until m.eql?("")
	    s << m.slice!(0, 2).hex
      end
      s
    end
    
  end

end