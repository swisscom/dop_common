require 'dop_common/log'

module DopCommon
  module Cli

    # Default quiet log formatter for the CLI
    class DefaultFormatter < Logger::Formatter
      def call(severity, time, progname, msg)
        "#{msg2str(msg)}\n"
      end
    end

    # This adds code line context to the log output
    class TraceFormatter < Logger::Formatter
      def call(severity, datetime, progname, msg)
        timestamp = datetime.strftime("%Y-%m-%d %H:%M:%S.%L")
        hostname = ::Socket.gethostname.split('.').first
        file, line, method = caller[11].sub(/.*\/([0-9a-zA-Z_\-.]+):(\d+):.+`(.+)'/, "\\1-\\2-\\3").gsub(":", " ").split("-")
        pid = "[#{::Process.pid}]".ljust(7)
        "#{timestamp} #{hostname} #{progname}#{pid} #{severity.ljust(5)} #{file}:#{line}:#{method}: #{msg2str(msg)}\n"
      end
    end

    def self.initialize_logger(name, log_level, verbosity, trace)
      # create a dummy logger and use the lowest log level configured
      DopCommon.logger = Logger.new('/dev/null')
      file_log_level = ::Logger.const_get(log_level.upcase)
      cli_log_level = ::Logger.const_get(verbosity.upcase)
      min_log_level = file_log_level < cli_log_level ? file_log_level : cli_log_level
      DopCommon.log.level = min_log_level

      # create the cli console logger
      logger = Logger.new(STDOUT)
      logger.level = cli_log_level
      if trace
        logger.formatter = DopCommon::Cli::TraceFormatter.new
      else
        logger.formatter = DopCommon::Cli::DefaultFormatter.new
      end
      DopCommon.add_log_junction(logger)

      # create the cli file logger
      FileUtils.mkdir_p(DopCommon.config.log_dir)
      log_file = File.join(DopCommon.config.log_dir, name)
      logger = Logger.new(log_file , 10, 1024000)
      logger.level = ::Logger.const_get(DopCommon.config.log_level.upcase)
      DopCommon.add_log_junction(logger)
    end

  end
end
