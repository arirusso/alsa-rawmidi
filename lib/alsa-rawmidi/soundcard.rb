module AlsaRawMIDI

  class Soundcard

    attr_reader :subdevices

    def initialize(card_num)
      @subdevices = {
        :input => [],
        :output => []
      }
      populate_subdevices(card_num)
    end

    def self.find(card_num)
      Soundcard.new(card_num) if API.snd_card_load(card_num).eql?(1)
    end

    private

    def get_handle(card_num)
      pointer = FFI::MemoryPointer.new(FFI.type_size(:int))
      API.snd_ctl_open(pointer, get_alsa_card_name(card_num), 0)
      pointer.read_int
    end

    def populate_subdevices(card_num)
      handle = get_handle(card_num)
      ids = (0..31).to_a.select do |i|
        devnum = FFI::MemoryPointer.new(:int).write_int(i)
        API.snd_ctl_rawmidi_next_device(handle, devnum) >= 0
      end
      ids.each do |id|
        @subdevices.keys.each do |direction|
          @subdevices[direction] += get_subdevice(direction, handle, card_num, id)
        end
      end
    end

    def unpack(string)
      arr = string.delete_if { |n| n.zero? }
      arr.pack("C#{arr.length}")
    end

    # @param [Fixnum, String] num
    # @return [String]
    def get_alsa_card_name(num)
      "hw:#{num.to_s}"
    end

    # @param [Fixnum, String] card_num
    # @param [Fixnum, String] device_num
    # @param [Fixnum] subdev_count
    # @param [Fixnum] id
    # @return [String]
    def get_alsa_subdev_id(card_num, device_num, subdev_count, id)
      ext = (subdev_count > 1) ? ",#{id}" : ''
      "#{get_alsa_card_name(card_num)},#{device_num.to_s}#{ext}"
    end

    def get_subdevice(direction, ctl_ptr, card_num, device_num)
      info = get_info(direction, device_num)
      i = 0
      subdev_count = 1
      available = []
      while i <= subdev_count
        API.snd_rawmidi_info_set_subdevice(info.pointer, i)
        if API.snd_ctl_rawmidi_info(ctl_ptr, info.pointer) >= 0
          subdev_count = get_subdev_count(info) if i.zero?
          available << new_device(direction, info, card_num, device_num, subdev_count, i)
          i += 1
        else
          break
        end
      end
      available
    end

    def get_info(direction, device_num)
      stream_key = case direction
      when :input then :SND_RAWMIDI_STREAM_INPUT
      when :output then :SND_RAWMIDI_STREAM_OUTPUT
      end
      stream = API::CONSTANTS[stream_key]
      info = API::SndRawMIDIInfo.new
      API.snd_rawmidi_info_set_device(info.pointer, device_num)
      API.snd_rawmidi_info_set_stream(info.pointer, stream)
      info
    end

    def get_subdev_count(info)
      subdev_count = API.snd_rawmidi_info_get_subdevices_count(info.pointer)
      subdev_count = 0 if subdev_count > 32
      subdev_count
    end

    # Instantiate a new device object
    # @return [Input, Output]
    def new_device(direction, info, card_num, device_num, subdev_count, id)
      system_id = get_alsa_subdev_id(card_num, device_num, subdev_count, id)
      device_class = case direction
      when :input then Input
      when :output then Output
      end
      device_class.new(:system_id => system_id, :name => info[:name].to_s, :subname => info[:subname].to_s)
    end

  end

end
