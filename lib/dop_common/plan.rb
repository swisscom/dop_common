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
      # fix hash key names (convert them to symbols)
      @hash = Hash[hash.map{|k,v| [k.to_sym, v]}]
      @hash[:plan] = Hash[@hash[:plan].map{|k,v| [k.to_sym, v]}] if @hash[:plan]
    end

    def validate
      log_validation_method('max_in_flight_valid?')
      log_validation_method('ssh_root_pass_valid?')
      log_validation_method('infrastructures_valid?')
      log_validation_method('nodes_valid?')
      log_validation_method('steps_valid?')
      log_validation_method('configuration_valid?')
      try_validate_obj("Plan: Can't validate the infrastructures part because of a previous error"){infrastructures}
      try_validate_obj("Plan: Can't validate the nodes part because of a previous error"){nodes}
      try_validate_obj("Plan: Can't validate the steps part because of a previous error"){steps}
    end

    def name
      @name ||= name_valid? ?
        @hash[:name] : Digest::SHA2.hexdigest(@hash.to_s)
    end

    def max_in_flight
      @max_in_flight ||= max_in_flight_valid? ?
        @hash[:max_in_flight] : DEFAULT_MAX_IN_FLIGHT
    end

    def ssh_root_pass
      @ssh_root_pass ||= ssh_root_pass_valid? ?
        @hash[:ssh_root_pass] : nil
    end

    def infrastructures
      @infrastructures ||= infrastructures_valid? ?
        create_infrastructures : nil
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

    def name_valid?
      return false if @hash[:name].nil?
      @hash[:name].kind_of?(String) or
        raise PlanParsingError, 'The plan name has to be a String'
      @hash[:name][/^\w+$/,0] or
        raise PlanParsingError, 'The plan name may only contain letters, numbers and underscores'
    end

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

    def infrastructures_valid?
      @hash[:infrastructures] or
        raise PlanParsingError, 'Plan: infrastructures hash is missing'
      @hash[:infrastructures].kind_of?(Hash) or
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
