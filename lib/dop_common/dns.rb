require 'ipaddr'

module DopCommon
  class DNS
    include Validator
    include HashParser

    def initialize(hash)
      @hash = (symbolize_keys(hash) || {}) # DNS is optional.
    end

    def validate
      log_validation_method(:name_servers_valid?)
      log_validation_method(:search_domains_valid?)
    end

    def name_servers
      @name_servers ||= name_servers_valid? ? @hash[:name_servers] : []
    end

    def search_domains
      @search_domains ||= search_domains_valid? ? @hash[:search_domains] : []
    end

    private

    def name_servers_valid?
      return false unless @hash.has_key?(:name_servers)
      raise PlanParsingError, "DNS: name_servers must be an array of IP addresses" if
        !@hash[:name_servers].kind_of?(Array) || @hash[:name_servers].empty?
      @hash[:name_servers].each do |n|
        begin
          IPAddr.new(n)
        rescue
          raise PlanParsingError, "DNS: name_servers entry '#{n}' is not a valid IP address"
        end
      end
      true
    end

    def search_domains_valid?
      regex = /((^[a-z0-9]+(-[a-z0-9]+)*){1,63}$)|(^((?=[a-z0-9-]{1,63}\.)[a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,63}$)/
      return false unless @hash.has_key?(:search_domains)
      raise PlanParsingError, "DNS: search_domains must be an array of search domains" if
        !@hash[:search_domains].kind_of?(Array) || @hash[:search_domains].empty?
      raise PlanParsingError, "DNS: search_domains entries must be strings" unless
        @hash[:search_domains].all? { |d| d.kind_of?(String) }
      @hash[:search_domains].each do |d|
        raise PlanParsingError, "DNS: search_domain entry '#{d}' is not a valid domain name" unless
          d =~ regex
      end
      true
    end
  end
end
