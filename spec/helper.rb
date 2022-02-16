# frozen_string_literal: true

dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift "#{dir}/../lib"

require 'rspec'
require 'alsa-rawmidi'

module SpecHelper
  module_function

  def bytestrs_to_ints(arr)
    data = arr.map { |m| m[:data] }.join
    output = []
    until (bytestr = data.slice!(0, 2)).eql?('')
      output << bytestr.hex
    end
    output
  end

  # some MIDI messages
  def numeric_messages
    [
      [0x90, 100, 100], # NOTE: on
      [0x90, 43, 100], # NOTE: on
      [0x90, 76, 100], # NOTE: on
      [0x90, 60, 100], # NOTE: on
      [0x80, 100, 100], # NOTE: off
      [0xF0, 0x41, 0x10, 0x42, 0x12, 0x40, 0x00, 0x7F, 0x00, 0x41, 0xF7] # SysEx
    ]
  end

  # some MIDI messages
  def string_messages
    [
      '906440', # NOTE: on
      '804340', # NOTE: off
      'F04110421240007F0041F7' # SysEx
    ]
  end

  def device
    @device ||= select_devices
  end

  def select_devices
    @device ||= {}
    { input: AlsaRawMIDI::Input.all, output: AlsaRawMIDI::Output.all }.each do |type, devs|
      puts ''
      puts "select an #{type}..."
      while @device[type].nil?
        devs.each do |device|
          puts "#{device.id}: #{device.name}"
        end
        selection = $stdin.gets.chomp
        next unless selection != ''

        selection = selection.to_i
        @device[type] = devs.find { |d| d.id == selection }
        puts "selected #{selection} for #{type}" unless @device[type]
      end
    end
    @device
  end
end
