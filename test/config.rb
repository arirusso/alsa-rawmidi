#!/usr/bin/env ruby

module TestHelper::Config

  include AlsaRawMIDI

  # adjust these constants to suit your hardware configuration
  # before running tests

  NumDevices = 4 # this is the total number of MIDI devices that are connected to your system
  TestInput = Input.first # this is the device you wish to use to test input
  TestOutput = Output.first # likewise for output

end