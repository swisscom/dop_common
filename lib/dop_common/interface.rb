#
# DOP Common configuration lookup
#

module DopCommon
  class Interface

    attr_reader :name

    def initialize(name, hash)
      @name = name
      @hash = hash
    end

  end
end
