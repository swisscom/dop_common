#
# the logger stuff
#
require 'logger'

module DopCommon

  def self.log
    @log ||= Logger.new(STDOUT)
  end

  def self.logger=(logger)
    @log = logger
  end

end
