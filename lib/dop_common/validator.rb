#
# DOP Common Validator
#
# Some Validation Helper stuff
#

module DopCommon
  module Validator

    def valid?
      @validity = true
      validate
      @validity
    end

    def set_not_valid
      @validity = false
    end

    def log_validation_method(method, error_klass = PlanParsingError)
      begin
        send(method)
      rescue error_klass => e
        set_not_valid
        DopCommon.log.error(e.message)
      end
    end

    def try_validate_obj(message, error_klass = PlanParsingError)
      begin
        obj = yield
        if obj.kind_of?(Array)
          obj.each do |x|
            x.validate
            set_not_valid unless x.valid?
          end
        else
          obj.validate
          set_not_valid unless obj.valid?
        end
      rescue error_klass => e
        set_not_valid
        DopCommon.log.warn(message)
      end
    end

  end
end
