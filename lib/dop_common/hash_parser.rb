#
# DOP Common Hash Parser Helper Functions
#

module DopCommon
  module HashParser

    # This method will set the key from a list of defined
    # aliases or raise an error if multiple values are found
    def key_aliases(hash, key, key_aliases)
      value = hash[key]
      key_aliases.each do |key_alias|
        next if hash[key_alias].nil?
        unless value.nil?
          keys_with_values = key_aliases.select{|a| !hash[a].nil?}
          keys_with_values << key if hash[key]
          key_list = keys_with_values.map{|k| k.kind_of?(Symbol) ? ':' + k.to_s : k}.join(', ')
          raise DopCommon::PlanParsingError,
            "Two or more values found for the same thing. There can only be one of: #{key_list}"
        else
          value = hash[key] = hash.delete(key_alias)
          key_s = key.kind_of?(Symbol) ? ':' + key.to_s : key
          DopCommon.log.debug("Key alias found '#{key_alias}', mapping for key #{key_s}")
        end
      end
    end
    module_function :key_aliases

    def symbolize_keys(hash)
      Hash[hash.map { |k, v| [k.to_sym, v] }] if hash.kind_of?(Hash)
    end
    module_function :symbolize_keys

    def deep_symbolize_keys(hash, stack = [])
      # prevent loops in recursive function
      return if stack.include?(hash.object_id)
      stack << hash.object_id

      if hash.kind_of?(Hash)
        Hash[
          hash.map do |k, v|
            [k.respond_to?(:to_sym) ? k.to_sym : k, deep_symbolize_keys(v, stack)]
          end
        ]
      elsif hash.kind_of?(Array)
        hash.map { |v| deep_symbolize_keys(v, stack) }
      else
        hash
      end
    end
    module_function :deep_symbolize_keys

    # This method will retrun true if the String in 'value' starts and
    # ends with /, which means it represents a regexp
    def represents_regexp?(value)
      if value.kind_of?(String)
        value[/^\/(.*)\/$/, 1] ? true : false
      else
        false
      end
    end
    module_function :represents_regexp?

    # This method will return true if the string in 'value' represents
    # a regex and if it is possible to create a regexp object
    def is_valid_regexp?(value)
      return false unless represents_regexp?(value)
      regexp = value[/^\/(.*)\/$/, 1]
      Regexp.new(regexp)
      true
    rescue
      false
    end
    module_function :is_valid_regexp?

    # This method takes a hash and a key. It will then validate the
    # pattern list in the value of that key.
    #
    # Examples (Simple String/Regexp):
    #
    # hash = { :key => 'my_node'}
    # hash = { :key => '/my_node/'}
    #
    # Examples (Array of Strings, Regexps):
    #
    # hash = { :key => [ 'my_node', '/my_node/' ] }
    #
    def pattern_list_valid?(hash, key, optional = true)
      return false if hash[key].nil? && optional
      [Array, String, Symbol].include? hash[key].class or
        raise PlanParsingError, "The value for '#{key}' has to be a string, an array or a symbol."
      [hash[key]].flatten.each do |pattern|
        [String, Symbol].include? pattern.class or
          raise PlanParsingError, "The pattern #{pattern} in '#{key}' is not a symbol or string."
        if HashParser.represents_regexp?(pattern)
          HashParser.is_valid_regexp?(pattern) or
            raise PlanParsingError, "The pattern #{pattern} in '#{key}' is not a valid regular expression."
        end
      end
      true
    end
    module_function :pattern_list_valid?

    # This method takes a hash where all the values are pattern lists
    # and checks if they are valid.
    #
    # Example:
    #
    # hash = {
    #   :key => {
    #     'list_1' => [ 'my_node', '/my_node/' ],
    #     'list_2' => '/my_node'/
    #   }
    # }
    #
    def hash_of_pattern_lists_valid?(hash, key, optional = true )
      return false if hash[key].nil? && optional
      hash[key].kind_of?(Hash) or
        raise PlanParsingError, "The value for '#{key}' has to be a Hash"
      hash[key].each_key do |list_name|
        list_name.kind_of?(String) or
          raise PlanParsingError, "The key '#{list_name.to_s}' in '#{key}' has to be a String"
        HashParser.pattern_list_valid?(hash[key], list_name)
      end
      true
    end
    module_function :hash_of_pattern_lists_valid?

    # This method will parse a valid pattern list and replace regexp
    # strings with Regexp objects.
    def parse_pattern_list(hash, key)
      case hash[key]
      when 'all', 'All', 'ALL', :all then :all
      else
        patterns = [hash[key]].flatten.compact
        patterns.map do |pattern|
          HashParser.represents_regexp?(pattern) ? Regexp.new(pattern[/^\/(.*)\/$/, 1]) : pattern
        end
      end
    end
    module_function :parse_pattern_list

    # This method will parse a hash of pattern lists and replace the
    # regexp strings with Regexp objects
    def parse_hash_of_pattern_lists(hash, key)
      Hash[hash[key].map do |list_name, pattern_list|
        [list_name, parse_pattern_list(hash[key], list_name)]
      end]
    end
    module_function :parse_hash_of_pattern_lists

  end
end
