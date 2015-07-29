#
# DOP Common credential hash parser
#

module DopCommon
  class Credential
    include Validator

    attr_reader :hash

    VALID_TYPES = [:username_password]

    def initialize(name, hash)
      @name = name
      @hash = hash.kind_of?(Hash) ? Hash[hash.map{|k,v| [k.to_sym, v]}] : hash
    end

    def validate
      log_validation_method('type_valid?')
    end

    def type
      @type ||= type_valid? ? @hash[:type] : nil
    end

    def username
      @username ||= [:username_password].include?(type) and @hash[:username] or
        raise "The credentials type #{type} does not support a username attribute"
    end

    def password
      @password ||= [:username_password].include?(type) and @hash[:password] or
        raise "The credentials type #{type} does not support a password attribute"
    end

  private

    def type_valid?
      @hash[:type] or
        raise PlanParsingError, "You need to specify the 'type' of the credental in #{@name} which can be one of #{VALID_TYPES.join(', ')}"
      case @hash[:type]
      when :username_password then username_password_valid?
      else raise PlanParsingError, "The 'type' of the credental in #{@name} has to be one of #{VALID_TYPES.join(', ')}"
      end
      true
    end

    def username_password_valid?
      @hash[:username] or
        raise PlanParsingError, "A username is missing in the credential #{@name} which is of type #{@hash[:type]}"
      @hash[:username].kind_of?(String) or @hash[:username].kind_of?(Fixnum) or
        raise PlanParsingError, "The username has to be a string or number in the credential #{@name} which is of type #{@hash[:type]}"
      @hash[:password] or
        raise PlanParsingError, "A password is missing in the credential #{@name} which is of type #{@hash[:type]}"
      @hash[:password].kind_of?(String) or @hash[:password].kind_of?(Fixnum) or @hash[:password].kind_of?(Hash) or
        raise PlanParsingError, "The password has to be a string, numberor hash in the credential #{@name} which is of type #{@hash[:type]}"
      external_secret_valid?(@hash[:password]) if @hash[:password].kind_of?(Hash)
      true
    end

    def external_secret_valid?(hash)
      #TODO: implement
      raise PlanParsingError, "External secret sources for credentials are not implemented yet (#{@name})."
    end

  end
end
