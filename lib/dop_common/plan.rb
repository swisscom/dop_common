#
#
#
require 'yaml'

module DopCommon
  class PlanParsingError < StandardError
  end

  class Plan
    include Validator

    DEFAULT_MAX_IN_FLIGHT = 3

    def initialize(hash)
      @hash = Hash[hash.map{|k,v| [k.to_sym, v]}]
    end

    def validate
      log_validation_method('max_in_flight_valid?')
      log_validation_method('infrastructure_valid?')
      log_validation_method('nodes_valid?')
      log_validation_method('steps_valid?')
      log_validation_method('configuration_valid?')
      try_validate_obj("Plan: Can't validate the infrastructure part because of a previous error"){infrastructure}
      try_validate_obj("Plan: Can't validate the nodes part because of a previous error"){nodes}
      try_validate_obj("Plan: Can't validate the steps part because of a previous error"){steps}
    end

    def max_in_flight
      @max_in_flight ||= max_in_flight_valid? ?
        @hash[:max_in_flight] : DEFAULT_MAX_IN_FLIGHT
    end

    def infrastructure
      @infrastructure ||= infrastructure_valid? ?
        create_infrastructure : nil
    end

    def nodes
      @nodes ||= nodes_valid? ?
        inflate_nodes : nil
    end

    def steps
      @steps ||= steps_valid? ?
        create_steps : nil
    end

    def configuration
      @configuration ||= configuration_valid? ?
        DopCommon::Configuration.new(@hash[:configuration]) :
        DopCommon::Configuration.new({})
    end

    def find_node(name)
      nodes.find{|node| node.name == name}
    end

  private

    def max_in_flight_valid?
      return false if @hash[:max_in_flight].nil? # max_in_flight is optional
      @hash[:max_in_flight].kind_of?(Fixnum) or
        raise PlanParsingError, 'Plan: max_in_flight has to be a number'
      @hash[:max_in_flight] > 0 or
        raise PlanParsingError, 'Plan: max_in_flight has to be greater than one'
    end

    def infrastructure_valid?
      @hash[:infrastructure] or
        raise PlanParsingError, 'Plan: infrastructure hash is missing'
      @hash[:infrastructure].kind_of?(Hash) or
        raise PlanParsingError, 'Plan: infrastructure key has not a hash as value'
      @hash[:infrastructure].any? or
        raise PlanParsingError, 'Plan: infrastructure hash is empty'
    end

    def create_infrastructure
      @hash[:infrastructure].map do |name, hash|
        ::DopCommon::Infrastructure.new(name, hash)
      end
    end

    def nodes_valid?
      @hash[:nodes] or
        raise PlanParsingError, 'Plan: nodes hash is missing'
      @hash[:nodes].kind_of?(Hash) or
        raise PlanParsingError, 'Plan: nodes key has not a hash as value'
      @hash[:nodes].any? or
        raise PlanParsingError, 'Plan: nodes hash is empty'
    end

    def parsed_nodes
      @parsed_nodes ||= @hash[:nodes].map do |name, hash|
        ::DopCommon::Node.new(name.to_s, hash)
      end
    end

    def inflate_nodes
      parsed_nodes.map do |node|
        node.inflatable? ? node.inflate : node
      end.flatten
    end

    def steps_valid?
      @hash[:steps] or
        raise PlanParsingError, 'Plan: steps hash is missing'
      @hash[:steps].kind_of? Array or
        raise PlanParsingError, 'Plan: steps key has not a array as value'
      @hash[:steps].any? or
        raise PlanParsingError, 'Plan: steps hash is empty'
    end

    def create_steps
      @hash[:steps].map do |hash|
        ::DopCommon::Step.new(hash)
      end
    end

    def configuration_valid?
      return false if @hash[:configuration].nil? # configuration hash is optional
      @hash[:configuration].kind_of? Hash or
        raise PlanParsingError, 'Plan: configuration key has not a hash as value'
    end

  end
end
