#
# DOP Common infrastructure hash parser
#
require 'active_support/core_ext/hash/indifferent_access'

module DopCommon
  class Infrastructure

    def initialize(name, hash)
      @name = name
      @hash = hash.kind_of?(Hash) ? ActiveSupport::HashWithIndifferentAccess.new(hash) : hash
    end

  end
end
