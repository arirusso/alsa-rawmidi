#!/usr/bin/env ruby
#
# Input device class for the ALSA driver interface 
#
require 'json'

module AlsaRawMIDI
  
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
    def read_buffer
      @wr.close
      output = []
      msgs = JSON.parse(@rd.read)
      @rd.close
      Process.wait
      start_collector
      msgs.each { |msg| msg.symbolize_keys! }
      msgs
    end
    
    alias_method :read, :read_buffer
    
    # enable this the input device for use, can be passed a block
    def enable(options = {}, &block)
      handle_ptr = FFI::MemoryPointer.new(FFI.type_size(:int))
      Map.snd_rawmidi_open(handle_ptr, nil, @id, Map::Constants[:SND_RAWMIDI_NONBLOCK]) # 
      @handle = handle_ptr.read_int
      @enabled = true
      @start_time = Time.now.to_f        
      start_collector
      unless block.nil?
      	begin
      		block.call(self)
      	ensure
      		close
      	end
      end
    end
    
    # close the device and kill the message collector process
    def close
      Process.kill(9, @p2) # kill collector process
      Map.snd_rawmidi_drain(@handle)
      Map.snd_rawmidi_close(@handle)
    end
    
    private
    
    def get_message_formatted(raw)
    	time = ((Time.now.to_f - @start_time) * 1000).to_i # same time format as winmm
      	{ :data => raw, :timestamp => time }
    end
    
    # launch a background process that collects messages
    def start_collector
      @rd, @wr = IO.pipe
      @p2 = Process.fork do
      	buffer = []
      	while (raw = get_buffer).eql?("") do
      		sleep(0.1) 
      	end
      	buffer << get_message_formatted(raw)
      	@rd.close
      	@wr.write(buffer.to_json)
      	@wr.close
      end
    end
        
    # gets the next bytes from the buffer
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