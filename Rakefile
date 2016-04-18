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
    'rhel6.example.com' => ['ruby193'],
    'rhel7.example.com' => [],
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
        sh "vagrant ssh #{machine} -c '#{commands.join(' && ')}'"
        # scl ruby
        test_machines[machine].each do |scl|
          sh "vagrant ssh #{machine} -c 'scl enable ruby193 \"#{commands.join(' && ')}\"'"
        end
      end
    end
  end
end
