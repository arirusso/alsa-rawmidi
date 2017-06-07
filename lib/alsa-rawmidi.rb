#
# alsa-rawmidi
# ALSA Driver Interface
#
# (c) 2010-2014 Ari Russo
# Licensed under Apache 2.0
# https://github.com/arirusso/alsa-rawmidi
#

# libs
require "ffi"

# modules
require "alsa-rawmidi/api"
require "alsa-rawmidi/device"

# class
require "alsa-rawmidi/input"
require "alsa-rawmidi/output"
require "alsa-rawmidi/soundcard"

module AlsaRawMIDI

  VERSION = "0.3.1"

end
