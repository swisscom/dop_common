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
