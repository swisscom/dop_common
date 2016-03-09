#
# DOP Common infrastructure hash parser
#

module DopCommon
  class Network
    include Validator
    include HashParser

    attr_reader :name

    def initialize(name, hash)
      @name = name
      @hash = deep_symbolize_keys(hash)
    end

    def validate
      log_validation_method(:ip_pool_valid?)
      log_validation_method(:ip_defgw_valid?)
      log_validation_method(:ip_netmask_valid?)
    end

    def ip_netmask
      @ip_netmask ||= ip_netmask_valid? ? IPAddr.new(@hash[:ip_netmask]) : nil
    end

    def ip_defgw
      @ip_defgw ||= ip_defgw_valid? ? IPAddr.new(@hash[:ip_defgw]) : nil
    end

    def ip_pool
      @ip_pool ||= ip_pool_valid? ? create_ip_pool : {}
    end

    private

    def ip_netmask_valid?
      return false if @hash.empty?
      IPAddr.new(@hash[:ip_netmask])
      true
    rescue ArgumentError
      raise PlanParsingError, "Network #{@name}: Invalid network mask definition"
    end

    def ip_defgw_valid?
      return false if @hash.empty?
      IPAddr.new(@hash[:ip_defgw])
      true
    rescue ArgumentError
      raise PlanParsingError, "Network #{@name}: Invalid default gateway definition"
    end

    def ip_pool_valid?
      return false if @hash.empty? # An empty network specification is valid
      # It must be a hash with from and to keys if defined
      raise PlanParsingError, "Network #{@name}: An IP pool must be a hash with 'from' and 'to' keys" unless
        @hash[:ip_pool].kind_of?(Hash) and
        @hash[:ip_pool].has_key?(:from) and
        @hash[:ip_pool].has_key?(:to)
      # The IP defined by from must be lower than the IP defined by to keyword
      ip_from = IPAddr.new(@hash[:ip_pool][:from])
      ip_to   = IPAddr.new(@hash[:ip_pool][:to])
      raise PlanParsingError, "Network #{@name}: The IP defined by 'from' must to be lower than the IP defined by in 'to'" unless ip_from < ip_to
      # The IP of default gateway must be out of IP pool range
      raise PlanParsingError, "Network #{@name}: The default gateway must be out of IP pool range" unless ip_defgw < ip_from || ip_defgw > ip_to
      # IPs specified by IP pool and the default gateway must belong to the same network
      net = ip_defgw.mask(ip_netmask.to_s)
      raise PlanParsingError, "Network #{@name}: IPs specified by IP pool and the default gateway must belong to the same network" unless
        net.include?(ip_from) && net.include?(ip_to)
      true
    rescue ArgumentError
      # Invalide IP/Netmasl definition
      raise PlanParsingError, "Network #{@name}: Invalid IP and/or netmask definition"
    end

    def create_ip_pool
      Hash[@hash[:ip_pool].collect { |k,v| [k.to_sym, IPAddr.new(v)] }]
    end
  end
end
