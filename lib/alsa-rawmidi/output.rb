module AlsaRawMIDI
  
  # Output device class
  class Output
    
    include Device
    
    # Close this output
    def close
      API.snd_rawmidi_drain(@handle)
      API.snd_rawmidi_close(@handle)
      @enabled = false
    end
    
    # Send a MIDI message in hex string format
    def puts_s(data)
      data = data.dup
	    output = []
      until (str = data.slice!(0,2)) == ""
      	output << str.hex
      end
      puts_bytes(*output)
    end
    alias_method :puts_bytestr, :puts_s
    alias_method :puts_hex, :puts_s

    # Send a MIDI message in numeric byte format
    def puts_bytes(*data)

      format = "C" * data.size
      bytes = FFI::MemoryPointer.new(data.size).put_bytes(0, data.pack(format))

      API.snd_rawmidi_write(@handle, bytes.to_i, data.size)
      API.snd_rawmidi_drain(@handle)
      
    end
    
    # Send a MIDI message of an indeterminate type
    def puts(*a)
  	  case a.first
        when Array then puts_bytes(*a.first)
    	  when Numeric then puts_bytes(*a)
    	  when String then puts_s(*a)
      end
    end
    alias_method :write, :puts
    
    # Enable this device; also takes a block
    def enable(options = {}, &block)
      handle_ptr = FFI::MemoryPointer.new(FFI.type_size(:int))
      API.snd_rawmidi_open(nil, handle_ptr, @system_id, 0)
      @handle = handle_ptr.read_int
      @enabled = true
      if block_given?
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
    
    # The first output
    def self.first
      Device.first(:output)	
    end

    # The last output
    def self.last
      Device.last(:output)	
    end
    
    # All outputs
    def self.all
      Device.all_by_type[:output]
    end
  end
  
end
