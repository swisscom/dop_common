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
      Hash[hash.map { |k, v| [k.to_sym, v] }]
    end
    module_function :symbolize_keys

    def deep_symbolize_keys(hash)
      case hash
      when Hash
        Hash[
          hash.map do |k, v|
          [ k.respond_to?(:to_sym) ? k.to_sym : k, recursive_symbolize_keys(v) ]
          end
        ]
      when Enumerable
        hash.map { |v| recursive_symbolize_keys(v) }
      else
        hash
      end
    end
    module_function :deep_symbolize_keys
  end
end
