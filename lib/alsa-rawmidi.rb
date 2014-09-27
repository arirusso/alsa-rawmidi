#
# Modules and classes to interact with the ALSA Driver Interface
#
# Ari Russo
# (c) 2010-2014
# Licensed under Apache 2.0
#
module AlsaRawMIDI
  
  VERSION = "0.2.15"

end

require "ffi"
 
require "alsa-rawmidi/device"
require "alsa-rawmidi/input"
require "alsa-rawmidi/map"
require "alsa-rawmidi/output"
require "alsa-rawmidi/soundcard"
