# frozen_string_literal: true

module AlsaRawMIDI
  # Input device class
  class Input
    include Device

    attr_reader :buffer

    #
    # An array of MIDI event hashes as such:
    # [
    #   { :data => [144, 60, 100], :timestamp => 1024 },
    #   { :data => [128, 60, 100], :timestamp => 1100 },
    #   { :data => [144, 40, 120], :timestamp => 1200 }
    # ]
    #
    # The data is an array of numeric bytes
    # The timestamp is the number of millis since this input was enabled
    #
    # @return [Array<Hash>]
    def gets
      loop until enqueued_messages?
      msgs = enqueued_messages
      @pointer = @buffer.length
      msgs
    end
    alias read gets

    # Like Input#gets but returns message data as string of hex digits as such:
    #   [
    #     { :data => "904060", :timestamp => 904 },
    #     { :data => "804060", :timestamp => 1150 },
    #     { :data => "90447F", :timestamp => 1300 }
    #   ]
    #
    # @return [Array<Hash>]
    def gets_s
      msgs = gets
      msgs.each { |m| m[:data] = TypeConversion.numeric_bytes_to_hex_string(m[:data]) }
      msgs
    end
    alias gets_bytestr gets_s
    alias gets_hex gets_s

    # Enable this the input for use; yields
    # @param [Hash] options
    # @param [Proc] block
    # @return [Input] self
    def enable(_options = {})
      unless @enabled
        @start_time = Time.now.to_f
        @resource = API::Input.open(@system_id)
        @enabled = true
        initialize_buffer
        spawn_listener
      end
      if block_given?
        begin
          yield(self)
        ensure
          close
        end
      end
      self
    end
    alias open enable
    alias start enable

    # Close this input
    # @return [Boolean]
    def close
      if @enabled
        Thread.kill(@listener)
        API::Device.close(@resource)
        @enabled = false
        true
      else
        false
      end
    end

    # The first input available
    # @return [Input]
    def self.first
      Device.first(:input)
    end

    # The last input available
    # @return [Input]
    def self.last
      Device.last(:input)
    end

    # All available inputs
    # @return [Array<Input>]
    def self.all
      Device.all_by_type[:input]
    end

    private

    # Initialize the input buffer
    # @return [Array]
    def initialize_buffer
      @pointer = 0
      @buffer = []
      def @buffer.clear
        super
        @pointer = 0
      end
      @buffer
    end

    # A timestamp for the current time
    # @return [Float]
    def now
      time = Time.now.to_f - @start_time
      time * 1000
    end

    # A message paired with timestamp
    # @param [String] hexstring
    # @param [Float] timestamp
    # @return [Hash]
    def get_message_formatted(hexstring, timestamp)
      {
        data: TypeConversion.hex_string_to_numeric_bytes(hexstring),
        timestamp: timestamp
      }
    end

    # The messages enqueued in the buffer
    # @return [Array<Hash>]
    def enqueued_messages
      @buffer.slice(@pointer, @buffer.length - @pointer)
    end

    # Are there messages enqueued?
    # @return [Boolean]
    def enqueued_messages?
      @pointer < @buffer.length
    end

    # Launch a background thread that collects messages
    # and holds them for the next call to gets*
    # @return [Thread]
    def spawn_listener
      interval = 1.0 / 1000
      @listener = Thread.new do
        begin
          loop do
            while (messages = API::Input.poll(@resource)).nil?
              sleep(interval)
            end
            populate_buffer(messages) unless messages.nil?
          end
        rescue Exception => e
          Thread.main.raise(e)
        end
      end
      @listener.abort_on_exception = true
      @listener
    end

    # Collect messages from the system buffer
    # @return [Array<String>, nil]
    def populate_buffer(messages)
      @buffer << get_message_formatted(messages, now) unless messages.nil?
    end
  end
end
