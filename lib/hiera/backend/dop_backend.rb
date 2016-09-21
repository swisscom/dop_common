#
# DOP Plan Hiera Backend
#

class Hiera
  module Backend

    class DopPlans
      def initialize(plan_cache)
        @plan_cache = plan_cache
        @plans = {}    # { plan_name => plan    }
        @versions = {} # { plan      => version }
        @nodes = {}    # { node_name => plan    }
      end

      # will return the plan of the node or nil
      # if the node is not in a plan
      def get_plan(node_name)
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
        newest_version = @plan_cache.show_versions(plan_name).last
        unless loaded_version == newest_version
          remove_plan(plan)
          add_plan(plan_name)
        end
      rescue
        remove_plan(plan)
      end

      def refresh_all
        loaded_plan_names = @plans.keys
        existing_plan_names = @plan_cache.list
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
        version = @plan_cache.show_versions(plan_name).last
        plan    = @plan_cache.get_plan(plan_name)
        @plans[plan_name] = plan
        @versions[plan] = version
        plan.nodes do |node|
          @nodes[node.name] = plan
        end
      end

    end

    class Dop_backend

      def initialize(cache = nil)
        Hiera.debug('Hiera DOP backend starting')
        begin
          require 'dop_common'
        rescue
          require 'rubygems'
          require 'dop_common'
        end

        @plan_cache_dir ||= Config[:dop] && Config[:dop][:plan_cache_dir]
        @plan_cache_dir ||= '/var/lib/dop/cache'

        @plan_cache = DopCommon::PlanCache.new(@plan_cache_dir)
        @plans = DopPlans.new(@plan_cache)
        Hiera.debug('DOP Plan Cache Loaded')
      end

      def lookup(key, scope, order_override, resolution_type, context)
        node_name = scope['::clientcert']
        plan = @plans.get_plan(node_name)
        if plan.nil?
          Hiera.debug("Node #{node_name} not found in any plan")
          throw(:no_such_key)
        else
          Hiera.debug("Node #{node_name} found in plan #{plan.name}")
          plan_lookup(plan, key, scope, order_override, resolution_type, context)
        end
      end

      def plan_lookup(plan, key, scope, order_override, resolution_type, context)
        answer = nil
        found = false
        extra_data = {}
        context[:order_override] = order_override
        Backend.datasources(scope, order_override) do |source|
          Hiera.debug("Looking for data source #{source}")
          begin
            data = plan.configuration.lookup(source, key, scope)
            new_answer = Backend.parse_answer(data, scope, extra_data, context)
            found = true

            case resolution_type.is_a?(Hash) ? :hash : resolution_type
            when :array then answer = merge_array(answer, new_answer)
            when :hash  then answer = merge_hash(answer, new_answer, resolution_type)
            else
              answer = new_answer
              break
            end

          rescue ConfigurationValueNotFound
            next
          end
        end
        throw(:no_such_key) unless found
        return answer
      end

      def merge_array(answer, new_answer)
        answer ||= []
        case new_answer
        when Array then answer += new_answer
        when String then answer << new_answer
        else
          raise "Hiera type mismatch: expected Array or String and got #{new_answer.class}"
        end
        return answer
      end

      def merge_hash(answer, new_answer, resolution_type)
        answer ||= {}
        answer = Backend.merge_answer(new_answer, answer, resolution_type)
        unless new_answer.kind_of?(Hash)
          raise "Hiera type mismatch: expected Hash and got #{new_answer.class}"
        end
        return answer
      end

    end
  end
end
