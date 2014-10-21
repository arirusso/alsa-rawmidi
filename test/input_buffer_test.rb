require "helper"

class AlsaRawMIDI::InputBufferTest < Test::Unit::TestCase

  context "AlsaRawMIDI" do

    setup do
      @input = TestHelper.input.open
      @output = TestHelper.output.open
      @input.buffer.clear
      @pointer = 0
    end

    teardown do
      @input.close
      @output.close
    end

    context "Source#buffer" do

      setup do
        @messages = TestHelper.numeric_messages
        @messages_arr = @messages.inject(&:+).flatten
        @received_arr = []
      end

      should "have the correct messages in the buffer" do
        bytes = []
        @messages.each do |message|
          p "sending: #{message}"
          @output.puts(message)
          bytes += message

          sleep(1)

          buffer = @input.buffer.map { |m| m[:data] }.flatten
          p "received: #{buffer.to_s}"
          assert_equal(bytes, buffer)
        end
        assert_equal(bytes.length, @input.buffer.map { |m| m[:data] }.flatten.length)
      end

    end
  end
end
