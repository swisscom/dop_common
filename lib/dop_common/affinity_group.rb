#
# DOP Common infrastructure hash parser
#

module DopCommon
  class AffinityGroup
    include Validator
    include HashParser

    def initialize(name, hash)
      @name = name
      @hash = symbolize_keys(hash)
    end

    def validate
      log_validation_method(:positive_valid?)
      log_validation_method(:enforce_valid?)
      log_validation_method(:cluster_valid?)
    end

    def positive
      @positive ||= positive_valid? ? hash[:positive] : nil
    end
    
    def enforce
      @enforce ||= enforce_valid? ? hash[:enforce] : nil
    end
    
    def cluster
      @ip_pool ||= cluster_valid? ? hash[:cluster] : nil
    end

    private

    def positive_valid?
      @hash[:positive].kind_of?(TrueClass) or @hash[:positive].kind_of?(FalseClass) or
        raise PlanParsingError, "Affinity group #{@name}: positive flag must be one of 'true' or 'false'"
    end

    def enforce_valid?
      @hash[:enforce].kind_of?(TrueClass) or @hash[:enforce].kind_of?(FalseClass) or
        raise PlanParsingError, "Affinity group #{@name}: enforce flag must be one of 'true' or 'false'"
    end

    def cluster_valid?
      @hash[:cluster].kind_of?(String) or 
        raise PlanParsingError, "Affinity group #{@name}: cluster must be a string"
    end
  end
end
