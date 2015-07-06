#
# Parsing of values that can be set on multiple levels
#
require 'yaml'

module DopCommon
  module SharedOptions
    include Validator

    def valitdate_shared_options
      log_validation_method('max_in_flight_valid?')
      log_validation_method('ssh_root_pass_valid?')
      log_validation_method('canary_host_valid?')
    end

    def max_in_flight
      @max_in_flight ||= max_in_flight_valid? ?
        @hash[:max_in_flight] : nil
    end

    def ssh_root_pass
      @ssh_root_pass ||= ssh_root_pass_valid? ?
        @hash[:ssh_root_pass] : nil
    end

    def canary_host
      @canary_host ||= canary_host_valid? ?
        @hash[:canary_host] : false
    end

  private

    def max_in_flight_valid?
      ### START DEPRICATED KEY PARSING plan => max_in_flight
      if @hash[:max_in_flight].nil?
        return false if @hash[:plan].nil? # plan hash is optional
        return false if @hash[:plan][:max_in_flight].nil? # max_in_flight is optional
        @hash[:max_in_flight] = @hash[:plan][:max_in_flight]
        DopCommon.log.warn('The max_in_flight key under "plan" in depricated. Please set max_in_flight as a global key')
      end
      ### END DEPRICATED KEY PARSING
      return false if @hash[:max_in_flight].nil? # max_in_flight is optional
      @hash[:max_in_flight].kind_of?(Fixnum) or
        raise PlanParsingError, 'Plan: max_in_flight has to be a number'
      @hash[:max_in_flight] >= -1 or
        raise PlanParsingError, 'Plan: max_in_flight has to be greater than -1'
    end

    def ssh_root_pass_valid?
      ### START DEPRICATED KEY PARSING plan => max_root_pass
      if @hash[:ssh_root_pass].nil? # ssh_root_pass is optional
        return false if @hash[:plan].nil? # plan hash is optional
        return false if @hash[:plan][:ssh_root_pass].nil? # ssh_root_pass is optional
        @hash[:ssh_root_pass] = @hash[:plan][:ssh_root_pass]
        DopCommon.log.warn('The ssh_root_pass key under "plan" in depricated. Please set ssh_root_pass as a global key')
      end
      ### END DEPRICATED KEY PARSING
      return false if @hash[:ssh_root_pass].nil? # ssh_root_pass is optional
      @hash[:ssh_root_pass].kind_of?(String) or
        raise PlanParsingError, 'Plan: ssh_root_pass has to be a string'
    end

    def canary_host_valid?
      return false if @hash[:canary_host].nil?
      @hash[:canary_host].kind_of?(TrueClass) or @hash[:canary_host].kind_of?(FalseClass) or
        raise PlanParsingError, "Step #{@name}: The value for canary_host must be boolean"
    end

  end
end
