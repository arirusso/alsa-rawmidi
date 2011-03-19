module TestHelper::Config
  		
  	include AlsaRawMIDI
  	
	# adjust these constants according to suit your hardware configuration 
  	# before running these tests
  	NumDevices = 4
  	TestInput = Device.first(:input)
  	TestOutput = Device.first(:output)
  		
end