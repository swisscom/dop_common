#
# DOP common node hash parser
#
require 'dop_common/node/config'

module DopCommon
  class Node
    include Validator
    include HashParser
    include Utils
    include Node::Config

    attr_reader :name
    alias_method :nodename, :name

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
      @parsed_credentials     = parent[:parsed_credentials]
      @parsed_hooks           = parent[:parsed_hooks]
      @parsed_configuration   = parent[:parsed_configuration]
    end

    def validate
      log_validation_method('digits_valid?')
      log_validation_method('range_valid?')
      log_validation_method('fqdn_valid?')
      log_validation_method('infrastructure_valid?')
      log_validation_method('infrastructure_properties_valid?')
      log_validation_method('image_valid?')
      log_validation_method('full_clone_valid?')
      log_validation_method('thin_clone_valid?')
      log_validation_method('interfaces_valid?')
      log_validation_method('flavor_valid?')
      log_validation_method('cores_valid?')
      log_validation_method('memory_valid?')
      log_validation_method('storage_valid?')
      log_validation_method('timezone_valid?')
      log_validation_method('product_id_valid?')
      log_validation_method('organization_name_valid?')
      log_validation_method('credentials_valid?')
      log_validation_method('dns_valid?')
      log_validation_method('data_disks_valid?')
      log_validation_method('tags_valid?')
      log_validation_method('force_stop_valid?')
      try_validate_obj("Node #{@name}: Can't validate the interfaces part because of a previous error"){interfaces}
      try_validate_obj("Node #{@name}: Can't validate the infrastructure_properties part because of a previous error"){infrastructure_properties}
      try_validate_obj("Node #{@name}: Can't validate the dns part because of a previous error"){dns}
      try_validate_obj("Node #{@name}: Can't validate data_disks part because of a previous error"){data_disks}
      # Memory and storage may be to nil.
      try_validate_obj("Node #{@name}: Can't validate the memory part because of a previous error"){memory} unless @hash[:memory].nil?
      try_validate_obj("Node #{@name}: Can't validate storage part because of a previous error"){storage} unless @hash[:storage].nil?
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

    def hostname
      @hostname ||= fqdn.split('.').first
    end

    def domainname
      @domainname ||= fqdn.split('.', 2).last
    end

    def infrastructure
      @infrastructure ||= infrastructure_valid? ? create_infrastructure : nil
    end

    def infrastructure_properties
      @infrastructure_properties ||= infrastructure_properties_valid? ?
        create_infrastructure_properties : {}
    end

    def image
      @image ||= image_valid? ? @hash[:image] : nil
    end

    def full_clone?
      @full_clone ||= full_clone_valid? ? @hash[:full_clone] : true
    end
    alias_method :full_clone, :full_clone?

    def thin_clone?
      @thin_clone ||= thin_clone_valid? ? @hash[:thin_clone] : nil
    end
    alias_method :thin_clone, :thin_clone?

    def interfaces
      @interfaces ||= interfaces_valid? ? create_interfaces : []
    end

    def flavor
      @flavor ||= flavor_valid? ? create_flavor : nil
    end

    def cores
      @cores ||= cores_valid? ? create_cores : nil
    end

    def memory
      @memory ||= memory_valid? ? create_memory : nil
    end

    def storage
      @storage ||= storage_valid? ? create_storage : nil
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

    def credentials
      @credentials ||= credentials_valid? ? create_credentials : []
    end

    def dns
      @dns ||= dns_valid? ? create_dns : nil
    end

    def data_disks
      @data_disks ||= data_disks_valid? ? create_data_disks : []
    end

    def hooks
      @parsed_hooks
    end

    def tags
      @tags ||= tags_valid? ? create_tags : nil
    end

    def force_stop?
      @force_stop ||= force_stop_valid? ? @hash[:force_stop] : false
    end
    alias_method :force_stop, :force_stop?

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
      return false unless @hash.has_key?(:infrastructure_properties)
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

    def thin_clone_valid?
      return false if @hash[:thin_clone].nil?
      raise PlanParsingError, "Node #{@node}: The 'thin_clone' can be used only for VSphere provider" unless
        (infrastructure.provides?(:vsphere) || infrastructure.provides?(:vmware))
      raise PlanParsingError, "Node #{@node}: The 'thin_clone', if defined, must be true or false" unless
        @hash.has_key?(:thin_clone) && (@hash[:thin_clone].kind_of?(TrueClass) || @hash[:thin_clone].kind_of?(FalseClass))
      true
    end

    def interfaces_valid?
      return false if @hash[:interfaces].nil?
      @hash[:interfaces].kind_of?(Hash) or
        raise PlanParsingError, "Node #{@name}: The value of 'interfaces' has to be a hash"
      @hash[:interfaces].keys.all?{|i| i.kind_of?(String)} or
        raise PlanParsingError, "Node #{@name}: The keys in the 'interface' hash have to be strings"
      @hash[:interfaces].values.all?{|v| v.kind_of?(Hash)} or
        raise PlanParsingError, "Node #{@name}: The values in the 'interface' hash have to be hashes"
      true
    end

    def flavor_valid?
      raise PlanParsingError, "Node #{@name}: flavor is mutually exclusive with any of cores, memory and storage" if
        @hash.has_key?(:flavor) && @hash.keys.any? { |k| [:cores, :memory, :storage].include?(k) }
      raise PlanParsingError, "Node #{@name}: flavor must be a string" if
        @hash.has_key?(:flavor) && !@hash[:flavor].kind_of?(String)
      return true if infrastructure.provides?(:openstack)
      raise PlanParsingError, "Node #{@name}: Invalid flavor '#{@hash[:flavor]}'" if
        !@hash[:flavor].nil? && !VALID_FLAVOR_TYPES.has_key?(@hash[:flavor].to_sym)
      false
    end

    def cores_valid?
      if infrastructure.provides?(:openstack)
        raise PlanParsingError, "Node #{@name}: cores can't be specified if openstack is a provider" if
          @hash.has_key?(:cores)
        return false
      end
      raise PlanParsingError, "Node #{@name}: cores must be a non-zero positive number" if
        @hash.has_key?(:cores) && !(@hash[:cores].kind_of?(Fixnum) && @hash[:cores] > 0)
      true
    end

    def memory_valid?
      if infrastructure.provides?(:openstack)
        raise PlanParsingError, "Node #{@name}: memory can't be specified if openstack is a provider" if
          @hash.has_key?(:memory)
        return false
      end
      true
    end

    def storage_valid?
      if infrastructure.provides?(:openstack)
        raise PlanParsingError, "Node #{@name}: storage can't be specified if openstack is a provider" if
          @hash.has_key?(:storage)
        return false
      end
      true
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

    def credentials_valid?
      return false if @hash[:credentials].nil?
      [String, Symbol, Array].include?(@hash[:credentials].class) or
        raise PlanParsingError, "Node #{name}: 'credentials' has to be a string, symbol or array"
      [@hash[:credentials]].flatten.each do |credential|
        [String, Symbol].include?(credential.class) or
          raise PlanParsingError, "Node #{name}: the 'credentials' array should only contain strings, symbols"
        @parsed_credentials.keys.include?(credential) or
          raise PlanParsingError, "Node #{name}: the credential #{credential.to_s} in 'credentials' does not exist"
        real_credential = @parsed_credentials[credential]
        case real_credential.type
        when :ssh_key
          real_credential.public_key or
            raise PlanParsingError, "Node #{name}: the ssh_key credential #{credential.to_s} in 'credentials' requires a public key"
        end
      end
    end

    def dns_valid?
      raise PlanParsingError, "Node #{@name}: The 'dns', if specified, must be a hash" if
        @hash.has_key?(:dns) && !@hash[:dns].kind_of?(Hash)
      true
    end

    def data_disks_valid?
      return false unless @hash.has_key?(:disks)
      raise PlanParsingError, "Node #{@name}: The 'disks', if specified, must be a hash" unless
        @hash[:disks].kind_of?(Hash)
      raise PlanParsingError, "Node #{@name}: Each value of 'disks' must be a hash" unless
        @hash[:disks].values.all? { |d| d.kind_of?(Hash) }
      true
    end

    def create_fqdn
      node_name = (@hash[:fqdn] || @name)
      node_name[-1] == '.'[0] ? node_name[0...-1] : node_name
    end

    def create_interfaces
      @hash[:interfaces].map do |interface_name, interface_hash|
        DopCommon::Interface.new(
          interface_name,
          interface_hash,
          :parsed_networks => infrastructure.networks
        )
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

    def create_flavor
      @hash[:flavor].nil? ? DEFAULT_OPENSTACK_FLAVOR : @hash[:flavor]
    end

    def create_cores
      @hash.has_key?(:cores) ? @hash[:cores] : @hash.has_key?(:flavor) ?
        VALID_FLAVOR_TYPES[@hash[:flavor].to_sym][:cores] : DEFAULT_CORES
    end

    def create_memory
      DopCommon::Utils::DataSize.new(
        @hash.has_key?(:memory) ? @hash[:memory] : @hash.has_key?(:flavor) ?
          VALID_FLAVOR_TYPES[@hash[:flavor].to_sym][:memory] : DEFAULT_MEMORY
      )
    end

    def create_storage
      DopCommon::Utils::DataSize.new(
        @hash.has_key?(:storage) ? @hash[:storage] : @hash.has_key?(:flavor) ?
          VALID_FLAVOR_TYPES[@hash[:flavor].to_sym][:storage] : DEFAULT_STORAGE
      )
    end

    def create_credentials
      [@hash[:credentials]].flatten.map do |credential|
        @parsed_credentials[credential]
      end
    end

    def create_dns
      DopCommon::DNS.new(@hash[:dns])
    end

    def create_data_disks
      @hash[:disks].map do |disk_name, disk_hash|
        DopCommon::DataDisk.new(
          disk_name,
          disk_hash,
          :parsed_infrastructure => infrastructure,
          :parsed_infrastructure_properties => infrastructure_properties
        )
      end
    end

    def tags_valid?
      return false if @hash[:tags].nil?
      raise PlanParsingError, "Node #{@node}: The 'thin_clone' can be used only for VSphere provider" unless
          (infrastructure.provides?(:vsphere) || infrastructure.provides?(:vmware))
      [String, Symbol, Array].include?(@hash[:tags].class) or
          raise PlanParsingError, "Node #{name}: 'tags' has to be a string, symbol or array"
      [@hash[:tags]].flatten.each do |tag|
        [String, Symbol].include?(tag.class) or
            raise PlanParsingError, "Node #{name}: the 'tags' array should only contain strings, symbols"
      end
    end

    def create_tags
      [@hash[:tags]].flatten.map do |tag|
        tag.to_s
      end
    end

    def force_stop_valid?
      return false if @hash[:force_stop].nil?
      raise PlanParsingError, "Node #{@node}: The 'force_stop', if defined, must be true or false" unless
          @hash.has_key?(:force_stop) && (@hash[:force_stop].kind_of?(TrueClass) || @hash[:force_stop].kind_of?(FalseClass))
      true
    end
  end
end
