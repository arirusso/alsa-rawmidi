# frozen_string_literal: true

module AlsaRawMIDI
  # Helper for converting MIDI data
  module TypeConversion
    module_function

    # Convert a hex string to an array of numeric bytes eg "904040" -> [0x90, 0x40, 0x40]
    # @param [String] string
    # @return [Array<Integer>]
    def hex_string_to_numeric_bytes(string)
      string = string.dup
      bytes = []
      until string.length.zero?
        string_byte = string.slice!(0, 2)
        bytes << string_byte.hex
      end
      bytes
    end

    # Convert an array of numeric bytes to a hex string eg [0x90, 0x40, 0x40] -> "904040"
    # @param [Array<Integer>] bytes
    # @return [String]
    def numeric_bytes_to_hex_string(bytes)
      string_bytes = bytes.map do |byte|
        string_byte = byte.to_s(16).upcase
        string_byte = "0#{string_byte}" if byte < 16
        string_byte
      end
      string_bytes.join
    end
  end
end
