#
# Parsing of values that can be set on multiple levels
#
require 'yaml'

module DopCommon
  module RunOptions
    include Validator

    def valitdate_shared_options
      log_validation_method('max_in_flight_valid?')
      log_validation_method('max_per_role_valid?')
      log_validation_method('canary_host_valid?')
    end

    def max_in_flight
      @max_in_flight ||= max_in_flight_valid? ?
        @hash[:max_in_flight] : nil
    end

    def max_per_role
      @max_per_role ||= max_per_role_valid? ?
        @hash[:max_per_role] : nil
    end

    def canary_host
      @canary_host ||= canary_host_valid? ?
        @hash[:canary_host] : false
    end

  private

    def max_in_flight_valid?
      return false if @hash[:max_in_flight].nil? # max_in_flight is optional
      @hash[:max_in_flight].kind_of?(Fixnum) or
        raise PlanParsingError, 'Plan: max_in_flight has to be a number'
      @hash[:max_in_flight] >= -1 or
        raise PlanParsingError, 'Plan: max_in_flight has to be greater than -1'
    end

    def max_per_role_valid?
      return false if @hash[:max_per_role].nil? # max_per_role is optional
      @hash[:max_per_role].kind_of?(Fixnum) or
        raise PlanParsingError, 'Plan: max_per_role has to be a number'
      @hash[:max_per_role] > 0 or
        raise PlanParsingError, 'Plan: max_per_role has to be greater than 0'
    end

    def canary_host_valid?
      return false if @hash[:canary_host].nil?
      @hash[:canary_host].kind_of?(TrueClass) or @hash[:canary_host].kind_of?(FalseClass) or
        raise PlanParsingError, "Step #{@name}: The value for canary_host must be boolean"
    end

  end
end
