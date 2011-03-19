#!/usr/bin/env ruby
module AlsaRawMIDI
  
  #
  # Output device class for the ALSA driver interface 
  #
  class Output
    
    include Device
    
    def output_message_bytestr(data)
      data = data.dup
	  output = []
      until (str = data.slice!(0,2)).eql?("")
      	output << str.hex
      end
      output_message(output)
    end
    
    # this takes an array of bytes 
    def output_message(data)

      format = "C" * data.size
      bytes = FFI::MemoryPointer.new(data.size).put_bytes(0, data.pack(format))

      Map.snd_rawmidi_write(@handle, bytes.to_i, data.size)
      Map.snd_rawmidi_drain(@handle)
      
    end
    
    alias_method :message, :output_message
    
    def enable(options = {}, &block)
      handle_ptr = FFI::MemoryPointer.new(FFI.type_size(:int))
      Map.snd_rawmidi_open(nil, handle_ptr, @id, 0)
      @handle = handle_ptr.read_int
      @enabled = true
      unless block.nil?
      	begin
      		block.call(self)
      	ensure
      		close
      	end
      end
    end
    
  end
  
end