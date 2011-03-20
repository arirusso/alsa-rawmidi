#!/usr/bin/env ruby
#
# ALSA driver interface library structs, enums and functions
#

module AlsaRawMIDI
  module Map
    
    extend FFI::Library
    ffi_lib 'libasound'
    
    Constants = {
      :SND_RAWMIDI_STREAM_OUTPUT => 0,
      :SND_RAWMIDI_STREAM_INPUT => 1,
      :SND_RAWMIDI_APPEND => 0x0001,
      :SND_RAWMIDI_NONBLOCK =>  0x0002,
      :SND_RAWMIDI_SYNC =>  0x0004    
    }
        
    module TypeAliases
      SndCtlType = :ulong
      SndCtl = :ulong
      SndRawMIDI = :ulong
    end
      
    # snd_ctl
    class SndCtl < FFI::Struct 
      include TypeAliases
      
      layout :dl_handle, :pointer, # void*
        :name, :pointer, # char*
        :type, SndCtlType,
        :ops, :pointer, # const snd_ctl_ops_t*
        :private_data, :pointer, # void*
        :nonblock, :ulong,
        :poll_fd, :ulong,
        :async_handlers, :ulong
    end
    
    # snd_ctl_card_info
    class SndCtlCardInfo < FFI::Struct
      layout :card, :int, # card number
             :pad, :int, # reserved for future (was type)
             :id, [:uchar, 16], # ID of card (user selectable)
             :driver, [:uchar, 16], # Driver name
             :name, [:uchar, 32], # Short name of soundcard
             :longname, [:uchar, 80], # name + info text about soundcard
             :reserved_, [:uchar, 16], # reserved for future (was ID of mixer)
             :mixername, [:uchar, 80], # visual mixer identification
             :components, [:uchar, 128] # card components / fine identification, delimited with one space (AC97 etc..)
    end
    
    # snd_rawmidi_info
    class SndRawMIDIInfo < FFI::Struct 
      layout :device, :uint, # RO/WR (control): device number
        :subdevice, :uint, # RO/WR (control): subdevice number
        :stream, :int, # WR: stream
        :card, :int, # R: card number
        :flags, :uint, # SNDRV_RAWMIDI_INFO_XXXX
        :id, [:uchar, 64], # ID (user selectable)
        :name, [:uchar, 80], # name of device
        :subname, [:uchar, 32], # name of active or selected subdevice
        :subdevices_count, :uint,
        :subdevices_avail, :uint,
        :reserved, [:uchar, 64] # reserved for future use
    end
    
    # timespec
    class Timespec < FFI::Struct
      layout :tv_sec, :time_t, # Seconds since 00:00:00 GMT
             :tv_nsec, :long # Additional nanoseconds since
    end
    
    # snd_rawmidi_status
    class SndRawMIDIStatus < FFI::Struct
      layout :stream, :int,
             :timestamp, Timespec.by_value, # Timestamp
             :avail, :size_t, # available bytes
             :xruns, :size_t, # count of overruns since last status (in bytes)
             :reserved, [:uchar, 64] # reserved for future use
    end
    
    # Simple doubly linked list implementation
    class LinkedList < FFI::Struct 
      layout :next, :pointer, # *LinkedList
             :prev, :pointer # *LinkedList
    end
    
    # snd_rawmidi
    class SndRawMIDI < FFI::Struct
      layout :card, :pointer, # *snd_card
             :list, LinkedList.by_value,
             :device, :uint, # device number 
             :info_flags, :uint, # SNDRV_RAWMIDI_INFO_XXXX
             :id, [:char, 64],
             :name, [:char, 80]
    end
    
    # spinlock_t
    class Spinlock < FFI::Struct
      layout :lock, :uint
    end
    
    # wait_queue_head_t
    class WaitQueueHead < FFI::Struct
      layout :lock, Spinlock.by_value,
             :task_list, LinkedList.by_value
    end
    
    class AtomicT < FFI::Struct
      layout :counter, :int # volatile int counter
    end
    
    class Tasklet < FFI::Struct
      layout :next, :pointer,   # pointer to the next tasklet in the list / void (*func) (unsigned long)
             :state, :ulong,    # state of the tasklet 
             :count, AtomicT.by_value, # reference counter 
             :func,  :pointer,  # tasklet handler function / void (*func) (unsigned long)
             :data,  :ulong     # argument to the tasklet function 
    end
    
    # snd_rawmidi_runtime
    class SndRawMIDIRuntime < FFI::Struct
      layout :drain, :uint, 1, # drain stage
             :oss, :uint, 1, # OSS compatible mode
             # midi stream buffer
             :buffer, :pointer, # uchar* / buffer for MIDI data
             :buffer_size, :size_t, # size of buffer
             :appl_ptr, :size_t, # application pointer
             :hw_ptr, :size_t, # hardware pointer
             :avail_min, :size_t, # min avail for wakeup
             :avail, :size_t, # max used buffer for wakeup
             :xruns, :size_t, # over/underruns counter
             # misc
             :lock, Spinlock.by_value,
             :sleep, WaitQueueHead.by_value,
             # event handler (new bytes, input only)
             :substream, :pointer, # void (*event)(struct snd_rawmidi_substream *substream);
             # defers calls to event [input] or ops->trigger [output]
             :tasklet, Tasklet.by_value,
             :private_data, :pointer, # void*
             :private_free, :pointer # void (*private_free)(struct snd_rawmidi_substream *substream)
    end
    
    # snd_rawmidi_params
    class SndRawMIDIParams < FFI::Struct
      layout :stream, :int,
             :buffer_size, :size_t, # queue size in bytes
             :avail_min, :size_t, # minimum avail bytes for wakeup
             :no_active_sensing, :uint, 1, # do not send active sensing byte in close()
             :reserved, [:uchar, 16] # reserved for future use
    end
      
    #
    # snd_card
    #
    
    # Try to load the driver for a card. 
    attach_function :snd_card_load, [:int], :int # (int card)
    # Try to determine the next card. 
    attach_function :snd_card_next, [:pointer], :int # (int* card)
    # Convert card string to an integer value. 
    attach_function :snd_card_get_index, [:pointer], :int # (const char* name)
    # Obtain the card name. 
    attach_function :snd_card_get_name, [:int, :pointer], :int # (int card, char **name)
    # Obtain the card long name. 
    attach_function :snd_card_get_longname, [:int, :pointer], :int # (int card, char **name)
    
    #
    # snd_ctl
    #
    
    # Opens a CTL. 
    attach_function :snd_ctl_open, [:pointer, :pointer, :int], :int #  (snd_ctl_t **ctl, const char *name, int mode)
    # Opens a CTL using local configuration. 
    attach_function :snd_ctl_open_lconf, [:pointer, :pointer, :int, :pointer], :int # (snd_ctl_t **ctl, const char *name, int mode, snd_config_t *lconf)
    # close CTL handle 
    attach_function :snd_ctl_close, [:pointer], :int #(snd_ctl_t *ctl)
    # set nonblock mode 
    attach_function :snd_ctl_nonblock, [:pointer, :int], :int # (snd_ctl_t *ctl, int nonblock)
    # Get card related information. 
    attach_function :snd_ctl_card_info, [:pointer, :pointer], :int # (snd_ctl_t *ctl, snd_ctl_card_info_t *info)
    # Get card name from a CTL card info.
    attach_function :snd_ctl_card_info_get_name, [:pointer], :string # (const snd_ctl_card_info_t *obj) / const char*
    # Get info about a RawMidi device. 
    attach_function :snd_ctl_rawmidi_info, [TypeAliases::SndCtl, :pointer], :int # (snd_ctl_t *ctl, snd_rawmidi_info_t *info)
    # Get next RawMidi device number. 
    attach_function :snd_ctl_rawmidi_next_device, [TypeAliases::SndCtl, :pointer], :int # (snd_ctl_t *ctl, int *device)

    # 
    # snd_rawmidi
    #
    
    # close RawMidi handle 
    attach_function :snd_rawmidi_close, [TypeAliases::SndRawMIDI], :int # (snd_rawmidi_t *rmidi)
    # drain all bytes in the rawmidi I/O ring buffer
    attach_function :snd_rawmidi_drain, [TypeAliases::SndRawMIDI], :int # (snd_rawmidi_t *rmidi)
    # set nonblock mode
    attach_function :snd_rawmidi_nonblock, [TypeAliases::SndRawMIDI, :int], :int # (snd_rawmidi_t *rmidi, int nonblock)
    # Opens a new connection to the RawMidi interface.
    attach_function :snd_rawmidi_open, [:pointer, :pointer, :string, :int], :int # (snd_rawmidi_t **in_rmidi, snd_rawmidi_t **out_rmidi, const char *name, int mode)
    # Opens a new connection to the RawMidi interface using local configuration. 
    attach_function :snd_rawmidi_open_lconf, [:pointer, :pointer, :string, :int, :pointer], :int #(snd_rawmidi_t **in_rmidi, snd_rawmidi_t **out_rmidi, const char *name, int mode, snd_config_t *lconf)
    # read MIDI bytes from MIDI stream
    attach_function :snd_rawmidi_read, [TypeAliases::SndRawMIDI, :pointer, :size_t], :ssize_t # (snd_rawmidi_t *rmidi, void *buffer, size_t size) 
    # write MIDI bytes to MIDI stream
    attach_function :snd_rawmidi_write, [TypeAliases::SndRawMIDI, :long, :size_t], :ssize_t # (snd_rawmidi_t *rmidi, const void *buffer, size_t size)
    
    #
    # snd_rawmidi_info
    #

    enum :snd_rawmidi_stream, [
      'SND_RAWMIDI_STREAM_OUTPUT', 0,
      'SND_RAWMIDI_STREAM_INPUT', 1,
      'SND_RAWMIDI_STREAM_LAST', 1
    ]
    
    # get information about RawMidi handle 
    attach_function :snd_rawmidi_info, [:pointer, :pointer], :int # (snd_rawmidi_t *rmidi, snd_rawmidi_info_t *info)
    # get rawmidi count of subdevices
    attach_function :snd_rawmidi_info_get_subdevices_count, [:pointer], :uint # (const snd_rawmidi_info_t *obj)
    # set rawmidi device number 
    attach_function :snd_rawmidi_info_set_device, [:pointer, :uint], :void # (snd_rawmidi_info_t *obj, unsigned int val)
    # set rawmidi subdevice number
    attach_function :snd_rawmidi_info_set_subdevice, [:pointer, :uint], :void # (snd_rawmidi_info_t *obj, unsigned int val)
    # set rawmidi stream identifier
    attach_function :snd_rawmidi_info_set_stream, [:pointer, :snd_rawmidi_stream], :void # (snd_rawmidi_info_t *obj, snd_rawmidi_stream_t val)
    # get size of the snd_rawmidi_info_t structure in bytes 
    attach_function :snd_rawmidi_info_sizeof, [], :size_t # (void)
 
    #
    # misc
    #
    
    # Convert an error code to a string
    attach_function :snd_strerror, [:int], :string # (int errnum) / const char*
    # Frees the global configuration tree in snd_config.
    attach_function :snd_config_update_free_global, [], :int # (void)
    
  end
end