# frozen_string_literal: true

require 'helper'

describe 'io' do
  # ** this spec assumes that the test input is connected to the test output
  let(:output) { SpecHelper.device[:output].open }
  let(:input) { SpecHelper.device[:input].open }

  before do
    sleep 0.3
    input.buffer.clear
  end

  describe 'full IO' do
    describe 'using Arrays' do
      let(:messages) { SpecHelper.numeric_messages }
      let(:messages_as_bytes) { messages.inject(&:+).flatten }

      after do
        input.close
        output.close
      end

      it 'does IO' do
        pointer = 0
        result = messages.map do |message|
          p "sending: #{message}"

          output.puts(message)
          sleep 0.3
          received = input.gets.map { |m| m[:data] }.flatten

          p "received: #{received}"

          expect(received).to eq(messages_as_bytes.slice(pointer, received.length))
          pointer += received.length
          received
        end
        expect(result.flatten.length).to eq(messages_as_bytes.length)
      end
    end

    context 'using byte Strings' do
      let(:messages) { SpecHelper.string_messages }
      let(:messages_as_string) { messages.join }

      it 'does IO' do
        pointer = 0
        result = messages.map do |message|
          p "sending: #{message}"

          output.puts(message)
          sleep 0.3
          received = input.gets_bytestr.map { |m| m[:data] }.flatten.join
          p "received: #{received}"

          expect(received).to eq(messages_as_string.slice(pointer, received.length))
          pointer += received.length
          received
        end
        expect(result).to eq(messages)
      end
    end
  end
end
