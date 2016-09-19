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
    end

    def affinity_groups
      @affinity_groups ||= affinity_groups_valid? ? @hash[:affinity_groups] : []
    end

    def keep_ha
      @keep_ha ||= keep_ha_valid? ? @hash[:keep_ha] : true
    end

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

    def keep_ha_valid?
      return false if @hash[:keep_ha].nil?
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

    def use_config_drive_valid?
      return false if @hash[:use_config_drive].nil?
      raise PlanParsingError, "Infrastructure properties: The 'use_config_drive' is valid only for OpenStack infrastructure types" unless @parsed_infrastructure.provides?(:openstack)
      raise PlanParsingError, "Infrastructure properties: The 'use_config_drive' must be boolean" unless
        @hash[:use_config_drive].kind_of?(TrueClass) || @hash[:use_config_drive].kind_of?(FalseClass)
      true
    end
  end
end
