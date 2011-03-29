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
  s.summary     = "Realtime MIDI input and output with Ruby for Linux."
  s.description = "Realtime MIDI input and output with Ruby for Linux."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "alsa-rawmidi"

  s.add_dependency "ffi", ">= 1.0"

  s.files        = Dir.glob("{lib}/**/*") + %w(LICENSE README.rdoc)
  s.require_path = 'lib'
end