# frozen_string_literal: true

#
# alsa-rawmidi
# ALSA Driver Interface
#
# (c) 2010-2022 Ari Russo
# Licensed under Apache 2.0
# https://github.com/arirusso/alsa-rawmidi
#

# libs
require 'ffi'

# modules
require 'alsa-rawmidi/api'
require 'alsa-rawmidi/device'
require 'alsa-rawmidi/type_conversion'
require 'alsa-rawmidi/version'

# class
require 'alsa-rawmidi/input'
require 'alsa-rawmidi/output'
require 'alsa-rawmidi/soundcard'

module AlsaRawMIDI
end
