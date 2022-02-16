#!/usr/bin/env ruby
# frozen_string_literal: true

dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift "#{dir}/../lib"

# Lists all of the available MIDI devices

require 'alsa-rawmidi'
require 'pp'

pp AlsaRawMIDI::Device.all_by_type
