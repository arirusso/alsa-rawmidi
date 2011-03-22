#!/usr/bin/env ruby

module AlsaRawMIDI

    #
    # Module containing methods used by both input and output devices when using the
    # ALSA driver interface
    #
    module Device

        attr_reader :enabled, # has the device been initialized?
                    :id, # the id of the device
                    :name,
                    :subname,
                    :type # :input or :output

        alias_method :enabled?, :enabled
        def initialize(id, options = {}, &block)
            @name = options[:name]
            @subname = options[:subname]
            @id = id

            # cache the type name so that inspecting the class isn't necessary each time
            @type = self.class.name.split('::').last.downcase.to_sym

            @enabled = false
        end

        # close the device
        def close
            Map.snd_rawmidi_drain(@handle)
            Map.snd_rawmidi_close(@handle)
        end

        # select the first device of type <em>type</em>
        def self.first(type)
            all_by_type[type].first
        end

        # select the last device of type <em>type</em>
        def self.last(type)
            all_by_type[type].last
        end

        # a hash of :input and :output devices
        def self.all_by_type
            available_devices = { :input => [], :output => [] }
            count = 0
            32.times do |i|
                card = Soundcard.find(i)
                unless card.nil?
                    available_devices.keys.each do |type|
                    available_devices[type] += card.subdevices[type]
                    end
                end
            end
            available_devices
        end

        # all devices of both types
        def self.all
            all_by_type.values.flatten
        end

    end
    
end