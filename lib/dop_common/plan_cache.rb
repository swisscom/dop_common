#
# DOP Common Plan Cache
#
# This class will store validated and parsed plans in a cache where they
# easily can be accessed
#
require 'yaml'

module DopCommon
  class PlanCache

    def initialize(plan_cache_dir)
      @plan_cache_dir = plan_cache_dir

      # make sure the plan directory is created
      FileUtils.mkdir_p(@plan_cache_dir) unless File.directory?(@plan_cache_dir)
    end

    def add(plan_file)
      hash = YAML.load_file(plan_file)
      plan = DopCommon::Plan.new(hash)

      raise StandardError, 'Plan was already added. Remove to readd the plan' if plan_exists?(plan.name)
      raise StandardError, 'Plan not valid; did not add' unless plan.valid?
      raise StandardError, 'Some Nodes already exist. Did not add' if node_duplicates?(plan)

      save_yaml(hash, plan.name) # This may be removed once DOPv fully uses dop_common as parser
      save(plan)
      DopCommon.log.info("New plan #{plan.name} was added")
      plan.name
    end

    def list
      Dir[File.join(@plan_cache_dir, '*_plan.yaml')].map do |file|
        File.basename(file).sub('_plan.yaml', '')
      end
    end

    def remove(name)
      raise StandardError, "Plan #{name} does not exist" unless plan_exists?(name)
      Dir[File.join(@plan_cache_dir, name + '*' )].each do |file|
        DopCommon.log.debug("Removing file from cache: #{file}")
        FileUtils.rm(file)
      end
      DopCommon.log.info("Plan #{name} was removed")
      name
    end

    def plan_exists?(name)
      File.exists?(dump_file(name))
    end

    def get(name)
      raise StandardError, "Plan #{name} does not exist" unless plan_exists?(name)
      YAML::load(File.read(dump_file(name)))
    end

    def save(plan)
      File.open(dump_file(plan.name), 'w') { |file| file.write(YAML::dump(plan)) }
    end

    def save_yaml(hash, name)
      File.open(yaml_file(name), 'w') { |file| file.write(hash) }
    end

    # Check if the nodes of the plan given as a parameter clash with
    # the nodes of the already stored planes in the cache
    def node_duplicates?(plan)
      list.any? do |name|
        get(name).nodes.any? do |cached_node|
          plan.nodes.any? do |node|
            if node.name == cached_node.name
              DopCommon.log.error("Node #{node.name} already exists in plan #{name}")
              true
            else
              false
            end
          end
        end
      end
    end

    def yaml_file(name)
      File.join(@plan_cache_dir, name + '.yaml')
    end

    # Get the name of the dump file
    def dump_file(name)
      File.join(@plan_cache_dir, name + '_plan.yaml')
    end

  end
end
