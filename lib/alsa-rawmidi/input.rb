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
    #   { :data => "904040", :timestamp => 1024 },
    #   { :data => "804040", :timestamp => 1100 },
    #   { :data => "90607F", :timestamp => 1200 }
    # ]
    #
    # the data is strings of hex digits
    # the timestamp is the number of millis since this input was enabled
    #
    def gets
      @listener.join
      msgs = @buffer.dup
      @buffer.clear
      spawn_listener
      msgs
    end
    alias_method :read, :gets

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
        while (raw = get_buffer).eql?("") do
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
      rawstr.eql?("") ? rawstr : rawstr.unpack("A*").first.unpack("H*").first.upcase
    end
    
  end

end