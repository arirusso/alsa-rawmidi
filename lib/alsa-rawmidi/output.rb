#!/usr/bin/env ruby

module AlsaRawMIDI
  
  #
  # Output device class for the ALSA driver interface 
  #
  class Output
    
    include Device
    
    # this takes a String of hex digits 
    def puts_bytestr(data)
      data = data.dup
	  output = []
      until (str = data.slice!(0,2)).eql?("")
      	output << str.hex
      end
      puts_bytes(*output)
    end

    # sends a message consisting of Numeric bytes 
    def puts_bytes(*data)

      format = "C" * data.size
      bytes = FFI::MemoryPointer.new(data.size).put_bytes(0, data.pack(format))

      Map.snd_rawmidi_write(@handle, bytes.to_i, data.size)
      Map.snd_rawmidi_drain(@handle)
      
    end
    
    # send a message of an indeterminant type
    def puts(*a)
  	  case a.first
        when Array then puts_bytes(*a.first)
    	when Numeric then puts_bytes(*a)
    	when String then puts_bytestr(*a)
      end
    end
    alias_method :write, :puts
    
    # enable this device, also takes a block
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
    alias_method :open, :enable
    alias_method :start, :enable

    def self.first
      Device.first(:output)	
    end

    def self.last
      Device.last(:output)	
    end
    
    def self.all
      Device.all_by_type[:output]
    end
    
  end
  
end