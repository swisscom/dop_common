#
# DOP Common configuration lookup
#

module DopCommon
  class ConfigurationValueNotFound < StandardError
  end

  class Configuration

    def initialize(hash)
      @hash = hash
    end

    def lookup(source, key, scope)
      element = traverse_hash(source)
      if element.has_key?(key)
        element[key]
      else
        raise DopCommon::ConfigurationValueNotFound
      end
    rescue => e
      raise DopCommon::ConfigurationValueNotFound
    end

  private

    def traverse_hash(source)
      element = @hash
      source.split('/').each do |level|
        element = element[level]
      end
      element
    end

  end
end
