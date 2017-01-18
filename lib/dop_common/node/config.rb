#
# Node configuration parts for hiera variable lookups and facts
#

module DopCommon
  class Node
    module Config
      @@mutex_hiera = Mutex.new
      @@mutex_lookup = Mutex.new
      @@hiera = nil
      @@hiera_config = nil

      def has_name?(pattern)
        pattern_match?(name, pattern)
      end

      def config(variable)
        resolve_external(variable) || resolve_internal(variable)
      end

      def has_config?(variable, pattern)
        pattern_match?(config(variable), pattern)
      end

      def config_includes?(variable, pattern)
        [config(variable)].flatten.any?{|v| pattern_match?(v, pattern)}
      end

      def fact(variable)
        scope[ensure_global_namespace(variable)]
      end

      def has_fact?(variable, pattern)
        pattern_match?(fact(variable), pattern)
      end

      def role
        config(DopCommon.config.role_variable) || role_default
      end

      def has_role?(pattern)
        pattern_match?(role, pattern)
      end

    private

      def pattern_match?(value, pattern)
        case pattern
        when Regexp then value =~ pattern
        else value == pattern
        end
      end

      def basic_scope
        @basic_scope ||= {
          '::fqdn'       => fqdn,
          '::clientcert' => fqdn,
          '::hostname'   => hostname,
          '::domain'     => domainname
        }
      end

      def facts
        return {} unless DopCommon.config.load_facts
        facts_yaml = File.join(DopCommon.config.facts_dir, fqdn + '.yaml')
        if File.exists? facts_yaml
          YAML.load_file(facts_yaml).values
        else
          DopCommon.log.warn("No facts found for node #{name} at #{facts_yaml}")
          {}
        end
      end

      def ensure_global_namespace(fact)
        fact =~ /^::/ ? fact : '::' + fact
      end

      def scope
        merged_scope = basic_scope.merge(facts)
        Hash[merged_scope.map {|fact,value| [ensure_global_namespace(fact), value ]}]
      end

      def hiera
        @@mutex_hiera.synchronize do
          # Create a new Hiera object if the config has changed
          unless DopCommon.config.hiera_yaml == @@hiera_config
            DopCommon.log.debug("Hiera config location changed from #{@@hiera_config.to_s} to #{DopCommon.config.hiera_yaml.to_s}")
            @@hiera_config = DopCommon.config.hiera_yaml
            config = {}
            if File.exists?(@@hiera_config)
              config = YAML.load_file(@@hiera_config)
            else
              DopCommon.log.error("Hiera config #{@@hiera_config} not found! Using empty config")
            end
            # set the plan_store defaults
            config[:dop] ||= { }
            unless config[:dop].has_key?(:plan_store_dir)
              config[:dop][:plan_store_dir] = DopCommon.config.plan_store_dir
            end
            config[:logger] = 'dop'
            @@hiera = Hiera.new(:config => config)
          end
        end
        @@hiera
      end

      def role_default
        if DopCommon.config.role_default
          DopCommon.config.role_default
        else
          DopCommon.log.warn("No role found for #{name} and no default role defined.")
          '-'
        end
      end

      # This will try to resolve the config variable from the plan configuration hash.
      # This is needed in case the plan is not yet added to the plan cache
      # (in case of validation) and hiera can't resolve it over the plugin,
      # but we still need the information about the node config.
      def resolve_internal(variable)
        return nil unless DopCommon.config.use_hiera
        @@mutex_lookup.synchronize do
          begin
            hiera # make sure hiera is initialized
            answer = nil
            Hiera::Backend.datasources(scope) do |source|
              DopCommon.log.debug("Hiera internal: Looking for data source #{source}")
              data = nil
              begin
                data = @parsed_configuration.lookup(source, variable, scope)
              rescue DopCommon::ConfigurationValueNotFound
                next
              else
                break if answer = Hiera::Backend.parse_answer(data, scope)
              end
            end
          rescue StandardError => e
            DopCommon.log.debug(e.message)
          end
          DopCommon.log.debug("Hiera internal: answer for variable #{variable} : #{answer}")
          return answer
        end
      end

      # this will try to resolve the variable over hiera directly
      def resolve_external(variable)
        return nil unless DopCommon.config.use_hiera
        @@mutex_lookup.synchronize do
          begin hiera.lookup(variable, nil, scope)
          rescue Psych::SyntaxError => e
            DopCommon.log.error("YAML parsing error in hiera data. Make sure you hiera yaml files are valid")
            nil
          end
        end
      end

    end
  end
end
