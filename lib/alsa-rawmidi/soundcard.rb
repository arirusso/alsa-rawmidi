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
      ids = API::Soundcard.get_subdevice_ids(@id)
      ids.each do |id|
        @subdevices.keys.each do |direction|
          devices = get_subdevices(direction, id) do |device_hash|
            new_device(device_hash)
          end
          @subdevices[direction] += devices
        end
      end
    end

    # @param [Fixnum, String] device_num
    # @param [Fixnum] subdev_count
    # @param [Fixnum] id
    # @return [String]
    def get_alsa_subdev_id(device_id, subdev_count, id)
      ext = (subdev_count > 1) ? ",#{id}" : ''
      name = API::Soundcard.get_name(@id)
      "#{name},#{device_id.to_s}#{ext}"
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
            :direction => direction,
            :id => i,
            :info => info,
            :device_id => device_id,
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
      system_id = get_alsa_subdev_id(device_hash[:device_id], device_hash[:subdev_count], device_hash[:id])
      info = device_hash[:info]
      device_class.new(:system_id => system_id, :name => info[:name].to_s, :subname => info[:subname].to_s)
    end

  end

end
