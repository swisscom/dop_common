#
# DOP Common infrastructure properties parser
#

module DopCommon
  class InfrastructureProperties
    include Validator
    include HashParser

    def initialize(hash, parsed_infrastructure)
      @hash = symbolize_keys(hash)
      @parsed_infrastructure = parsed_infrastructure
    end

    def validate
      log_validation_method(:affinity_groups_valid?)
      log_validation_method(:keep_ha_valid?)
      log_validation_method(:datacenter_valid?)
      log_validation_method(:cluster_valid?)
      log_validation_method(:default_pool_valid?)
      log_validation_method(:dest_folder_valid?)
      log_validation_method(:tenant_valid?)
      log_validation_method(:use_config_drive_valid?)
      log_validation_method(:domain_id_valid?)
      log_validation_method(:endpoint_type_valid?)
    end

    def affinity_groups
      @affinity_groups ||= affinity_groups_valid? ? @hash[:affinity_groups] : []
    end

    def security_groups
      @security_groups ||= security_groups_valid? ? create_security_groups : @parsed_infrastructure.default_security_groups
    end

    def keep_ha?
      @keep_ha ||= keep_ha_valid? ? @hash[:keep_ha] : true
    end
    alias_method :keep_ha, :keep_ha?

    def datacenter
      @datacenter ||= datacenter_valid? ? @hash[:datacenter] : nil
    end

    def cluster
      @cluster ||= cluster_valid? ? @hash[:cluster] : nil
    end

    def default_pool
      @default_pool ||= default_pool_valid? ? @hash[:default_pool] : nil
    end

    def dest_folder
      @dest_folder ||= dest_folder_valid? ? @hash[:dest_folder] : nil
    end

    def tenant
      @tenant ||= tenant_valid? ? @hash[:tenant] : nil
    end

    def use_config_drive?
      @use_config_drive ||= use_config_drive_valid? ? @hash[:use_config_drive] : false
    end
    alias_method :use_config_drive, :use_config_drive?

    def domain_id
      @domain_id ||= domain_id_valid? ? create_domain_id : nil
    end

    def endpoint_type
      @endpoint_type ||= endpoint_type_valid? ? create_endpoint_type : nil
    end

    private

    def affinity_groups_valid?
      ags = @hash[:affinity_groups]
      return false if ags.nil?
      raise PlanParsingError, "Infrastructure properties: Affinity groups, if specified, must be a non-empty array" if
        !ags.kind_of?(Array) || ags.empty?
      raise PlanParsingError, "Infrastructure properties: Each affinity group must be a non-empty string" if
        ags.any? { |ag| !ag.kind_of?(String) || ag.empty? }
      true
    end

    def security_groups_valid?
      return false unless @hash[:security_groups] or @hash[:additional_security_groups]
      raise PlanParsingError, "Infrastructure properties: security_groups and additional_security_groups are mutually exclusive" if
        @hash[:security_groups] and @hash[:additional_security_groups]
      sgs = @hash[:security_groups] || @hash[:additional_security_groups]
      raise PlanParsingError, "Infrastructure properties: (additional_)security_groups must be non-empty arrays" if
        !sgs.kind_of?(Array) || sgs.empty?
      raise PlanParsingError, "Infrastructure properties: (additional_)security_groups must be non-empty strings" if
        sgs.any? {|sg| !sg.kind_of?(String) || sg.empty? }
      true
    end

    def keep_ha_valid?
      return false if @hash[:keep_ha].nil?
      raise PlanParsingError, "Infrastructure properties: The 'keep_ha' is valid only for OVirt/RHEVm infrastructure types" unless
        @parsed_infrastructure.provides?(:ovirt)
      raise PlanParsingError, "Infrastructure properties: The 'keep_ha' must be boolean" unless
        @hash[:keep_ha].kind_of?(TrueClass) || @hash[:keep_ha].kind_of?(FalseClass)
      true
    end

    def datacenter_valid?
      return false unless @parsed_infrastructure.provides?(:ovirt, :vsphere)
      raise PlanParsingError, "Infrastructure properties: The 'datacenter' must be defined" if
        @parsed_infrastructure.provides?(:ovirt, :vsphere) && @hash[:datacenter].nil?
      raise PlanParsingError, "Infrastructure properties: The 'datacenter' must be a non-empty string" if
        !@hash[:datacenter].kind_of?(String) || @hash[:datacenter].empty?
      true
    end

    def cluster_valid?
      return false unless @parsed_infrastructure.provides?(:ovirt, :vsphere)
      raise PlanParsingError, "Infrastructure properties: The 'cluster' must be defined" if
        @parsed_infrastructure.provides?(:ovirt, :vsphere) && @hash[:cluster].nil?
      raise PlanParsingError, "Infrastructure properties: The 'cluster' must be a non-empty string" if
        !@hash[:cluster].kind_of?(String) || @hash[:cluster].empty?
      true
    end

    def default_pool_valid?
      return false if @hash[:default_pool].nil?
      raise PlanParsingError, "Infrastructure properties: The 'default_pool' must be a non-empty string" if
        !@hash[:default_pool].kind_of?(String) || @hash[:default_pool].empty?
      true
    end

    def dest_folder_valid?
      return false if @hash[:dest_folder].nil?
      raise PlanParsingError, "Infrastructure properties: The 'dest_folder' must be a non-empty string" if
        !@hash[:dest_folder].kind_of?(String) || @hash[:dest_folder].empty?
      true
    end

    def tenant_valid?
      return false unless @parsed_infrastructure.provides?(:openstack)
      raise PlanParsingError, "Infrastructure properties: The 'tenant' must be defined" if
        @parsed_infrastructure.provides?(:openstack) && @hash[:tenant].nil?
      raise PlanParsingError, "Infrastructure properties: The 'tenant' must be a non-empty string" if
        !@hash[:tenant].kind_of?(String) || @hash[:tenant].empty?
      true
    end

    def domain_id_valid?
      return false unless @parsed_infrastructure.provides?(:openstack)
      return true if @hash[:domain_id].nil?
      raise PlanParsingError, "Infrastructure properties: The domain_id must be a non-empty string" if
        !@hash[:domain_id].kind_of?(String) || @hash[:domain_id].empty?
      true
    end

    def endpoint_type_valid?
      return false unless @parsed_infrastructure.provides?(:openstack)
      return true if @hash[:endpoint_type].nil?
      raise PlanParsingError, "Infrastructure properties: The endpoint must be 'publicURL', 'internalURL' or 'adminURL'" unless
      @hash[:endpoint_type].kind_of?(String) && %w(publicURL internalURL adminURL).include?(@hash[:endpoint_type])
      true
    end

    def use_config_drive_valid?
      return false if @hash[:use_config_drive].nil?
      raise PlanParsingError, "Infrastructure properties: The 'use_config_drive' is valid only for OpenStack infrastructure types" unless @parsed_infrastructure.provides?(:openstack)
      raise PlanParsingError, "Infrastructure properties: The 'use_config_drive' must be boolean" unless
        @hash[:use_config_drive].kind_of?(TrueClass) || @hash[:use_config_drive].kind_of?(FalseClass)
      true
    end

    def create_security_groups
      sgs = @hash[:security_groups]
      sgs ? sgs : (@parsed_infrastructure.default_security_groups + @hash[:additional_security_groups]).uniq
    end

    def create_domain_id
      @hash[:domain_id].nil? ? 'default' : @hash[:domain_id]
    end
    
    def create_endpoint_type
      @hash[:endpoint_type].nil? ? 'publicURL' : @hash[:endpoint_type]
    end
  end
end
