#
# DOP Common infrastructure hash parser
#

module DopCommon
  class Infrastructure

    def initialize(name, hash)
      @name = name
      @hash = Hash[hash.map{|k,v| [k.to_sym, v]}]
    end

  end
end
