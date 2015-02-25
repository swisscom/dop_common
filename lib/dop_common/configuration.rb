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
      begin
        element = @hash
        source.split('/').each do |level|
          element = element[level]
        end
        element[key] or raise ConfigurationValueNotFound 
      rescue Exception => e
        raise ConfigurationValueNotFound
      end
    end

  end
end
