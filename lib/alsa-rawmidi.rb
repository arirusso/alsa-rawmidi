#!/usr/bin/env ruby

#
# Set of modules and classes for interacting with the ALSA Driver Interface
#
module AlsaRawMIDI
    VERSION = "0.1"
end

require 'ffi'
 
require 'alsa-rawmidi/core_extensions'
require 'alsa-rawmidi/device'
require 'alsa-rawmidi/input'
require 'alsa-rawmidi/map'
require 'alsa-rawmidi/output'
require 'alsa-rawmidi/soundcard'