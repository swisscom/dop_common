#
# DOPi CLI gloable options
#

module DopCommon
  module Cli

    def self.global_options(base)
      base.class_eval do
        desc 'Verbosity of the command line tool'
        default_value 'INFO'
        arg_name 'Verbosity'
        flag [:verbosity, :v]

        desc 'Show stacktrace on crash'
        default_value DopCommon.config.trace
        switch [:trace, :t]

        desc 'Specify the directory where the plans and their state will be stored'
        default_value DopCommon.config.plan_store_dir
        arg_name 'DIR'
        flag [:plan_store_dir, :s]

        desc 'Directory for the log files'
        default_value DopCommon.config.log_dir
        arg_name 'LOGDIR'
        flag [:log_dir]

        desc 'Log level for the logfiles'
        default_value DopCommon.config.log_level
        arg_name 'LOGLEVEL'
        flag [:log_level, :l]
      end
    end

  end
end
