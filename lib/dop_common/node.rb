#
# DOP common node hash parser
#

module DopCommon
  class Node
    include Validator
    include HashParser

    attr_reader :name

    DEFAULT_DIGITS = 2

    VALID_FLAVOR_TYPES = {
      :tiny     => {
        :cores    => 1,
        :memory   => 536870912,
        :storage  => 1073741824
      },
      :small    => {
        :cores    => 1,
        :memory   => 2147483648,
        :storage  => 10737418240
      },
      :medium   => {
        :cores    => 2,
        :memory   => 4294967296,
        :storage  => 10737418240
      },
      :large    => {
        :cores    => 4,
        :memory   => 8589934592,
        :storage  => 10737418240
      },
      :xlarge   => {
        :cores    => 8,
        :memory   => 17179869184,
        :storage  => 10737418240
      }
    }

    DEFAULT_OPENSTACK_FLAVOR = 'm1.medium'

    DEFAULT_CORES   = VALID_FLAVOR_TYPES[:medium][:cores]
    DEFAULT_MEMORY  = VALID_FLAVOR_TYPES[:medium][:memory]
    DEFAULT_STORAGE = VALID_FLAVOR_TYPES[:medium][:storage]

    def initialize(name, hash, parent={})
      @name = name
      @hash = symbolize_keys(hash)
      @parsed_infrastructures = parent[:parsed_infrastructures]
    end

    def validate
      log_validation_method('digits_valid?')
      log_validation_method('range_valid?')
      log_validation_method('fqdn_valid?')
      log_validation_method('infrastructure_valid?')
      log_validation_method('infrastructure_properties_valid?')
      log_validation_method('image_valid?')
      log_validation_method('full_clone_valid?')
      log_validation_method('interfaces_valid?')
      log_validation_method('flavor_valid?')
      log_validation_method('cores_valid?')
      log_validation_method('memory_valid?')
      log_validation_method('storage_valid?')
      log_validation_method('timezone_valid?')
      log_validation_method('product_id_valid?')
      log_validation_method('organization_name_valid?')
      try_validate_obj("Node: Can't validate the interfaces part because of a previous error"){interfaces}
      try_validate_obj("Node: Can't validate the 'infrastructure_properties' part because of a previous error"){infrastructure_properties}
    end

    def digits
      @digits ||= digits_valid? ?
        @hash[:digits] : DEFAULT_DIGITS
    end

    def range
      @range ||= range_valid? ?
        Range.new(*@hash[:range].scan(/\d+/)) : nil
    end

    # Check if the node describes a series of nodes.
    def inflatable?
      @name.include?('{i}')
    end

    # Create and return all the nodes in the series
    def inflate
      range.map do |node_number|
        @node_copy = clone
        @node_copy.name = @name.gsub('{i}', "%0#{digits}d" % node_number)
        @node_copy
      end
    end

    def fqdn
      @fqdn ||= fqdn_valid? ? create_fqdn : nil
    end

    def infrastructure
      @infrastructure ||= infrastructure_valid? ? create_infrastructure : nil
    end

    def infrastructure_properties
      @infrastructure_properties ||= infrastructure_properties_valid? ?
        create_infrastructure_properties : nil
    end

    def image
      @image ||= image_valid? ? @hash[:image] : nil
    end

    def full_clone
      @full_clone ||= full_clone_valid? ? @hash[:full_clone] : true
    end
    alias_method :full_clone?, :full_clone

    def interfaces
      @interfaces ||= interfaces_valid? ? create_interfaces : []
    end

    def flavor
      @flavor ||= flavor_valid? ?
        @hash[:flavor] : (infrastructure.provides?(:openstack) ? DEFAULT_OPENSTACK_FLAVOR : "")

    end

    def cores
      @cores ||= cores_valid? ? create_cores : DEFAULT_CORES
    end

    def memory
      @memory ||= memory_valid? ? create_memory : DEFAULT_MEMORY
    end

    def storage
      @storage ||= storage_valid? ? create_storage : DEFAULT_STORAGE
    end

    def timezone
      @timezone ||= timezone_valid? ? @hash[:timezone] : nil
    end

    def product_id
      @product_id ||= product_id_valid? ? @hash[:product_id] : nil
    end

    def organization_name
      @organization_name ||= organization_name_valid? ? @hash[:organization_name] : nil
    end

  protected

    attr_writer :name

  private

    def digits_valid?
      return false unless inflatable?
      return false if @hash[:digits].nil? # digits is optional
      @hash[:digits].kind_of?(Fixnum) or
        raise PlanParsingError, "Node #{@name}: 'digits' has to be a number"
      @hash[:digits] > 0 or
        raise PlanParsingError, "Node #{@name}: 'digits' has to be greater than zero"
    end

    def range_valid?
      if inflatable?
        @hash[:range] or
          raise PlanParsingError, "Node #{@name}: 'range' has to be specified if the node is inflatable"
      else
        return false # range is only needed if inflatable
      end
      @hash[:range].class == String or
        raise PlanParsingError, "Node #{@name}: 'range' has to be a string"
      range_array = @hash[:range].scan(/\d+/)
      range_array and range_array.length == 2 or
        raise PlanParsingError, "Node #{@name}: 'range' has to be a string which contains exactly two numbers"
      range_array[0] < range_array[1] or
        raise PlanParsingError, "Node #{@name}: the first number has to be smaller than the second in 'range'"
    end

    def fqdn_valid?
      nodename = @hash[:fqdn] || @name # FQDN is implicitly derived from a node name
      raise PlanParsingError, "Node #{@name}: FQDN must be a string" unless nodename.kind_of?(String)
      raise PlanParsingError, "Node #{@name}: FQDN must not exceed 255 characters" if nodename.size > 255
      # f.q.dn. is a valid FQDN
      nodename = nodename[0...-1] if nodename[-1] == '.'
      raise PlanParsingError, "Node #{@name}: FQDN has invalid format" unless
        nodename.split('.').collect do |tok|
          !tok.empty? && tok.size <= 63 && tok[0] != '-' && tok[-1] != '-' && !tok.scan(/[^a-z\d-]/i).any?
        end.all?
      true
    end

    def infrastructure_valid?
      @hash[:infrastructure].kind_of?(String) or
        raise PlanParsingError, "Node #{@name}: The 'infrastructure' pointer must be a string"
      @parsed_infrastructures.find { |i| i.name == @hash[:infrastructure] } or
        raise PlanParsingError, "Node #{@name}: No such infrastructure"
    end

    def infrastructure_properties_valid?
      raise PlanParsingError, "Node #{@name}: The 'infrastructure_properties' must be a hash" unless
        @hash[:infrastructure_properties].kind_of?(Hash)
      true
    end

    def image_valid?
      return false if infrastructure.provides?(:baremetal) && @hash[:image].nil?
      raise PlanParsingError, "Node #{@name}: The 'image' must be a string" unless @hash[:image].kind_of?(String)
      true
    end

    def full_clone_valid?
      return false if @hash[:full_clone].nil?
      raise PlanParsingError, "Node #{@node}: The 'full_clone' can be used only for OVirt/RHEVm providers" unless
        infrastructure.provides?(:ovirt)
      raise PlanParsingError, "Node #{@node}: The 'full_clone', if defined, must be true or false" unless
        @hash.has_key?(:full_clone) && (@hash[:full_clone].kind_of?(TrueClass) || @hash[:full_clone].kind_of?(FalseClass))
      true
    end

    def interfaces_valid?
      return false if @hash[:interfaces].nil? # TODO: interfaces should only be optional for baremetal
      @hash[:interfaces].kind_of?(Hash) or
        raise PlanParsingError, "Node #{@name}: The value for 'interfaces' has to be a hash"
      @hash[:interfaces].keys.all?{|i| i.kind_of?(String)} or
        raise PlanParsingError, "Node #{@name}: The keys in the 'interface' hash have to be strings"
      @hash[:interfaces].values.all?{|v| v.kind_of?(Hash)} or
        raise PlanParsingError, "Node #{@name}: The values in the 'interface' hash have to be hashes"
    end

    def flavor_valid?
      return false if @hash[:flavor].nil?
      raise PlanParsingError, "Node #{@name}: Flavor must be string" unless @hash[:flavor].kind_of?(String)
      raise PlanParsingError, "Node #{@name}: Invalid flavor" unless
        infrastructure.provides?(:openstack) || VALID_FLAVOR_TYPES.has_key?(@hash[:flavor].to_sym)
      true
    end

    def device_spec_valid?(device)
      return false if @hash[device].nil? && @hash[:flavor].nil?
      unless @hash[device].nil?
        raise PlanParsingError, "Node #{@name}: specification of '#{device.to_s}' is not allowed for OpenStack provider type" if
          infrastructure.provides?(:openstack)
        case device
        when :memory, :storage
          raise PlanParsingError, "Node #{@name}: #{device.to_s} must be a string of numbers followed by M,m,G or g character" unless
            @hash[device].kind_of?(String) && @hash[device] =~ /^\d+[GgMm]$/
        when :cores
          raise PlanParsingError, "Node #{@name}: CPU cores must be positive non-zero integer" unless
            @hash[device].kind_of?(Integer) && @hash[device] > 0
        else
          raise PlanParsingError, "Node #{name}: Invalid virtual device"
        end
      end
      true
    end

    def cores_valid?
      device_spec_valid?(:cores)
    end

    def memory_valid?
      device_spec_valid?(:memory)
    end

    def storage_valid?
      device_spec_valid?(:storage)
    end

    # TODO: Do a better format validation
    def timezone_valid?
      raise PlanParsingError, "Node #{name}: 'timezone' is a required for VSphere-based node" if
        infrastructure.provides?(:vsphere) && @hash[:timezone].nil?
      return false if @hash[:timezone].nil?
      raise PlanParsingError, "Node #{name}: 'timezone', if specified, must be a non-empty string" if
        !@hash[:timezone].kind_of?(String) || @hash[:timezone].empty?
      true
    end

    def product_id_valid?
      return false if @hash[:product_id].nil?
      raise PlanParsingError, "Node #{name}: 'product_id' must be a string" unless
        @hash[:product_id].kind_of?(String)
      true
    end

    def organization_name_valid?
      return false if @hash[:organization_name].nil?
      raise PlanParsingError, "Node #{name}: 'organization_name' must be a non-empty string" if
        !@hash[:organization_name].kind_of?(String) || @hash[:organization_name].empty?
      true
    end

    def create_fqdn
      nodename = (@hash[:fqdn] || @name)
      nodename[-1] == '.' ? nodename[0...-1] : nodename
    end

    def create_interfaces
      @hash[:interfaces].map do |interface_name, interface_hash|
        DopCommon::Interface.new(interface_name, interface_hash)
      end
    end

    def create_infrastructure
      @parsed_infrastructures.find { |i| i.name == @hash[:infrastructure] }
    end

    def create_infrastructure_properties
      DopCommon::InfrastructureProperties.new(
        @hash[:infrastructure_properties],
        infrastructure
      )
    end

    def create_cores
      return nil if infrastructure.provides?(:openstack)
      @hash[:flavor].nil? ? @hash[:cores] : VALID_FLAVOR_TYPES[flavor.to_sym][:cores]
    end

    # Expects valid input -> to be used after validation
    def to_bytes(str)
      value, unit = str.downcase.scan(/\d+|[mg]/).collect do |tok|
        case tok
        when /\d+/
          tok.to_i
        when 'm'
          1048576
        else
          1073741824
        end
      end
      value * unit
    end

    def create_memory
      return nil if infrastructure.provides?(:openstack)
      @hash[:flavor].nil? ? to_bytes(@hash[:memory]) : VALID_FLAVOR_TYPES[flavor.to_sym][:memory]
    end

    def create_storage
      return nil if infrastructure.provides?(:openstack)
      @hash[:flavor].nil? ? to_bytes(@hash[:storage]) : VALID_FLAVOR_TYPES[flavor.to_sym][:storage]
    end
  end
end
