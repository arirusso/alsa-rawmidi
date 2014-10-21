module AlsaRawMIDI

  # Common device functionality
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

    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    def initialize(options = {}, &block)
      @id = options[:id]
      @name = options[:name]
      @subname = options[:subname]
      @system_id = options[:system_id]
      @type = get_type
      @enabled = false
    end

    private

    def id=(id)
      @id = id
    end

    def get_type
      self.class.name.split('::').last.downcase.to_sym
    end

    module ClassMethods

      # Select the first device of the given type
      def first(type)
        all_by_type[type].first
      end

      # Select the last device of the given type
      def last(type)
        all_by_type[type].last
      end

      # A hash of devices, partitioned by type
      def all_by_type
        @devices ||= get_devices
      end

      # All devices
      def all
        all_by_type.values.flatten
      end

      private

      def get_devices
        available_devices = { 
          :input => [], 
          :output => [] 
        }
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

    end

  end

end
