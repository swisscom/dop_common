#
# DOP Common command hash parser
#

module DopCommon
  class Command
    include Validator
    include HashParser

    attr_reader :hash

    def initialize(hash)
      @hash = symbolize_keys(hash)
      @defaults = {
        :plugin_timeout => 300,
        :verify_after_run => false,
      }
    end

    def validate
      log_validation_method('plugin_valid?')
      log_validation_method('verify_after_run_valid?')
      if @hash.kind_of?(Hash)
        log_validation_method('plugin_timeout_valid?')
        log_validation_method('verify_commands_valid?')
        r_plugin = @plugin || 'unknown' # name may not be set because of a previous error
        try_validate_obj("Command #{r_plugin}: Can't validate the verify_commands part because of a previous error"){verify_commands}
      end
    end

    def overwrite_defaults=(defaults_hash)
      @defaults.merge!(defaults_hash)
    end

    # Add the plugin specific validator
    def extended_validator=(obj)
      @extended_validator = obj if obj.respond_to?(:validate)
    end

    def plugin
      @plugin ||= plugin_valid? ? parse_plugin : nil
    end

    def title
      @title ||= title_valid? ? @hash[:title] : plugin
    end

    def plugin_timeout
      @plugin_timeout = plugin_timeout_valid? ? @hash[:plugin_timeout] : @defaults[:plugin_timeout]
    end

    def verify_commands
      @verify_commands ||= verify_commands_valid? ? create_verify_commands : []
    end

    def verify_after_run
      @verify_after_run = verify_after_run_valid? ? @hash[:verify_after_run] : @defaults[:verify_after_run]
    end

  private

    def plugin_valid?
      if @hash.kind_of?(String)
        @hash.empty? and
          raise PlanParsingError, "The value for 'command' can not be an empty string"
      elsif @hash.kind_of?(Hash)
        @hash.empty? and
          raise PlanParsingError, "The value for 'command' can not be an empty hash"
        @hash[:plugin] or
          raise PlanParsingError, "The 'plugin key is missing in the 'command' hash"
        @hash[:plugin].kind_of?(String) or
          raise PlanParsingError, "The value for 'plugin' has to be a String with valid plugin name"
        @hash[:plugin].empty? and
          raise PlanParsingError, "The value for 'plugin' can not be an empty string"
      else
        raise PlanParsingError, "The value for 'command' must be a String with a plugin name or a hash"
      end
      true
    end

    def parse_plugin
      case @hash
        when String then @hash
        when Hash   then @hash[:plugin]
      end
    end

    def title_valid?
      return false unless @hash.kind_of?(Hash)
      return false if @hash[:title].nil?
      @hash[:title].kind_of?(String) or
        raise PlanParsingError, "The command title has to be a string"
    end

    def plugin_timeout_valid?
      return false unless @hash.kind_of?(Hash)
      return false if @hash[:plugin_timeout].nil? # plugin_timeout is optional
      @hash[:plugin_timeout].kind_of?(Fixnum) or
        raise PlanParsingError, "The value for 'plugin_timeout' has to be a number"
    end

    def verify_commands_valid?
      return false unless @hash.kind_of?(Hash)
      return false if @hash[:verify_commands].nil?
      [Array, Hash, String].include? @hash[:verify_commands].class or
        raise PlanParsingError, "The value for 'verify_commands' has to be a String, Hash or an Array"
    end

    def create_verify_commands
      case @hash[:verify_commands]
        when String, Hash then [ ::DopCommon::Command.new(@hash[:verify_commands]) ]
        when Array then @hash[:verify_commands].map {|c| ::DopCommon::Command.new(c)}
        else []
      end
    end

    def verify_after_run_valid?
      return false unless @hash.kind_of?(Hash)
      return false if @hash[:verify_after_run].nil?
      @hash[:verify_after_run].kind_of?(TrueClass) or @hash[:verify_after_run].kind_of?(FalseClass) or
        raise PlanParsingError, "The value for 'verify_after_run' must be boolean"
    end

  end
end
