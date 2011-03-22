#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test_helper'

class IoTest < Test::Unit::TestCase
  
  include AlsaRawMIDI
  include TestHelper
  include TestHelper::Config # before running these tests, adjust the constants in config.rb to suit your hardware setup
  
  # ** this test assumes that TestOutput is connected to TestInput
  def test_full_io
  	
    messages = VariousMIDIMessages

  	input = TestInput
    output = TestOutput
    
    input.enable 
    output.enable
    
    begin
    	   
    	messages.each do |msg| 
    		
    		$>.puts "sending: " + msg.inspect
    		
    		output.output_message(msg)
    		
    		received = input.read_buffer
    		received_ints = bytestrs_to_ints(received)
    		$>.puts "received: " + received_ints.inspect
    			
			assert_equal(msg, received_ints)
    	end
	ensure
		input.close
		output.close
	end
   
  end
  
  # ** this test assumes that TestOutput is connected to TestInput
  def test_full_io_bytestr
  	sleep(1) # pause between tests
  	
    messages = VariousMIDIByteStrMessages

  	input = TestInput
    output = TestOutput
    
    input.enable 
    output.enable
    
    begin
    	   
    	messages.each do |msg| 
    		
    		$>.puts "sending: " + msg.inspect
    		
    		output.output_message_bytestr(msg)
    		
    		received = input.read_buffer
    		$>.puts "received: " + received.inspect
    			
			assert_equal(msg, received.first[:data])
    	end
    	
	ensure
		input.close
		output.close
	end
		      
  end
  
end