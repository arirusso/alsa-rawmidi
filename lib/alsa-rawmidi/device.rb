#!/usr/bin/env ruby

module AlsaRawMIDI

  #
  # Module containing methods used by both input and output devices when using the
  # ALSA driver interface
  #
  module Device

                # has the device been initialized?
    attr_reader :enabled, 
                # the alsa id of the device
                :system_id,
                # a unique numerical id for the device
                :id, 
                :name,
                :subname,
                # :input or :output
                :type 

    alias_method :enabled?, :enabled
    
    def initialize(options = {}, &block)
      @id = options[:id]
      @name = options[:name]
      @subname = options[:subname]
      @system_id = options[:system_id]
      
      # cache the type name so that inspecting the class isn't necessary each time
      @type = self.class.name.split('::').last.downcase.to_sym

      @enabled = false
    end

    # select the first device of type <em>type</em>
    def self.first(type)
      all_by_type[type].first
    end

    # select the last device of type <em>type</em>
    def self.last(type)
      all_by_type[type].last
    end

    # a Hash of :input and :output devices
    def self.all_by_type
      available_devices = { :input => [], :output => [] }
      device_count = 0
      32.times do |i|
        card = Soundcard.find(i)
        unless card.nil?
          available_devices.keys.each do |type|
            devices = card.subdevices[type]
            devices.each do |dev|
              dev.send(:id=, device_count)
              device_count += 1
            end
            available_devices[type] += devices
          end
        end
      end
      available_devices
    end

    # all devices of both types
    def self.all
      all_by_type.values.flatten
    end
    
    private
    
    def id=(id)
      @id = id
    end

  end

end