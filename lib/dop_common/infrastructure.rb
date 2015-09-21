#
# DOP Common infrastructure hash parser
#

module DopCommon
  class Infrastructure
    include Validator
    include HashParser

    attr_reader :name

    def initialize(name, hash)
      @name = name
      @hash = symbolize_keys(hash)
    end

    def validate
      log_validation_method(:type_valid?)
      log_validation_method(:networks_valid?)
      log_validation_method(:affinity_groups_valid?)
      try_validate_obj("Plan: Can't validate the networks part because of a previous error") { networks }
      try_validate_obj("Plan: Can't validate the affinity groups part because of a previous error") { affinity_groups }
    end

    def type
      @type ||= type_valid? ? @hash[:type] : nil
    end

    def networks
      @networks ||= networks_valid? ? create_networks : {}
    end

    def affinity_groups
      @affinity_groups ||= affinity_groups_valid? ? create_affinity_groups : {}
    end

    private

    def type_valid?
      case @hash[:type]
      when nil then raise PlanParsingError, "Infrastructure #{@name}: type is a required property"
      # TODO: Move supported_provider? from dopv to dop_common.
      when String then true
      else raise PlanParsingError, "Infrastructure #{@name}: type must be a string"
      end
    end

    def networks_valid?
      return false if @hash[:networks].nil?
      @hash[:networks].kind_of?(Hash) or
        raise PlanParsingError, "Infrastructure #{@name}: networks must be a hash"
      @hash[:networks].keys.all? { |name| name.kind_of?(String) } or
        raise PlanParsingError, "Infrastructure #{@name}: network names have to be string"
      @hash[:networks].values.all? { |network| network.nil? or network.kind_of?(Hash) } or
        raise PlanParsingError, "Infrastructure #{@name}: networks have to be defined as nil or hash"
    end

    def affinity_groups_valid?
      return false if @hash[:affinity_groups].nil?
      @hash[:affinity_groups].kind_of?(Hash) or
        raise PlanParsingError, "Infrastructure #{@name}: affinity_groups must be a hash"
      @hash[:affinity_groups].keys.all? { |name| name.kind_of?(String) } or
        raise PlanParsingError, "Infrastructure #{@name}: affinity group names have to be string"
      @hash[:affinity_groups].values.all? { |ag| ag.kind_of?(Hash) } or
        raise PlanParsingError, "Infrastructure #{@name}: affinity groups have to be defined as hash"
    end

    def create_networks
      Hash[@hash[:networks].map do |name, hash|
        [name, ::DopCommon::Network.new(name, hash)]
      end]
    end

    def create_affinity_groups
      Hash[@hash[:affinity_groups].map do |name, hash|
        [name, ::DopCommon::AffinityGroup.new(name, hash) ]
      end]
    end
  end
end
