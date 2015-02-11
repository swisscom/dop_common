#
# DOP Common command hash parser
#

module DopCommon
  class Command

    DEFAULT_PLUGIN_TIMEOUT = 300

    def initialize(hash)
      @hash = hash
    end

    def plugin
      @plugin ||= plugin_valid? ? parse_plugin : nil
    end

    def plugin_timeout
      @plugin_timeout ||= plugin_timeout_valid? ? @hash[:plugin_timeout] : DEFAULT_PLUGIN_TIMEOUT
    end

  private

    def plugin_valid?
      if @hash.class == String
        @hash.empty? and
          raise PlanParsingError, "The value for 'command' can not be an empty string"
      elsif @hash.class == Hash
        @hash.empty? and
          raise PlanParsingError, "The value for 'command' can not be an empty hash"
        @hash[:plugin] or
          raise PlanParsingError, "The 'plugin key is missing in the 'command' hash"
        @hash[:plugin].class == String or
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
        when Hash then @hash[:plugin]
      end
    end

    def plugin_timeout_valid?
      return false if @hash[:plugin_timeout].nil? # plugin_timeout is optional
      @hash[:plugin_timeout].class == Fixnum or
        raise PlanParsingError, "The value for 'plugin_timeout' has to be a number"
    end

  end
end
