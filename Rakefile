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
    test_machines.each do |machine, scls|
      scls.each do |scl|
        commands = [
          'cd /vagrant',
          "bundle install --path ~/.bundle_#{scl}",
          'bundle exec rspec',
        ]
        Bundler.with_clean_env do
          if scl == 'system'
            sh "vagrant ssh #{machine} -c '#{commands.join(' && ')}'"
          else
            sh "vagrant ssh #{machine} -c 'scl enable #{scl} \"#{commands.join(' && ')}\"'"
          end
        end
      end
    end
  end
end
