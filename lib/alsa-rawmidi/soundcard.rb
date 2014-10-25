module AlsaRawMIDI

  class Soundcard

    attr_reader :subdevices

    def initialize(card_num)
      @subdevices = {
        :input => [],
        :output => []
      }
      @id = card_num
      populate_subdevices
    end

    def self.find(card_num)
      @soundcards ||= {}
      if API::Soundcard.exists?(card_num)
        @soundcards[card_num] ||= Soundcard.new(card_num)
      end
    end

    private

    def populate_subdevices
      ids = API::Soundcard.get_device_ids(@id)
      ids.each do |id|
        @subdevices.keys.each do |direction|
          devices = get_subdevices(direction, id) do |device_hash|
            new_device(device_hash)
          end
          @subdevices[direction] += devices
        end
      end
    end

    def get_subdevices(direction, device_id, &block)
      info = API::Soundcard.get_info(direction, device_id)
      handle = API::Soundcard.get_handle(@id)
      i = 0
      subdev_count = 1
      available = []
      while i <= subdev_count
        if API::Soundcard.valid_subdevice?(info, i, handle)
          subdev_count = API::Soundcard.get_subdevice_count(info) if i.zero?
          device_hash = {
            :device_id => device_id,
            :direction => direction,
            :id => i,
            :name => info[:name].to_s,
            :subname => info[:subname].to_s,
            :subdev_count => subdev_count
          }
          available << yield(device_hash)
          i += 1
        else
          break
        end
      end
      available
    end

    # Instantiate a new device object
    # @param [Hash]
    # @return [Input, Output]
    def new_device(device_hash)
      device_class = case device_hash[:direction]
      when :input then Input
      when :output then Output
      end
      system_id = API::Soundcard.get_subdevice_id(@id, device_hash[:device_id], device_hash[:subdev_count], device_hash[:id])
      device_class.new(:system_id => system_id, :name => device_hash[:name], :subname => device_hash[:subname])
    end

  end

end
