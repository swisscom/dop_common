#
# Dop configurator helper functions
#
module DopCommon
  class Config
    module Helper
      def self.included(base)
        base.send(:extend, ClassMethods)
      end

      module ClassMethods
        def user
          Etc.getpwuid(Process.uid)
        end

        def is_root?
          user.name == 'root'
        end

        def dop_home
          File.join(user.dir, '.dop')
        end

        def conf_var(variable, options = {})
          define_method(variable) do
            unless instance_variable_defined?("@#{variable}")
              default = default.call(self) if default.kind_of?(Proc)
              instance_variable_set "@#{variable}", options[:default]
            end
            instance_variable_get "@#{variable}"
          end
          attr_writer variable
        end
      end

    end
  end
end

