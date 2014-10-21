module AlsaRawMIDI
	
  class Soundcard

    attr_reader :subdevices
    
    def initialize(card_num)
      @subdevices = { 
        :input => [], 
        :output => [] 
      }
      populate(card_num)
    end

    def self.find(card_num)
      if API.snd_card_load(card_num) == 1
        Soundcard.new(card_num) 
      end
    end

    private

    def populate(card_num)
      name = "hw:#{card_num}"
      handle_ptr = FFI::MemoryPointer.new(FFI.type_size(:int))
      #snd_ctl = API::SndCtl.new
      #snd_ctl_pointer = FFI::MemoryPointer.new(:pointer).write_pointer(snd_ctl.pointer)
      API.snd_ctl_open(handle_ptr, name, 0)
      handle = handle_ptr.read_int
      32.times do |i|
        devnum = FFI::MemoryPointer.new(:int).write_int(i)
        if (err = API.snd_ctl_rawmidi_next_device(handle, devnum)) < 0
        break # TODO: fix this
        end
        @subdevices.each do |direction, collection|
          card = {
            :handle => handle,
            :num => card_num,
            :device_num => i
          }
          collection += populate_subdevices(direction, card)
        end
      end
    end

    def unpack(string)
      arr = string.delete_if(&:zero?)
      arr.pack("C#{arr.length}")
    end

    def get_alsa_subdev_id(card_num, device_num, subdev_count, i)
      ext = (subdev_count > 1) ? ",#{i}" : ''
      "hw:#{card_num},#{device_num}#{ext}"
    end

    def populate_subdevices(direction, card)
      stream_type, device_class = *case direction
      when :input then [API::CONSTANTS[:SND_RAWMIDI_STREAM_INPUT], Input]
      when :output then [API::CONSTANTS[:SND_RAWMIDI_STREAM_OUTPUT], Output]
      end
      info = API::SndRawMIDIInfo.new
      API.snd_rawmidi_info_set_device(info.pointer, card[:device_num])
      API.snd_rawmidi_info_set_stream(info.pointer, stream_type)
      i = 0
      subdev_count = 1
      devices = []
      while (i <= subdev_count)
        device = get_subdevice(device_class, i, info, card)
        if device.nil?
          break
        else
          devices << device 
          i += 1
        end
      end
      devices
    end

    def get_subdevice(device_class, id, info, card)
      API.snd_rawmidi_info_set_subdevice(info.pointer, id)
      # TODO: fix this
      if (err = API.snd_ctl_rawmidi_info(card[:handle], info.pointer)) >= 0

        if (id < 1)
          subdev_count = API.snd_rawmidi_info_get_subdevices_count(info.pointer)
          subdev_count = 0 if subdev_count > 32
          create_device(device_class, id, subdev_count, info, card)
        end
      end
    end

    def create_device(device_class, id, subdev_count, info, card)
      system_id = get_alsa_subdev_id(card[:num], card[:device_num], subdev_count, id)
      device_options = {
        :system_id => system_id, 
        :name => info[:name].to_s, 
        :subname => info[:subname].to_s
      }
      device_class.new(device_options)
    end

  end

end
