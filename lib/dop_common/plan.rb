#
#
#
require 'yaml'

module DopCommon
  class PlanParsingError < StandardError
  end

  class Plan
    include Validator
    include SharedOptions
    include HashParser

    def initialize(hash)
      # fix hash key names (convert them to symbols)
      @hash = symbolize_keys(hash)
      @hash[:plan] = symbolize_keys(@hash[:plan]) if @hash[:plan]
    end

    def validate
      valitdate_shared_options
      log_validation_method('name_valid?')
      log_validation_method('infrastructures_valid?')
      log_validation_method('nodes_valid?')
      log_validation_method('steps_valid?')
      log_validation_method('configuration_valid?')
      log_validation_method('credentials_valid?')
      try_validate_obj("Plan: Can't validate the infrastructures part because of a previous error"){infrastructures}
      try_validate_obj("Plan: Can't validate the nodes part because of a previous error"){nodes}
      try_validate_obj("Plan: Can't validate the steps part because of a previous error"){steps}
      try_validate_obj("Plan: Can't validate the credentials part because of a previous error"){credentials}
    end

    def name
      @name ||= name_valid? ?
        @hash[:name] : Digest::SHA2.hexdigest(@hash.to_s)
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
        create_steps : []
    end

    def configuration
      @configuration ||= configuration_valid? ?
        DopCommon::Configuration.new(@hash[:configuration]) :
        DopCommon::Configuration.new({})
    end

    def credentials
      @credentials ||= credentials_valid? ?
        create_credentials : {}
    end

    def find_node(name)
      nodes.find{|node| node.name == name}
    end

  private

    def name_valid?
      return false if @hash[:name].nil?
      @hash[:name].kind_of?(String) or
        raise PlanParsingError, 'The plan name has to be a String'
      @hash[:name][/^[\w-]+$/,0] or
        raise PlanParsingError, 'The plan name may only contain letters, numbers and underscores'
      !@hash[:name][/_plan$/,0] or
        raise PlanParsingError, 'The plan name can not end in _plan. This is used internally.'
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
        ::DopCommon::Node.new(name.to_s, hash.merge(:infrastructures => infrastructures))
      end
    end

    def inflate_nodes
      parsed_nodes.map do |node|
        node.inflatable? ? node.inflate : node
      end.flatten
    end

    def steps_valid?
      return false if @hash[:steps].nil? ## steps can be nil for DOPv only plans
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
        raise PlanParsingError, "Plan: 'configuration' key has not a hash as value"
    end

    def credentials_valid?
      return false if @hash[:credentials].nil? # credentials hash is optional
      @hash[:credentials].kind_of? Hash or
        raise PlanParsingError, "Plan: 'credentials' key has not a hash as value"
      @hash[:credentials].keys.all?{|k| k.kind_of?(String) or k.kind_of?(Symbol)} or
        raise PlanParsingError, "Plan: all keys in the 'credentials' hash have to be strings or symbols"
      @hash[:credentials].values.all?{|v| v.kind_of?(Hash)} or
        raise PlanParsingError, "Plan: all values in the 'credentials' hash have to be hashes"
    end

    def create_credentials
      Hash[@hash[:credentials].map do |name, hash|
        [name, ::DopCommon::Credential.new(name, hash)]
      end]
    end

  end
end
