#
# DOP common step set hash parser
#

module DopCommon
  class StepSet
    include Validator

    attr_reader :name

    def initialize(name, steps_array)
      @name = name
      @steps_array = steps_array
    end

    def validate
      log_validation_method(:steps_valid?)
      try_validate_obj("StepSet #{name}: Can't validate the steps part because of a previous error"){steps}
    end

    def steps
      @steps ||= steps_valid? ? create_steps : nil
    end

  private

    def steps_valid?
      @steps_array.any? or
        raise PlanParsingError, "StepSet #{name}: no steps defined"
      @steps_array.all?{|s| s.kind_of?(Hash)} or
        raise PlanParsingError, "StepSet #{name}: steps array must only contain hashes"
    end

    def create_steps
      @steps_array.map do |hash|
        ::DopCommon::Step.new(hash)
      end
    end

  end
end
