#
# DOP Plan Hiera Backend
#

class Hiera
  module Backend

    class Dop_backend

      def initialize
        Hiera.debug('Hiera DOP backend starting')
        begin
          require 'dop_common'
        rescue
          require 'rubygems'
          require 'dop_common'
        end

        if Config[:dop].kind_of?(Hash)
          @plan_store_dir ||= Config[:dop][:plan_store_dir]
        end
        @plan_store_dir ||= '/var/lib/dop/plans'

        @plan_store = DopCommon::PlanStore.new(@plan_store_dir)
        @plan_cache = DopCommon::PlanCache.new(@plan_store)
        Hiera.debug('DOP Plan Cache Loaded')
      end

      def lookup(key, scope, order_override, resolution_type, context)
        node_name = scope['::clientcert']
        plan = @plan_cache.plan_by_node(node_name)

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
        Hiera::Backend.datasources(scope, order_override) do |source|
          Hiera.debug("Looking for data source #{source}")
          begin
            data = plan.configuration.lookup(source, key, scope)
            new_answer = Hiera::Backend.parse_answer(data, scope, extra_data, context)
            found = true

            case resolution_type.is_a?(Hash) ? :hash : resolution_type
            when :array then answer = merge_array(answer, new_answer)
            when :hash  then answer = merge_hash(answer, new_answer, resolution_type)
            else
              answer = new_answer
              break
            end

          rescue DopCommon::ConfigurationValueNotFound
            next
          end
        end
        throw(:no_such_key) unless found
        return answer
      end

    private

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
        answer = Hiera::Backend.merge_answer(new_answer, answer, resolution_type)
        unless new_answer.kind_of?(Hash)
          raise "Hiera type mismatch: expected Hash and got #{new_answer.class}"
        end
        return answer
      end

    end
  end
end
