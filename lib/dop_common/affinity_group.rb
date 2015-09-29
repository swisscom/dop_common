#
# DOP Common infrastructure hash parser
#

module DopCommon
  class AffinityGroup
    include Validator
    include HashParser

    attr_reader :name

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
      @positive ||= positive_valid? ? @hash[:positive] : nil
    end
    alias_method :positive?, :positive

    def enforce
      @enforce ||= enforce_valid? ? @hash[:enforce] : nil
    end
    alias_method :enforced?, :enforce

    def cluster
      @ip_pool ||= cluster_valid? ? @hash[:cluster] : nil
    end

    private

    def positive_valid?
      raise PlanParsingError, "Affinity group #{@name}: positive flag must be one of 'true' or 'false'" unless
        @hash[:positive].kind_of?(TrueClass) || @hash[:positive].kind_of?(FalseClass)
      true
    end

    def enforce_valid?
      raise PlanParsingError, "Affinity group #{@name}: enforce flag must be one of 'true' or 'false'" unless
        @hash[:enforce].kind_of?(TrueClass) || @hash[:enforce].kind_of?(FalseClass)
      true
    end

    def cluster_valid?
      raise PlanParsingError, "Affinity group #{@name}: cluster must be a string" unless
        @hash[:cluster].kind_of?(String)
      true
    end
  end
end
