#
# the logger stuff
#
require 'logger'

module DopCommon

  def self.log
    @log ||= create_logger(STDOUT)
  end

  def self.logger=(logger)
    logger.formatter = DopCommon.log_formatter
    @log = logger
  end

  def self.log_filters
    @log_filters ||= []
  end

  def self.add_log_filter(filter_proc)
    log_filters << filter_proc
  end

  def self.log_junctions
    @log_junction ||= []
  end

  def self.add_log_junction(logger)
    log_junctions << logger
  end

  def self.create_logger(logdev = STDOUT)
    logger = Logger.new(logdev)
    logger.formatter = log_formatter
    logger
  end

  def self.log_formatter
    original_formatter = Logger::Formatter.new
    Proc.new do |severity, datetime, progname, msg|
      filtered_message = msg
      log_filters.each do |filter|
        filtered_message = case filtered_message
                           when Exception
                             filtered_message.exception(filter.call(filtered_message.message))
                           when String
                             filter.call(filtered_message)
                           else
                             filter.call(filtered_message.inspect)
                           end
      end
      log_junctions.each {|logger| logger.log(::Logger.const_get(severity), filtered_message, progname)}
      original_formatter.call(severity, datetime, progname, filtered_message)
    end
  end

end
