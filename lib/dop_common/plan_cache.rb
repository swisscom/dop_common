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
      id   = get_id(plan_file)
      raise StandardError, 'Plan was already added. Remove to readd the plan' if id_exists?(id)

      plan = DopCommon::Plan.new(hash)
      raise StandardError, 'Plan not valid; did not add' unless plan.valid?
      raise StandardError, 'Some Nodes already exist. Did not add' if node_duplicates?(plan)

      save_yaml(hash, id) # This may be removed once DOPv fully uses dop_common as parser
      save(plan, id)
      DopCommon.log.info("New plan #{plan_file} was added with id #{id}")
      id
    end

    def list
      Dir[File.join(@plan_cache_dir, '*_plan.yaml')].map do |file|
        File.basename(file).sub('_plan.yaml', '')
      end
    end

    def remove(id)
      raise StandardError, 'Plan id does not exist' unless id_exists?(id)
      Dir[File.join(@plan_cache_dir, id + '*' )].each do |file|
        DopCommon.log.debug("Removing file from cache: #{file}")
        FileUtils.rm(file)
      end
      DopCommon.log.info("Plan with id #{id} was removed")
      id
    end

    def id_exists?(id)
      File.exists?(dump_file(id))
    end

    def get(id)
      raise StandardError, 'Plan id does not exist' unless id_exists?(id)
      YAML::load(File.read(dump_file(id)))
    end

    def save(plan, id)
      File.open(dump_file(id), 'w') { |file| file.write(YAML::dump(plan)) }
    end

    def save_yaml(hash, id)
      File.open(yaml_file(id), 'w') { |file| file.write(hash) }
    end

    # Check if the nodes of the plan given as a parameter clash with
    # the nodes of the already stored planes in the cache
    def node_duplicates?(plan)
      list.any? do |id|
        get(id).nodes.any? do |cached_node|
          plan.nodes.any? do |node|
            if node.name == cached_node.name
              DopCommon.log.error("Node #{node.name} already exists in plan #{id}")
              true
            else
              false
            end
          end
        end
      end
    end

    def yaml_file(id)
      File.join(@plan_cache_dir, id + '.yaml')
    end

    # Get the name of the dump file
    def dump_file(id)
      File.join(@plan_cache_dir, id + '_plan.yaml')
    end

    def get_id(plan_file)
      Digest::SHA2.file(plan_file).hexdigest
    end

  end
end
