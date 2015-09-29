#
# DOP Common infrastructure hash parser
#

require 'uri'

module DopCommon
  class Infrastructure
    include Validator
    include HashParser

    attr_reader :name

    VALID_PROVIDER_TYPES = [:baremetal, :openstack, :ovirt, :rhev, :rhevm, :vmware, :vsphere]

    def initialize(name, hash)
      @name = name
      @hash = symbolize_keys(hash)
      @parsed_credentials = @hash[:parsed_credentials]
    end

    def validate
      log_validation_method(:provider_valid?)
      log_validation_method(:endpoint_valid?)
      log_validation_method(:networks_valid?)
      log_validation_method(:affinity_groups_valid?)
      try_validate_obj("Plan: Can't validate the networks part because of a previous error") { networks }
      try_validate_obj("Plan: Can't validate the affinity groups part because of a previous error") { affinity_groups }
    end

    def provider
      @provider ||= provider_valid? ? @hash[:type].downcase.to_sym : nil
    end
    alias_method :type, :provider

    def provides?(type)
      provider == type.downcase.to_sym
    end
    alias_method :type?, :provides?

    def endpoint
      @endpoint ||= create_endpoint if endpoint_valid?
    end

    def credentials
      @credentials ||= credentials_valid? ? create_credentials : nil
    end

    def networks
      @networks ||= networks_valid? ? create_networks : []
    end

    def affinity_groups
      @affinity_groups ||= affinity_groups_valid? ? create_affinity_groups : []
    end

    private

    def provider_valid?
      case @hash[:type]
      when nil
        raise PlanParsingError, "Infrastructure #{@name}: provider type is a required property"
      when String
        raise PlanParsingError, "Infrastructure #{@name}: invalid provider type" unless
          VALID_PROVIDER_TYPES.include?(@hash[:type].downcase.to_sym)
      else
        raise PlanParsingError, "Infrastructure #{@name}: provider type must be a string"
      end
      true
    end
    alias_method :type_valid?, :provider_valid?

    def endpoint_valid?
      return false if provides?(:baremetal) && @hash[:endpoint].nil?
      raise PlanParsingError, "Infrastructure #{@name}: endpoint is a required property" if @hash[:endpoint].nil?
      ::URI.parse(@hash[:endpoint])
      true
    rescue URI::InvalidURIError
      raise PlanParsingError, "Interface #{@name}: the specified endpoint URL is invalid"
    end

    def credentials_valid?
      return false if provides?(:baremetal) && @hash[:credentials].nil?
      raise PlanParsingError, "Infrastructure #{@name}: Credentials pointer must be a string" unless
        @hash[:credentials].kind_of?(String)
      raise PlanParsingError, "Infrastructure #{@name}: Missing definition of endpoint credentials" unless
        @parsed_credentials.has_key?(@hash[:credentials])
      true
    end

    def networks_valid?
      return false if provides?(:baremetal) && @hash[:networks].nil? # Network is optional for baremetal
      raise PlanParsingError, "Infrastructure #{@name}: network is a required property" if
        !provides?(:baremetal) && @hash[:networks].nil?
      raise PlanParsingError, "Infrastructure #{@name}: networks must be a hash" unless
        @hash[:networks].kind_of?(Hash)
      raise PlanParsingError, "Infrastructure #{@name}: network names have to be string" unless
        @hash[:networks].keys.all? { |name| name.kind_of?(String) }
      raise PlanParsingError, "Infrastructure #{@name}: each network has to be defined as hash" unless
      @hash[:networks].values.all? { |network| network.kind_of?(Hash) }
      true
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

    def create_endpoint
      ::URI.parse(@hash[:endpoint])
    end

    def create_credentials
      @parsed_credentials[@hash[:credentials]]
    end

    def create_networks
      @hash[:networks].collect { |name,hash| ::DopCommon::Network.new(name, hash) }
    end

    def create_affinity_groups
      @hash[:affinity_groups].collect { |name,hash| ::DopCommon::AffinityGroup.new(name, hash) }
    end
  end
end
