#
# DOP Plan Hiera Backend
#

class Hiera
  module Backend
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
        @plan_cache_dir ||= '/var/lib/dop/plans'

        @plan_cache = DopCommon::PlanCache.new(@plan_cache_dir)
        Hiera.debug('DOP Plan Cache Loaded')
      end

      def find_plan(node_name)
        begin
          plan_id = @plan_cache.list.find do |id|
            Hiera.debug("Checking plan #{id} for node #{node_name}")
            @plan_cache.get(id).find_node(node_name)
          end
          Hiera.debug("Node found in plan #{plan_id}")
          @plan_cache.get(plan_id)
        rescue StandardError => e
          nil
        end
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = nil
        begin
          configuration = find_plan(scope['::clientcert']).configuration
          Backend.datasources(scope, order_override) do |source|
            Hiera.debug("Looking for data source #{source}")
            data = nil
            begin
               data = configuration.lookup(source, key, scope)
            rescue DopCommon::ConfigurationValueNotFound
              next
            else
              new_answer = Backend.parse_answer(data, scope)
              case resolution_type
              when :array
                raise StandardError, "Hiera type mismatch: expected Array and got #{new_answer.class}" unless new_answer.kind_of? Array or new_answer.kind_of? String
                answer ||= []
                answer << new_answer
              when :hash
                raise Exception, "Hiera type mismatch: expected Hash and got #{new_answer.class}" unless new_answer.kind_of? Hash
                answer ||= {}
                answer = Backend.merge_answer(new_answer,answer)
              else
                answer = new_answer
                break
              end
            end
          end
        rescue StandardError => e
          Hiera.debug(e.message)
          nil
        end
        return answer
      end

    end
  end
end
