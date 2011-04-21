#!/usr/bin/env ruby

dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift dir + '/../lib'

require 'alsa-rawmidi'
require 'pp'

pp AlsaRawMIDI::Device.all_by_type