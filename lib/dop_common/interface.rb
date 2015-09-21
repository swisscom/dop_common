#
# DOP Common configuration lookup
#
require 'ipaddr'

module DopCommon
  class Interface
    include Validator

    attr_reader :name

    def initialize(name, hash)
      @name = name
      @hash = Hash[hash.map{|k,v| [k.to_sym, v]}]
    end

    def validate
      log_validation_method('ip_valid?')
    end

    def ip
      @ip ||= ip_valid? ? @hash[:ip] : nil
    end

  private

    def ip_valid?
      @hash[:ip].kind_of?(String) or @hash[:ip].kind_of?(Symbol) or
        raise PlanParsingError, "Interface #{@name}: 'ip' has to be specified as a valid IP String or :dhcp"
      case @hash[:ip]
      when :dhcp, 'dhcp' then @hash[:ip] = :dhcp
      when :none, 'none' then @hash[:ip] = :none
      else IPAddr.new(@hash[:ip])
      end
    rescue ArgumentError => e
        raise PlanParsingError, "Interface #{@name}: the specified ip is not valid"
    end

  end
end
