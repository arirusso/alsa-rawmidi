dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift dir + '/../lib'

require 'test/unit'
require 'alsa-rawmidi'

module TestHelper
	    
    def bytestrs_to_ints(arr)
		data = arr.map { |m| m[:data] }.join
    	output = []
    	until (bytestr = data.slice!(0,2)).eql?("")
    	  output << bytestr.hex
       	end
       	output    	
    end
    
    VariousMIDIMessages = [
      [0xF0, 0x41, 0x10, 0x42, 0x12, 0x40, 0x00, 0x7F, 0x00, 0x41, 0xF7], # SysEx message
      [0x90, 100, 100],
      [0x90, 43, 100],
      [0x90, 76, 100],
      [0x90, 60, 100],
      [0x90, 45, 100]
    ]
    
    VariousMIDIByteStrMessages = [
      "F04110421240007F0041F7", # SysEx message
      "906440",
      "904340"
    ]
    
end

require File.dirname(__FILE__) + '/config'