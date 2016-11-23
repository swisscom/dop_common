#
# This is a simple wrapper around YAML::Store to make versioning
# and updating easier.
#
require 'yaml/store'
require 'rb-inotify'

module DopCommon
  class UnknownVersionError < StandardError
  end

  class StateStore < YAML::Store

    def initialize(state_file, plan_name, plan_cache)
      @plan_name   = plan_name
      @plan_cache  = plan_cache
      @state_file  = state_file
      @write_mutex = Mutex.new
      super(@state_file)
    end

    # This is a wrapper around transaction to make sure we have a run lock.
    # This will ensure that only ever one instance can write to this store.
    def transaction(read_only = false, &block)
      if read_only
        super(read_only, &block)
      else
        @write_mutex.synchronize do
          if @plan_cache.run_lock?(@plan_name)
            # save the version on first write
            super do
              self[:version] = latest_version if self[:version].nil?
            end
            super(&block)
          else
            raise StandardError, "Not possible to write to #{@state_file} because we have no run lock"
          end
        end
      end
    end

    def version
      transaction(true) do
        self[:version] || :new
      end
    end

    def pending_updates?
      case version
      when :new, latest_version then false
      else true
      end
    end

    # update the state file. This takes a block which will receive a
    # hash diff from the state version to the newest plan version.
    # If the plan is new or already on the latest version the block will
    # not be executed.
    #
    # The block is already inside a transaction. The version will be bumped
    # to the latest version only if the transaction is successful.
    def update
      ver = version
      return if ver == latest_version
      return if ver == :new
      raise UnknownVersionError.new(ver) unless version_exists?(ver)
      DopCommon.log.info("Updating plan #{@plan_name} from version #{ver} to #{latest_version}")
      transaction do
        yield(@plan_cache.get_plan_hash_diff(@plan_name, ver, latest_version))
        self[:version] = latest_version
      end
    end

    # This method will take a block which will be executet every time the
    # state file changes.
    def on_change
      notifier = INotify::Notifier.new
      notifier.watch(@state_file, :modify) do
        yield
      end
      notifier.run
    end

  private

    def latest_version
      @plan_cache.show_versions(@plan_name).last
    end

    def version_exists?(version)
      @plan_cache.show_versions(@plan_name).include?(version)
    end

  end
end
