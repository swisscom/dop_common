require "bundler/gem_tasks"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new('spec')

task :default => :spec
task :test => :spec

task :console do
  require 'pry'
  require 'dop_common'
  ARGV.clear
  Pry.start
end

namespace :vagrant do
  test_machines = {
    'rhel6.example.com' => ['system', 'ruby193', 'rh-ruby22'],
    'rhel7.example.com' => ['system', 'ruby193', 'rh-ruby22'],
  }

  task :prep do
    Bundler.with_clean_env do
      sh 'vagrant up'
      sh 'vagrant rsync'
    end
  end

  desc 'execute the rspec tests in vagrant boxes'
  task :spec => ['vagrant:prep'] do
    test_machines.each_key do |machine|
      Bundler.with_clean_env do
        commands = [
          'cd /vagrant',
          'bundle install',
          'bundle exec rspec',
        ]
        # system ruby
        if test_machines[machine].delete('system')
          sh "vagrant ssh #{machine} -c '#{commands.join(' && ')}'"
        end
        # scl ruby
        test_machines[machine].each do |scl|
          sh "vagrant ssh #{machine} -c 'scl enable #{scl} \"#{commands.join(' && ')}\"'"
        end
      end
    end
  end
end
