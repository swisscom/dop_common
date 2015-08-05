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
      log_validation_method('exclude_nodes_valid?')
      log_validation_method('nodes_by_config_valid?')
      log_validation_method('exclude_nodes_by_config_valid?')
      log_validation_method('roles_valid?')
      log_validation_method('exclude_roles_valid?')
      log_validation_method('command_valid?')
      r_name = @name || 'unknown' # name may not be set because of a previous error
      try_validate_obj("Step #{r_name}: Can't validate the command part because of a previous error"){command}
    end

    def nodes
      @nodes ||= nodes_valid? ? parse_pattern_list(:nodes) : []
    end

    def exclude_nodes
      @exclude_nodes ||= exclude_nodes_valid? ? parse_pattern_list(:exclude_nodes) : []
    end

    def nodes_by_config
      @nodes_by_config ||= nodes_by_config_valid? ?
        parse_patterns_list(:nodes_by_config) : {}
    end

    def exclude_nodes_by_config
      @exclude_nodes_by_config ||= exclude_nodes_by_config_valid? ?
        parse_patterns_list(:exclude_nodes_by_config) : {}
    end

    def roles
      @roles ||= roles_valid? ? parse_pattern_list(:roles) : []
    end

    def exclude_roles
      @exclude_roles ||= exclude_roles_valid? ? parse_pattern_list(:exclude_roles) : []
    end

    def command
      @command ||= command_valid? ? create_command : nil
    end

    def set_plugin_defaults
      @set_plugin_defaults ||= set_plugin_defaults_valid? ?
        parse_plugin_pattern_array(:set_plugin_defaults) : []
    end

    def delete_plugin_defaults
      @delete_plugin_defaults ||= delete_plugin_defaults_valid? ?
        parse_plugin_pattern_array(:delete_plugin_defaults) : []
    end

  private

    def parse_patterns_list(patterns, hash = @hash)
      Hash[hash[patterns].map do |pattern, value|
        [pattern, parse_pattern_list(pattern, hash[patterns])]
      end]
    end

    def parse_pattern_list(pattern, hash = @hash)
      case hash[pattern]
      when 'all', 'All', 'ALL', :all then :all
      else
        pattern_array = [ hash[pattern] ].flatten.compact
        pattern_array.map do |entry|
          regexp = is_regexp?(entry)
          regexp ? Regexp.new(regexp) : entry
        end
      end
    end

    def nodes_valid?
      pattern_list_valid?(:nodes)
    end

    def exclude_nodes_valid?
      pattern_list_valid?(:exclude_nodes)
    end

    def nodes_by_config_valid?
      patterns_list_valid?(:nodes_by_config)
    end

    def exclude_nodes_by_config_valid?
      patterns_list_valid?(:exclude_nodes_by_config)
    end

    def roles_valid?
      pattern_list_valid?(:roles)
    end

    def exclude_roles_valid?
      pattern_list_valid?(:exclude_roles)
    end

    def patterns_list_valid?(patterns, hash = @hash)
      return false if hash[patterns].nil? # patterns are optional
      hash[patterns].kind_of?(Hash) or
        raise PlanParsingError, "Step #{@name}: The value for '#{patterns}' has to be a Hash"
      hash[patterns].each do |pattern, value|
        pattern.kind_of?(String) or
          raise PlanParsingError, "Step #{@name}: The key '#{pattern.to_s}' for '#{patterns}' has to be a String"
        pattern_list_valid?(pattern, hash[patterns])
      end
    end

    def pattern_list_valid?(pattern, hash = @hash)
      return false if hash[pattern].nil? # pattern is optional
      hash[pattern].kind_of?(Array) || hash[pattern].kind_of?(String) || hash[pattern].kind_of?(Symbol) or
        raise PlanParsingError, "Step #{@name}: The value for '#{pattern}' has to be a string or an array"
      if hash[pattern].kind_of?(Array)
        hash[pattern].each do |entry|
          entry.kind_of?(String) or
            raise PlanParsingError, "Step #{@name}: The '#{pattern}' array must only contain strings"
          if is_regexp?(entry)
            is_valid_regexp?(entry) or
              raise PlanParsingError, "The pattern #{entry} in '#{pattern}' is not a valid regular expression"
          end
        end
      else
        if is_regexp?(hash[pattern])
          is_valid_regexp?(hash[pattern]) or
            raise PlanParsingError, "The pattern #{hash[pattern]} in '#{pattern}' is not a valid regular expression"
        end
      end
      true
    end

    def is_regexp?(value)
      value[/^\/(.*)\/$/, 1]
    end

    def is_valid_regexp?(value)
      regexp = is_regexp?(value)
      return false unless regexp
      begin Regexp.new(regexp) if value
      rescue
        return false
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

    def plugin_pattern_array_valid?(key)
      @hash[key].all? do |entry|
        entry.kind_of?(Hash) or
          raise PlanParsingError, "Step #{@name}: Each entry in the '#{key}' array has to be a hash"
        HashParser.key_aliases(entry, :plugins, ['plugins', :plugin, 'plugin'])
        pattern_list_valid?(:plugins, entry) or
          raise PlanParsingError, "Step #{@name}: Each entry in the '#{key}' array needs a valid value for 'plugins'"
      end
    end

    def set_plugin_defaults_valid?
      return false if @hash[:set_plugin_defaults].nil? # is optional
      @hash[:set_plugin_defaults].kind_of?(Array) or
        raise PlanParsingError, "Step #{@name}: The value of 'set_plugin_defaults' has to be an array"
      plugin_pattern_array_valid?(:set_plugin_defaults)
    end

    def delete_plugin_defaults_valid?
      return false if @hash[:delete_plugin_defaults].nil? # is optional
      @hash[:delete_plugin_defaults].kind_of?(Array) or
      @hash[:delete_plugin_defaults].kind_of?(String) or
      @hash[:delete_plugin_defaults].kind_of?(Symbol) or
        raise PlanParsingError, "Step #{@name}: The value of 'delete_plugin_defaults' has to be an array or :all"
      unless @hash[:delete_plugin_defaults].kind_of?(Array)
        ['all', 'All', 'ALL', :all].include?(@hash[:delete_plugin_defaults]) or
          raise PlanParsingError, "Step #{@name}: The value of 'delete_plugin_defaults' has to be an array or :all"
      else
        return false unless plugin_pattern_array_valid?(:delete_plugin_defaults)
        @hash[:delete_plugin_defaults].all? do |entry|
          HashParser.key_aliases(entry, :delete_keys, ['delete_keys', :delete_key, 'delete_key'])
          entry[:delete_keys].nil? and
            raise PlanParsingError, "Step #{@name}: Each entry in the 'delete_plugin_defaults' array needs a valid value for 'delete_keys'"
          entry[:delete_keys].kind_of?(Array) or
          entry[:delete_keys].kind_of?(String) or
          entry[:delete_keys].kind_of?(Symbol) or
            raise PlanParsingError, "Step #{@name}: The value for 'delete_keys' in 'delete_plugin_defaults' has to be a string or an array"
          if entry[:delete_keys].kind_of?(Array)
            entry[:delete_keys].all?{|e| e.kind_of?(String) or e.kind_of?(Symbol)} or
              raise PlanParsingError, "Step #{@name}: The elements in 'delete_keys' in 'delete_plugin_defaults' have to me strings or symbols"
          end
        end
      end
      true
    end

    def parse_plugin_pattern_array(key)
      unless @hash[key].kind_of?(Array)
        :all
      else
        @hash[key].map do |entry|
          result = entry.dup
          result[:plugins] = parse_pattern_list(:plugins, entry)
          delete_keys = case entry[:delete_keys]
          when 'all', 'All', 'ALL', :all then :all
          when String, Array then [entry[:delete_keys]].flatten
          else nil
          end
          result[:delete_keys] = delete_keys if delete_keys
          result
        end
      end
    end

  end
end
