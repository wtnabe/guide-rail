# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create(:spec) do |t|
  t.libs << "spec"
  t.test_globs = ["spec/**/*_spec.rb"]
end

require "standard/rake"

desc "Check syntax of sig/**/*.rbs"
task :rbs do
  sh "rbs", "parse", *Dir["sig/**/*.rbs"]
end

task default: %i[spec standard rbs]
