#
# This builds a multi-destination logger and pluggable filters for
# around the standard ruby logger.
#
require 'logger'

module DopCommon

  def self.log
    @log ||= create_logger(STDOUT)
  end

  def self.logger=(logger)
    logger.formatter = DopCommon.filter_formatter
    @log = logger
  end

  def self.formatter
    @formatter ||= Logger::Formatter.new
  end

  def self.formatter=(formatter_proc)
    @formatter ||= formatter_proc
  end

  def self.reset_logger
    @log = nil
    @log_filters = []
    @log_junction = []
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

  def self.remove_log_junction(logger)
    log_junctions.delete(logger)
  end

  private

  def self.create_logger(logdev = STDOUT)
    logger = Logger.new(logdev)
    logger.formatter = DopCommon.filter_formatter
    logger
  end

  def self.filter_formatter
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
      formatter.call(severity, datetime, progname, filtered_message)
    end
  end

end
