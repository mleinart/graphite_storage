require 'bundler/gem_tasks'
require 'rspec/core/rake_task'


desc "Run all specs in spec path"
RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = ['--options', "#{File.expand_path('../.rspec', __FILE__)}"]
  task.pattern = FileList['spec/**/*_spec.rb']
end
