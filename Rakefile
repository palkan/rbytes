# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new

  RuboCop::RakeTask.new("rubocop:md") do |task|
    task.options << %w[-c .rubocop-md.yml]
  end
rescue LoadError
  task(:rubocop) {}
  task("rubocop:md") {}
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = false
end

task :compile do
  File.delete("lib/ruby_bytes/thor.rb") if File.file?("lib/ruby_bytes/thor.rb")

  sh "bin/rbytes compile templates/rbytes/rbytes.rb > lib/ruby_bytes/thor.rb"
end

task "test:install" do
  output = `bin/rbytes install https://railsbytes.com/script/x7msKX`
  unless output.include?("hello world from https://railsbytes.com")
    $stdput.puts "Failed to install:\n#{output}"
    exit(1)
  end
end

task default: %w[rubocop rubocop:md compile test]
