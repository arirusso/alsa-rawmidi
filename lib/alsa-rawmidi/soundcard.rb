# frozen_string_literal: true

module AlsaRawMIDI
  class Soundcard
    attr_reader :id, :subdevices

    # @param [Integer] id
    def initialize(id)
      @subdevices = {
        input: [],
        output: []
      }
      @id = id
      populate_subdevices
    end

    # Find a soundcard by its ID
    # @param [Integer] id
    # @return [Soundcard]
    def self.find(id)
      @soundcards ||= {}
      @soundcards[id] ||= Soundcard.new(id) if API::Soundcard.exists?(id)
    end

    private

    # @return [Hash]
    def populate_subdevices
      device_ids = API::Soundcard.get_device_ids(@id)
      device_ids.each do |device_id|
        @subdevices.each_key do |direction|
          devices = API::Soundcard.get_subdevices(direction, @id, device_id) do |device_hash|
            new_device(direction, device_hash)
          end
          @subdevices[direction] += devices
        end
      end
      @subdevices
    end

    # Instantiate a new device object
    # @param [Hash]
    # @return [Input, Output]
    def new_device(direction, device_hash)
      device_class = case direction
                     when :input then Input
                     when :output then Output
                     end
      device_properties = {
        system_id: device_hash[:id],
        name: device_hash[:name],
        subname: device_hash[:subname]
      }
      device_class.new(device_properties)
    end
  end
end
