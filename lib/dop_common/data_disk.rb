module DopCommon
  class DataDisk
    include Validator
    include HashParser
    include Utils

    attr_reader :name

    def initialize(name, hash, parent = {})
      @name = name
      @hash = symbolize_keys(hash)
      @parsed_infrastructure = parent[:parsed_infrastructure]
      @parsed_infrastructure_properties = parent[:parsed_infrastructure_properties]
    end

    def validate
      log_validation_method(:pool_valid?)
      log_validation_method(:thin_valid?)
      log_validation_method(:size_valid?)
      try_validate_obj("Can't validate the 'data_disk' #{@name} because of previous error"){size}
    end

    def pool
      @pool ||= pool_valid? ? @hash[:pool] : @parsed_infrastructure_properties.default_pool
    end

    def size
      @size ||= size_valid? ? DopCommon::Utils::DataSize.new(@hash[:size]) : nil
    end

    def thin?
      @thin ||= thin_valid? ? @hash[:thin] : true
    end

    private

    def pool_valid?
      provider = @parsed_infrastructure.provider
      default_pool = @parsed_infrastructure_properties.default_pool
      raise PlanParsingError, "Data disk #{@name}: A 'pool' is required for #{provider} provider type" unless
        @parsed_infrastructure.provides?(:openstack, :baremetal) || @hash.has_key?(:pool) || default_pool
      return false unless @hash.has_key?(:pool)
      raise PlanParsingError, "Data disk #{@name}: 'pool', if defined, must be a non-empty string" if
        !@hash[:pool].kind_of?(String) || @hash[:pool].empty?
      true
    end

    def size_valid?
      raise PlanParsingError, "Data disk #{@name}: 'size' is required" if @hash[:size].nil?
      raise PlanParsingError, "Data disk #{@name}: 'size' must be of string type" unless
        @hash[:size].kind_of?(String)
      true
    end

    def thin_valid?
      return false unless @hash.has_key?(:thin)
      raise PlanParsingError, "Data disk #{@name}: thin, if specified, must be boolean" unless
        [TrueClass, FalseClass].include?(@hash[:thin].class)
      true
    end
  end
end
