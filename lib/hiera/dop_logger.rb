#
# Route Hiera Log entries to DOPi Logger
#
require 'dop_common'

class Hiera
  module Dop_logger
    class << self

      def warn(msg)
        DopCommon.log.warn('Hiera: ' +msg)
      end

      def debug(msg)
        DopCommon.log.debug('Hiera: ' + msg)
      end

    end
  end
end
