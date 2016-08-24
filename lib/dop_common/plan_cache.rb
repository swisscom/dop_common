#
# DOP Common Plan Cache
#
# This class will store validated and parsed plans in a cache where they
# easily can be accessed
#
require 'yaml'
require 'fileutils'
require 'etc'
require 'hashdiff'
require 'lockfile'

module DopCommon
  class PlanCache

    def initialize(plan_cache_dir)
      @plan_cache_dir = plan_cache_dir
      @lockfiles = {}

      # make sure the plan directory is created
      FileUtils.mkdir_p(@plan_cache_dir) unless File.directory?(@plan_cache_dir)
    end

    # Add a new plan to the plan cache
    def add(raw_plan)
      hash = raw_plan.kind_of?(Hash) ? raw_plan : YAML.load_file(raw_plan)
      yaml = raw_plan.kind_of?(Hash) ? raw_plan.to_yaml : File.read(raw_plan)
      plan = DopCommon::Plan.new(hash)

      raise StandardError, "There is already a plan with the name #{plan.name}. Unable to add" if plan_exists?(plan.name)
      raise StandardError, 'Plan not valid. Unable to add' unless plan.valid?
      raise StandardError, 'Some Nodes already exist. Unable to add' if node_duplicates?(plan)

      plan_dir = File.join(@plan_cache_dir, plan.name, 'plan')
      FileUtils.mkdir_p(plan_dir) unless File.directory?(plan_dir)
      run_lock(plan.name) do
        save_plan_yaml(plan.name, yaml)
      end
      DopCommon.log.info("New plan #{plan.name} was added")
      plan.name
    end

    # Update a plan already in the plan cache
    def update(raw_plan)
      hash = raw_plan.kind_of?(Hash) ? raw_plan : YAML.load_file(raw_plan)
      yaml = raw_plan.kind_of?(Hash) ? raw_plan.to_yaml : File.read(raw_plan)
      plan = DopCommon::Plan.new(hash)

      raise StandardError, "No plan with the name #{plan.name} found. Unable to update" unless plan_exists?(plan.name)
      raise StandardError, 'Plan not valid. Unable to update' unless plan.valid?
      raise StandardError, 'Some Nodes already exist in other plans. Unable to update' if node_duplicates?(plan)

      run_lock(plan.name) do
        save_plan_yaml(plan.name, yaml)
      end
      DopCommon.log.info("Plan #{plan.name} was updated")
      plan.name
    end

    # remove a plan from the plan cache
    def remove(plan_name)
      raise StandardError, "Plan #{plan_name} does not exist" unless plan_exists?(plan_name)
      plan_dir = File.join(@plan_cache_dir, plan_name)
      plan_versions_dir = File.join(plan_dir, 'plan')

      # we have to remove the plan in two steps, so we don't
      # delete the lockfile too soon.
      run_lock(plan_name) do
        FileUtils.remove_entry_secure(plan_versions_dir)
      end
      FileUtils.remove_entry_secure(plan_dir)
      DopCommon.log.info("Plan #{plan_name} was removed")
      plan_name
    end

    # return an array with all plan names in the cache
    def list
      Dir.entries(@plan_cache_dir).select do |entry|
        plan_dir = File.join(@plan_cache_dir, entry, "plan")
        add_entry = true
        add_entry = false if ['.', '..'].include?(entry)
        add_entry = false if Dir[plan_dir + '/*.yaml'].empty?
        add_entry
      end
    end

    # returns a sorted array of versions for a plan (oldest version first)
    def show_versions(plan_name)
      raise StandardError, "Plan #{plan_name} does not exist" unless plan_exists?(plan_name)
      plan_dir = File.join(@plan_cache_dir, plan_name, "plan")
      Dir[plan_dir + '/*.yaml'].map {|yaml_file| File.basename(yaml_file, '.yaml')}.sort
    end

    # return the hash for the plan in the cache for a specific
    # version. Returns the latest version if no version is specified
    def get_plan_hash(plan_name, version = :latest)
      raise StandardError, "Plan #{plan_name} does not exist" unless plan_exists?(plan_name)

      versions = show_versions(plan_name)
      version = versions.last if version == :latest
      raise StandardError, "Version #{version} of plan #{plan_name} not found" unless versions.include?(version)

      yaml = File.join(@plan_cache_dir, plan_name, "plan", version + '.yaml')
      YAML.load_file(yaml)
    end

    # Get the plan object for the specified version directly
    def get_plan(plan_name, version = :latest)
      hash = get_plan_hash(plan_name, version)
      DopCommon::Plan.new(hash)
    end

    def get_plan_hash_diff(plan_name, old_version, new_version = :latest)
      old_hash = get_plan_hash(plan_name, old_version)
      new_hash = get_plan_hash(plan_name, new_version)
      HashDiff.best_diff(old_hash, new_hash)
    end

    # A run lock is used in all operations which change plans in the plan cache.
    def run_lock(plan_name)
      lockfile = run_lockfile(plan_name)
      lockfile.lock
      write_run_lock_info(plan_name)
      yield
    rescue Lockfile::TimeoutLockError
      info_file = File.join(@plan_cache_dir, plan_name, 'run_lock_info')
      locked_message = File.read(info_file)
      raise StandardError, locked_message
    ensure
      lockfile.unlock if run_lock?(plan_name)
    end

    # return true if we have a run lock
    def run_lock?(plan_name)
      run_lockfile(plan_name).locked?
    end

    def state_store(plan_name, app_name)
      state_file = File.join(@plan_cache_dir, plan_name, app_name + '.yaml')
      DopCommon::StateStore.new(state_file, plan_name, self)
    end

    private

    # Returns true if a plan with that name already exists
    # in the plan cache.
    def plan_exists?(plan_name)
      plan_dir = File.join(@plan_cache_dir, plan_name, "plan")
      Dir[plan_dir + '/*.yaml'].any?
    end

    # returns true if a node in the plan is already present
    # in an other plan already in the cache.
    def node_duplicates?(plan)
      other_plans = list - [ plan.name ]
      nodes = plan.nodes.map{|n| n.name}
      other_plans.any? do |other_plan_name|
        other_plan  = get_plan(other_plan_name)
        other_nodes = other_plan.nodes.map{|n| n.name}
        duplicates  = nodes & other_nodes
        unless duplicates.empty?
          DopCommon.log.error("Node(s) #{duplicates.join(', ')} already exist in plan #{other_plan_name}")
          return true
        end
      end
      false
    end

    # save a new version of the plan to the cache
    def save_plan_yaml(plan_name, yaml)
      file_name = File.join(@plan_cache_dir, plan_name, 'plan', new_version_string + '.yaml')
      file = File.new(file_name, 'w')
      file.write(yaml)
      file.close
    end

    def new_version_string
      Time.now.utc.strftime('%Y%m%d%H%M%S%L')
    end

    def run_lockfile(plan_name)
      lockfile = File.join(@plan_cache_dir, plan_name, 'run_lock')
      options = {:retry => 0, :timeout => 1, :max_age => 86400}
      @lockfiles[plan_name] ||= Lockfile.new(lockfile, options)
    end

    def write_run_lock_info(plan_name)
      info_file = File.join(@plan_cache_dir, plan_name, 'run_lock_info')
      user = Etc.getpwuid(Process.uid)
      File.open(info_file, 'w') do |f|
        f.puts "A run lock for the plan #{plan_name} is in place!"
        f.puts "Time : #{Time.now}"
        f.puts "User : #{user.name}"
        f.puts "Pid  : #{Process.pid}"
      end
    end

  end
end
