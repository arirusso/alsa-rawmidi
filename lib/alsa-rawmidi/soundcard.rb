module AlsaRawMIDI
	
  class Soundcard

    attr_reader :subdevices
    
    def initialize(card_num)
      @subdevices = { :input => [], :output => [] }
      name = "hw:#{card_num}"
      handle_ptr = FFI::MemoryPointer.new(FFI.type_size(:int))
      #snd_ctl = Map::SndCtl.new
      #snd_ctl_pointer = FFI::MemoryPointer.new(:pointer).write_pointer(snd_ctl.pointer)
      Map.snd_ctl_open(handle_ptr, name, 0)
      handle = handle_ptr.read_int
      32.times do |i|
        devnum = FFI::MemoryPointer.new(:int).write_int(i)
        if (err = Map.snd_ctl_rawmidi_next_device(handle, devnum)) < 0
        break # fix this
        end
        @subdevices.keys.each do |type|
          populate_subdevices(type, handle, card_num, i)
        end
      end
    end

    def self.find(card_num)
      Soundcard.new(card_num) if Map.snd_card_load(card_num).eql?(1)
    end

    private

    def unpack(string)
      arr = string.delete_if { |n| n.zero? }
      arr.pack("C#{arr.length}")
    end

    def get_alsa_subdev_id(card_num, device_num, subdev_count, i)
      ext = (subdev_count > 1) ? ",#{i}" : ''
      "hw:#{card_num},#{device_num}#{ext}"
    end

    def populate_subdevices(type, ctl_ptr, card_num, device_num)
      ctype, dtype = *case type
      when :input then [Map::Constants[:SND_RAWMIDI_STREAM_INPUT], Input]
      when :output then [Map::Constants[:SND_RAWMIDI_STREAM_OUTPUT], Output]
      end
      info = Map::SndRawMIDIInfo.new
      Map.snd_rawmidi_info_set_device(info.pointer, device_num)
      Map.snd_rawmidi_info_set_stream(info.pointer, ctype)
      i = 0
      subdev_count = 1
      available = []
      while (i <= subdev_count)
        Map.snd_rawmidi_info_set_subdevice(info.pointer, i)
        # fix this
        if (err = Map.snd_ctl_rawmidi_info(ctl_ptr, info.pointer)) < 0
        break
        end

        if (i < 1)
        subdev_count = Map.snd_rawmidi_info_get_subdevices_count(info.pointer)
        subdev_count = (subdev_count > 32) ? 0 : subdev_count
        end

        name = info[:name].to_s
        system_id = get_alsa_subdev_id(card_num, device_num, subdev_count, i)
        dev = dtype.new(:system_id => system_id, :name => info[:name].to_s, :subname => info[:subname].to_s)
        available << dev
        i += 1
      end
      @subdevices[type] += available
    end

  end

end
