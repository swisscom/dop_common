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
      end
    end

    def type
      @type ||= type_valid? ? @hash[:type].to_sym : nil
    end

    def username
      username_valid? ? @hash[:username] : nil
    end

    def password
      password_valid? ? get_secret(:password) : nil
    end

    def realm
      realm_valid? ? @hash[:realm] : nil
    end

    def service
      service_valid? ? @hash[:service] : nil
    end

    def keytab
      keytab_valid? ? @hash[:keytab] : nil
    end

    def private_key
      private_key_valid? ? @hash[:private_key] : nil
    end

    def public_key
      public_key_valid? ? @hash[:public_key] : nil
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
      private_key_valid? or
        raise PlanParsingError, "A private_key is missing in the credential #{@name} which is of type #{@hash[:type]}"
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
      return false if @hash[:password].nil?
      @hash[:password].kind_of?(String) or @hash[:password].kind_of?(Fixnum) or @hash[:password].kind_of?(Hash) or
        raise PlanParsingError, "The password has to be a string, numberor hash in the credential #{@name} which is of type #{@hash[:type]}"
      external_secret_valid?(@hash[:password]) if @hash[:password].kind_of?(Hash)
      true
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

    def credentials_file_valid?(hash_key)
      return false if @hash[hash_key].nil?
      @hash[hash_key].kind_of?(String) or
        raise PlanParsingError, "The '#{hash_key}' has to be a string in the credential #{@name} which is of type #{@hash[:type]}"
      File.exists?(@hash[hash_key]) or
        raise PlanParsingError, "The keytab #{@hash[hash_key]} from credential #{@name} which is of type #{@hash[:type]} does not exist"
      File.readable?(@hash[hash_key]) or
        raise PlanParsingError, "The keytab #{@hash[hash_key]} from credential #{@name} which is of type #{@hash[:type]} is not readable"
      true
    end

    def keytab_valid?()      credentials_file_valid?(:keytab)      end
    def private_key_valid?() credentials_file_valid?(:private_key) end
    def public_key_valid?()  credentials_file_valid?(:public_key)  end

    def external_secret_valid?(hash)
      hash.count == 1 or
        raise PlanParsingError, "You can only specify one external secret in credential #{@name}"
      method, file = hash.first
      [:file, :exec].include?(method) or
        raise PlanParsingError, "The external secret lookup method #{method} " \
          "in the credential #{name} is not valid. valid methods are :exec and :file"
      File.exists?(file) or
        raise PlanParsingError, "The file for the external secret defined in credential #{@name} does not exist."
      File.readable?(file) or
        raise PlanParsingError, "The file for the external secret defined in credential #{@name} is not readable."
      if method == :exec
        File.executable?(file) or
          raise PlanParsingError, "The file for the external secret defined in credential #{@name} is not executable."
      end
    end

    def get_secret(key)
      if @hash[key].kind_of?(Hash)
        method, file = @hash[key].first
        case method
        when :file then File.read(file).chomp
        when :exec then %x[#{file}].chomp
        end
      else
        @hash[key]
      end
    end

  end
end
