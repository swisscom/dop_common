module DopCommon
  module Utils
    def to_bytes(val)
      regex = /^[1-9]\d*(k|m|g)?$/i
      gigabytes = /g/i
      megabytes = /m/i
      kilobytes = /k/i
      str = val.to_s

      raise PlanParsingError, "The value must be a number greater that zero optionally followed by one of k,K,m,M,g,G literals" unless
        str =~ regex

      if str.index(gigabytes)
        return str.sub(gigabytes,'').to_i * 1073741824
      elsif str.index(megabytes)
        return str.sub(megabytes,'').to_i * 1048576
      elsif str.index(kilobytes)
        return str.sub(kilobytes,'').to_i * 1024
      else
        return str.to_i
      end
    end
    module_function :to_bytes
  end
end
