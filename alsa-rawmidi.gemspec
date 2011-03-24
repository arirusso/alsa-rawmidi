# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift 'lib'

require 'alsa-rawmidi'

Gem::Specification.new do |s|
  s.name        = "alsa-rawmidi"
  s.version     = AlsaRawMIDI::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ari Russo"]
  s.email       = ["ari.russo@gmail.com"]
  s.homepage    = "http://github.com/arirusso/alsa-rawmidi"
  s.summary     = "Interact with the ALSA RawMIDI API in Ruby"
  s.description = "A Ruby library for performing low level, realtime MIDI input and output in Linux.  Uses the ALSA RawMIDI driver interface API"

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "alsa-rawmidi"

  s.add_dependency "ffi", ">= 1.0"

  s.files        = Dir.glob("{lib}/**/*") + %w(LICENSE README.org)
  s.require_path = 'lib'
end