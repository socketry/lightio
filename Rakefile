require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:"spec:library") do |t|
  t.exclude_pattern = 'spec/**/monkey_spec.rb'
end

RSpec::Core::RakeTask.new(:"spec:monkey_patch") do |t|
  t.rspec_opts = "-r monkey_patch.rb --tag ~skip_monkey_patch"
end

task :default => :spec

task :spec => [:"spec:library", :"spec:monkey_patch"]
