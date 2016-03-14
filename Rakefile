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
  test_machines = [
    'rhel6.example.com',
    'rhel7.example.com'
  ]

  task :prep do
    Bundler.with_clean_env do
      sh 'vagrant up'
      sh 'vagrant rsync'
    end
  end

  task :spec => ['vagrant:prep'] do
    test_machines.each do |machine|
      Bundler.with_clean_env do
        commands = [
          'cd /vagrant',
          'bundle install',
          'bundle exec rspec',
        ]
        sh "vagrant ssh #{machine} -c '#{commands.join(' && ')}'"
      end
    end
  end
end
