
module DopCommon
  class PlanCache

    def initialize(plan_store)
      @plan_store = plan_store
      @plans = {}    # { plan_name => plan    }
      @versions = {} # { plan      => version }
      @nodes = {}    # { node_name => plan    }
    end

    # will return the plan of the node or nil
    # if the node is not in a plan
    def plan_by_node(node_name)
      plan = @nodes[node_name]
      if plan
        refresh_plan(plan)
        # this makes sure the node was not removed
        plan = @nodes[node_name]
        return plan if plan
      end

      refresh_all
      return @nodes[node_name]
    end

  private

    def refresh_plan(plan)
      loaded_version = @versions[plan]
      plan_name = plan.name
      newest_version = @plan_store.show_versions(plan_name).last
      unless loaded_version == newest_version
        remove_plan(plan)
        add_plan(plan_name)
      end
    rescue
      remove_plan(plan)
    end

    def refresh_all
      loaded_plan_names = @plans.keys
      existing_plan_names = @plan_store.list
      remove_old_plans(loaded_plan_names - existing_plan_names)
      refresh_plans(existing_plan_names)
    end

    def refresh_plans(plan_names)
      plan_names.each do |plan_name|
        plan = @plans[plan_name]
        if plan
          refresh_plan(plan)
        else
          add_plan(plan_name)
        end
      end
    end

    def remove_old_plans(plan_names)
      plan_names.each do |plan_name|
        remove_plan(@plans[plan_name])
      end
    end

    def remove_plan(plan_to_remove)
      @nodes.delete_if{|node_name, plan| plan == plan_to_remove}
      @plans.delete_if{|plan_name, plan| plan == plan_to_remove}
      @versions.delete_if{|plan, version| plan == plan_to_remove}
    end

    def add_plan(plan_name)
      version = @plan_store.show_versions(plan_name).last
      plan    = @plan_store.get_plan(plan_name)
      @plans[plan_name] = plan
      @versions[plan] = version
      plan.nodes do |node|
        @nodes[node.name] = plan
      end
    end

  end
end

