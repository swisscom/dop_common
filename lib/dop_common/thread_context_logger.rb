#
# This is log formatter which will log to different files based on the context
# which was set for the current thread. if no context was set then it will log
# to the 'all' context.
#
# This is used to separate log for different nodes even for logs which are
# generated in some external library which is not aware of the context.
#
module DopCommon
  class ThreadContextLogger
    def initialize(log_path, contexts, all = true)
      @log_path = log_path
      @contexts = contexts
      @all      = all
      @mutex    = Mutex.new
      @loggers  = {}
      @threads  = {}

      FileUtils.mkdir_p(@log_path)
      create
    end

    def create
      @mutex.synchronize do
        add('all') if @all
        @contexts.each{|context| add(context)}
      end
    end

    def cleanup
      @mutex.synchronize do
        @contexts.each{|context| remove(context)}
      end
    end

    def log_context=(context)
      @mutex.synchronize do
        @threads[Thread.current.object_id.to_s] = context
      end
    end

    def current_log_file
      context = @threads[Thread.current.object_id.to_s]
      log_file(context)
    end

    private

    def log_file(context)
      File.join(@log_path, context)
    end

    def add(context)
      logger = Logger.new(log_file(context))
      if context == 'all'
        logger.formatter = Logger::Formatter.new
      else
        logger.formatter = formatter(context)
      end
      logger.level = ::Logger.const_get(DopCommon.config.log_level.upcase)

      @loggers[context] = logger
      DopCommon.add_log_junction(logger)
    end

    def remove(context)
      logger = @loggers[context]
      DopCommon.remove_log_junction(logger)
    end

    def formatter(context)
      orig_formatter = Logger::Formatter.new
      Proc.new do |severity, datetime, progname, msg|
        @mutex.synchronize do
          if context == @threads[Thread.current.object_id.to_s]
            orig_formatter.call(severity, datetime, progname, msg)
          else
            nil
          end
        end
      end
    end

  end
end
