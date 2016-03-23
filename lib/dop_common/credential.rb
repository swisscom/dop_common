#
# DOP Common credential hash parser
#

module DopCommon
  class Credential
    include Validator
    include HashParser

    attr_reader :hash, :name

    VALID_TYPES = [:username_password, :kerberos, :ssh_key]

    def initialize(name, hash)
      @name = name
      @hash = deep_symbolize_keys(hash)
      DopCommon.add_log_filter(Proc.new {|msg| filter_secrets(msg)})
    end

    def validate
      log_validation_method('type_valid?')
    end

    # This method filters the secrets from a message
    def filter_secrets(msg)
      case type
      when :username_password then msg.gsub(password, '****')
      else msg
      end
    end

    def type
      @type ||= type_valid? ? @hash[:type].to_sym : nil
    end

    def username
      username_valid? ? @hash[:username] : nil
    end

    def password
      password_valid? ? load_content(@hash[:password]) : nil
    end

    def realm
      realm_valid? ? @hash[:realm] : nil
    end

    def service
      service_valid? ? @hash[:service] : nil
    end

    def keytab
      keytab_valid? ? load_content(@hash[:keytab]) : nil
    end

    def private_key
      private_key_valid? ? load_content(@hash[:private_key]) : nil
    end

    def public_key
      public_key_valid? ? load_content(@hash[:public_key]) : nil
    end

  private

    def type_valid?
      @hash[:type] or
        raise PlanParsingError, "You need to specify the 'type' of the credental in #{@name} which can be one of #{VALID_TYPES.join(', ')}"
      case @hash[:type]
      when :username_password, 'username_password' then username_password_valid?
      when :kerberos, 'kerberos'                   then kerberos_valid?
      when :ssh_key, 'ssh_key'                     then ssh_key_valid?
      else raise PlanParsingError, "The 'type' of the credental in #{@name} has to be one of #{VALID_TYPES.join(', ')}"
      end
      true
    end

    # This are the type validation methods, they will check if all the mandatory elements are there and
    # if every supported attribute is valid.

    def username_password_valid?
      username_valid? or
        raise PlanParsingError, "A username is missing in the credential #{@name} which is of type #{@hash[:type]}"
      password_valid? or
        raise PlanParsingError, "A password is missing in the credential #{@name} which is of type #{@hash[:type]}"
      true
    end

    def kerberos_valid?
      realm_valid? or
        raise PlanParsingError, "A realm is missing in the credential #{@name} which is of type #{@hash[:type]}"
      service_valid?
      keytab_valid?
      true
    end

    def ssh_key_valid?
      username_valid? or
        raise PlanParsingError, "A username is missing in the credential #{@name} which is of type #{@hash[:type]}"
      private_key_valid?
      public_key_valid?
      true
    end

    # Attribute verification, will return false if the attribute is not valid, otherwise raise a PlanParsingError

    def username_valid?
      return false if @hash[:username].nil?
      @hash[:username].kind_of?(String) or @hash[:username].kind_of?(Fixnum) or
        raise PlanParsingError, "The username has to be a string or number in the credential #{@name} which is of type #{@hash[:type]}"
      true
    end

    def password_valid?
      credential_load_content_valid?(:password)
    end

    def keytab_valid?
      credential_load_content_valid?(:keytab)
    end

    def private_key_valid?
      credential_load_content_valid?(:private_key)
    end

    def public_key_valid?
      credential_load_content_valid?(:public_key)
    end

    def credential_load_content_valid?(key)
      return false if @hash[key].nil?
      load_content_valid?(@hash[key])
    rescue PlanParsingError => e
      raise PlanParsingError, "Error while parsing the value for #{key} in credential #{@name}: #{e.message}"
    end

    def realm_valid?
      return false if @hash[:realm].nil?
      @hash[:realm].kind_of?(String) or
        raise PlanParsingError, "The realm has to be a string in the credential #{@name} which is of type #{@hash[:type]}"
      true
    end

    def service_valid?
      return false if @hash[:service].nil?
      @hash[:service].kind_of?(String) or
        raise PlanParsingError, "The service has to be a string in the credential #{@name} which is of type #{@hash[:type]}"
      true
    end

  end
end
