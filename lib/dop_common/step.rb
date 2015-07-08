#
# DOP common step hash parser
#

module DopCommon
  class Step
    include Validator
    include SharedOptions

    def initialize(hash)
      @hash = Hash[hash.map{|k,v| [k.to_sym, v]}]
    end

    def name
      @name ||= @hash[:name] or
        raise PlanParsingError, "Every step needs to have a 'name' key defined"
    end

    def validate
      valitdate_shared_options
      log_validation_method('name')
      log_validation_method('nodes_valid?')
      log_validation_method('roles_valid?')
      log_validation_method('command_valid?')
      r_name = @name || 'unknown' # name may not be set because of a previous error
      try_validate_obj("Step #{r_name}: Can't validate the command part because of a previous error"){command}
    end

    def nodes
      @nodes ||= nodes_valid? ? parse_pattern_list(:nodes) : []
    end

    def roles
      @roles ||= roles_valid? ? parse_pattern_list(:roles) : []
    end

    def command
      @command ||= command_valid? ? create_command : nil
    end

  private

    def parse_pattern_list(pattern)
      case @hash[pattern]
      when 'all', 'All', 'ALL', :all then :all
      else
        pattern_array = [ @hash[pattern] ].flatten.compact
        pattern_array.map do |entry|
          regexp = entry[/^\/(.*)\/$/, 1]
          regexp ? Regexp.new(regexp) : entry
        end
      end
    end

    def nodes_valid?
      pattern_list_valid?(:nodes)
    end

    def roles_valid?
      pattern_list_valid?(:roles)
    end

    def pattern_list_valid?(pattern)
      return false if @hash[pattern].nil? # roless is optional
      @hash[pattern].kind_of?(Array) || @hash[pattern].kind_of?(String) or
        raise PlanParsingError, "Step #{@name}: The value for '#{pattern}' has to be a string or an array"
      if @hash[pattern].kind_of?(Array)
        @hash[pattern].each do |entry|
          entry.kind_of?(String) or
            raise PlanParsingError, "Step #{@name}: The '#{pattern}' array must only contain strings"
          regexp = entry[/^\/(.*)\/$/, 1]
          begin Regexp.new(regexp) if regexp
          rescue
            raise PlanParsingError, "The pattern #{entry} in '#{pattern}' is not a valid regular expression"
          end
        end
      end
      true
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
