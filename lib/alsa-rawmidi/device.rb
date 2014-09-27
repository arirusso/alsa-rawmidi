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
    
    def initialize(options = {}, &block)
      @id = options[:id]
      @name = options[:name]
      @subname = options[:subname]
      @system_id = options[:system_id]
      
      # cache the type name so that inspecting the class isn't necessary each time
      @type = self.class.name.split('::').last.downcase.to_sym

      @enabled = false
    end

    # Select the first device of the given type
    def self.first(type)
      all_by_type[type].first
    end

    # Select the last device of the given type
    def self.last(type)
      all_by_type[type].last
    end

    # A hash of devices, partitioned by type
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

    # All devices
    def self.all
      all_by_type.values.flatten
    end
    
    private
    
    def id=(id)
      @id = id
    end

  end

end
