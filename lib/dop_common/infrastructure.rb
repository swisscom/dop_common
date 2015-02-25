#
# DOP Common infrastructure hash parser
#

module DopCommon
  class Infrastructure

    def initialize(name, hash)
      @name = name
      @hash = hash.kind_of?(Hash) ? Hash[hash.map{|k,v| [k.to_sym, v]}] : hash
    end

    def validate
      true
    end

    def valid?
      true
    end

  end
end
