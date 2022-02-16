# frozen_string_literal: true
require 'helper'

describe 'input buffer' do
  let(:output) { SpecHelper.device[:output].open }
  let(:input) { SpecHelper.device[:input].open }

  before do
    sleep 0.3
    input.buffer.clear
  end

  context 'Source#buffer' do
    let(:messages) { SpecHelper.numeric_messages }

    after do
      input.close
      output.close
    end

    it 'has the correct messages in the buffer' do
      bytes = []
      buffer = nil
      messages.each do |message|
        p "sending: #{message}"
        output.puts(message)
        bytes += message

        sleep 0.3

        buffer = input.buffer.map { |m| m[:data] }.flatten
        p "received: #{buffer}"
        expect(buffer).to eq(bytes)
      end
      expect(buffer.length).to eq(bytes.length)
    end
  end
end
