#
# DOP Common configuration lookup
#
require 'ipaddr'

module DopCommon
  class Interface
    include Validator
    include HashParser

    attr_reader :name

    def initialize(name, hash, parent={})
      @name = name
      @hash = symbolize_keys(hash)
      @parsed_networks = parent[:parsed_networks]
    end

    def validate
      log_validation_method('network_valid?')
      log_validation_method('ip_valid?')
      log_validation_method('set_gateway_valid?')
      log_validation_method('virtual_switch_valid?')
      log_validation_method('floating_network_valid?')
    end

    def network
      @network ||= network_valid? ? network_obj.name : nil
    end

    def ip
      @ip ||= ip_valid? ? @hash[:ip] : nil
    end

    def netmask
      @netmask ||= network_obj.ip_netmask.to_s
    end

    def set_gateway?
      @set_gateway ||= set_gateway_valid? ? (gateway == false ? false : @hash[:set_gateway]) : true
    end
    alias_method :set_gateway, :set_gateway?

    def gateway
      @gateway ||= false == network_obj.ip_defgw ? false : network_obj.ip_defgw.to_s
    end

    def virtual_switch
      @virtual_switch ||= virtual_switch_valid? ? @hash[:virtual_switch] : nil
    end

    def floating_network
      @floating_network ||= floating_network_valid? ? @hash[:floating_network] : nil
    end

  private
    def network_valid?
      raise PlanParsingError, "Interface #{@name}: 'network' must be specified" if
        @hash[:network].nil?
      raise PlanParsingError, "Interface #{@name}: 'network' must be a non-empty string" if
        !@hash[:network].kind_of?(String) || @hash[:network].empty?
      raise PlanParsingError, "Interface #{@name}: no such network definition '#{@hash[:network]}'" unless
      network_obj
      true
    end

    def ip_valid?
      raise PlanParsingError, "Interface #{@name}: 'ip' must be a string or symbol" unless
        [String, Symbol].include?(@hash[:ip].class)
      case @hash[:ip]
      when :dhcp, 'dhcp'
        @hash[:ip] = :dhcp
      when :none, 'none'
        @hash[:ip] = :none
      else
        ip_addr = IPAddr.new(@hash[:ip])
        raise PlanParsingError, "Interface #{name}: IP address '#{@hash[:ip]}' " \
          "is outside of '#{network_obj.ip_pool[:from]} - #{network_obj.ip_pool[:to]}' range" if
          ip_addr < network_obj.ip_pool[:from] || ip_addr > network_obj.ip_pool[:to]
      end
      true
    rescue ArgumentError
        raise PlanParsingError, "Interface #{@name}: the specified IP is not valid"
    end

    def set_gateway_valid?
      return (gateway == false ? true : false) if @hash[:set_gateway].nil?
      raise PlanParsingError, "Interface #{@name}: The 'set_gateway', must be true or false" unless
        [TrueClass, FalseClass].include?(@hash[:set_gateway].class)
      raise PlanParsingError, "Interface #{@name}: No gateway specified for network '#{network}'" if
        gateway == false && @hash[:set_gateway] == true
      true
    end

    def virtual_switch_valid?
      return false if @hash[:virtual_switch].nil?
      raise PlanParsingError, "Interface #{@name}: The 'virtual_switch' must be a non-empty string" if
        !@hash[:virtual_switch].kind_of?(String) || @hash[:virtual_switch].empty?
      true
    end

    def floating_network_valid?
      return false if @hash[:floating_network].nil?
      raise PlanParsingError, "Interface #{@name}: the floating network must be a non-empty string" if
        !@hash[:floating_network].kind_of?(String) || @hash[:floating_network].empty?
      IPAddr.new(@hash[:floating_network])
      true
    rescue ArgumentError
      raise PlanParsingError, "Interface #{@name}: the specified floating network is not valid"
    end

    def network_obj
      @network_obj ||= @parsed_networks.find { |n| n.name == @hash[:network] }
    end
  end
end
