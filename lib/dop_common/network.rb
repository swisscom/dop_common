#
# DOP Common infrastructure hash parser
#

module DopCommon
  class Network
    include Validator
    include HashParser

    def initialize(name, hash)
      @name = name
      @hash = deep_symbolize_keys(hash)
    end

    def validate
      log_validation_method(:ip_pool_valid?)
      log_validation_method(:ip_netmask_valid?)
      log_validation_method(:ip_defgw_valid?)
    end

    def ip_netmask
      @ip_netmask ||= ip_netmask_valid? ? IPAddr.new(@hash[:ip_netmask]) : nil
    end
    
    def ip_defgw
      @ip_defgw ||= ip_defgw_valid? ? IPAddr.new(@hash[:ip_defgw]) : nil
    end
    
    def ip_pool
      @ip_pool ||= ip_pool_valid? ? create_ip_pool : nil
    end

    private

    def ip_netmask_valid?
      IPAddr.new(@hash[:ip_netmask])
      true
    rescue ArgumentError => e
      raise "Network #{@name}: Invalid network mask definition"
    end
    
    def ip_defgw_valid?
      IPAddr.new(@hash[:ip_defgw])
      true
    rescue ArgumentError => e
      raise "Network #{@name}: Invalid default gateway definition"
    end

    def ip_pool_valid?
      return false if @hash.nil?
      return false if @hash[:ip_pool].nil?
      @hash[:ip_pool].has_key?(:from) and @hash[:ip_pool].has_key?(:to) or
        raise PlanParsingError, "Network #{@name}: 'from' and 'to' entries must be specified for an IP pool"
      ip_from = IPAddr.new(@hash[:ip_pool][:from])
      ip_to   = IPAddr.new(@hash[:ip_pool][:to])
      ip_from < ip_to or
        raise PlanParsingError, "Network #{@name}: The IP defined in 'from' field has to be lower than the IP specified in 'to' field"
      ip_defgw < ip_from or ip_defgw > ip_to or
        raise PlanParsingError, "Network #{@name}: The default gateway must lie outside of the IP range specified by 'to' and 'from' fields"
      
      net = ip_defgw.mask(ip_netmask.to_s)
      net.include?(ip_from) and net.include?(ip_to) or
        raise PlanParsingError, "Network #{@name}: All IPs specified by IP pool and the default gateway must belong to the same network"

    rescue ArgumentError => e
      raise PlanParsingError, "Network #{@name}: Invalid network specification"
    end

    def create_ip_pool
      Hash[@hash[:ip_pool].map { |k,v| [k.to_sym, IPAddr.new(v)] }]
    end
  end
end
