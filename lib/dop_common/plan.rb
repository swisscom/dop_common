#
#
#
require 'yaml'

module DopCommon
  class PlanParsingError < StandardError
  end

  class Plan

    DEFAULT_MAX_IN_FLIGHT = 3

    def initialize(hash)
      @hash = hash
    end

    def max_in_flight
      @max_in_flight ||= max_in_flight_valid? ?
        @hash[:max_in_flight] : DEFAULT_MAX_IN_FLIGHT
    end

    def infrastructures
      @infrastructures ||= infrastructures_valid? ?
        create_infrastructures : nil
    end

    def nodes
      @nodes ||= nodes_valid? ?
        create_nodes : nil
    end

    def steps
      @steps ||= steps_valid? ?
        create_steps : nil
    end

  private

    def max_in_flight_valid?
      return false if @hash[:max_in_flight].nil? # max_in_flight is optional
      @hash[:max_in_flight].class == Fixnum or
        raise PlanParsingError, 'Plan: max_in_flight has to be a number'
      @hash[:max_in_flight] > 0 or
        raise PlanParsingError, 'Plan: max_in_flight has to be greater than one'
    end

    def infrastructures_valid?
      @hash[:infrastructures] or
        raise PlanParsingError, 'Plan: infrastructures hash is missing'
      @hash[:infrastructures].class == Hash or
        raise PlanParsingError, 'Plan: infrastructures key has not a hash as value'
      @hash[:infrastructures].any? or
        raise PlanParsingError, 'Plan: infrastructures hash is empty'
    end

    def create_infrastructures
      @hash[:infrastructures].map do |name, hash|
        ::DopCommon::Infrastructure.new(name, hash)
      end
    end

    def nodes_valid?
      @hash[:nodes] or
        raise PlanParsingError, 'Plan: nodes hash is missing'
      @hash[:nodes].class == Hash or
        raise PlanParsingError, 'Plan: nodes key has not a hash as value'
      @hash[:nodes].any? or
        raise PlanParsingError, 'Plan: nodes hash is empty'
    end

    def create_nodes
      @hash[:nodes].map do |name, hash|
        ::DopCommon::Node.new(name, hash)
      end
    end

    def steps_valid?
      @hash[:steps] or
        raise PlanParsingError, 'Plan: steps hash is missing'
      @hash[:steps].class == Hash or
        raise PlanParsingError, 'Plan: steps key has not a hash as value'
      @hash[:steps].any? or
        raise PlanParsingError, 'Plan: steps hash is empty'
    end

    def create_steps
      @hash[:steps].map do |name, hash|
        ::DopCommon::Step.new(name, hash)
      end
    end


  end
end
