#
# DOP common step hash parser
#

module DopCommon
  class Step
    include Validator

    def initialize(hash)
      @hash = Hash[hash.map{|k,v| [k.to_sym, v]}]
    end

    def name
      @name ||= @hash[:name] or
        raise PlanParsingError, "Every step needs to have a 'name' key defined"
    end

    def validate
      log_validation_method('name')
      log_validation_method('nodes_valid?')
      log_validation_method('roles_valid?')
      log_validation_method('canary_host_valid?')
      log_validation_method('command_valid?')
      r_name = @name || 'unknown' # name may not be set because of a previous error
      try_validate_obj("Step #{r_name}: Can't validate the command part because of a previous error"){command}
    end

    def nodes
      @nodes ||= nodes_valid? ? parse_nodes : []
    end

    def roles
      @roles ||= roles_valid? ? parse_roles : []
    end

    def canary_host
      @canary_host ||= canary_host_valid? ? @hash[:canary_host] : false
    end

    def command
      @command ||= command_valid? ? create_command : nil
    end

    private

    def nodes_valid?
      return false if @hash[:nodes].nil? # nodes is optional
      @hash[:nodes].kind_of?(Array) || @hash[:nodes].kind_of?(String) or
        raise PlanParsingError, "Step #{@name}: The value for nodes has to be a string or an array"
      if @hash[:nodes].kind_of?(Array)
        @hash[:nodes].all?{|n| n.kind_of?(String)} or
          raise PlanParsingError, "Step #{@name}: The nodes array must only contain strings"
      end
      true
    end

    def parse_nodes
      case @hash[:nodes]
        when 'all', 'All', 'ALL' then @hash[:nodes]
        when String then [ @hash[:nodes] ]
        when Array then @hash[:nodes]
        else []
      end
    end

    def roles_valid?
      return false if @hash[:roles].nil? # roless is optional
      @hash[:roles].kind_of?(Array) || @hash[:roles].kind_of?(String) or
        raise PlanParsingError, "Step #{@name}: The value for roles has to be a string or an array"
      if @hash[:roles].kind_of?(Array)
        @hash[:roles].all?{|n| n.kind_of?(String)} or
          raise PlanParsingError, "Step #{@name}: The roles array must only contain strings"
      end
      true
    end

    def parse_roles
      case @hash[:roles]
        when 'all', 'All', 'ALL' then @hash[:roles]
        when String then [ @hash[:roles] ]
        when Array then @hash[:roles]
        else []
      end
    end

    def canary_host_valid?
      return false if @hash[:canary_host].nil?
      @hash[:canary_host].kind_of?(TrueClass) or @hash[:canary_host].kind_of?(FalseClass) or
        raise PlanParsingError, "Step #{@name}: The value for canary_host must be boolean"
    end

    def command_valid?
      @hash[:command] or
        raise PlanParsingError, "Step #{@name}: A command key has to be defined"
      @hash[:command].kind_of?(Hash) || @hash[:command].kind_of?(String) or
        raise PlanParsingError, "Step #{@name}: The value for command has to be a string or a hash"
    end

    def create_command
      @command = ::DopCommon::Command.new(@hash[:command])
    end

  end
end
