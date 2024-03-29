require 'rake/testtask'
require 'dotenv'

Dotenv.load

namespace :load do

  desc 'Load test dovetail stitching'
  task :dovetail, [:total, :concurrency, :per] do |t, args|
    $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/load")
    $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/test/support")
    require 'dovetail/file_cache'

    args.with_defaults(total: 10, concurrency: 5, per: 1)
    loader = FileCache.new(args[:total].to_i, args[:concurrency].to_i, args[:per].to_i)
    loader.load!
  end

end

Rake::TestTask.new('test') do |t|
  if ENV['STAGING_APPLICATIONS_STACK_STATE'] != "Created"
    puts "Skipping test suite; no application stacks."
    exit 0
  end

  # TODO When ENV['STAGING_REGION_MODE'] is not Primary, only apps that run in
  # a secondary region should be tested

  t.libs << 'test/support'
  t.pattern = "test/**/*_test.rb"
end
Rake::TestTask.new('test:dovetail') do |t|
  t.libs << 'test/support'
  t.pattern = "test/dovetail/*_test.rb"
end
Rake::TestTask.new('test:metrics') do |t|
  t.libs << 'test/support'
  t.pattern = "test/metrics/*_test.rb"
end
Rake::TestTask.new('test:publish') do |t|
  t.libs << 'test/support'
  t.pattern = "test/publish/*_test.rb"
end
Rake::TestTask.new('test:cleanup') do |t|
  t.libs << 'test/support'
  t.pattern = "test/**/cleanup.rb"
end
Rake::TestTask.new('test:upload') do |t|
  t.libs << 'test/support'
  t.pattern = "test/upload/*_test.rb"
end
Rake::TestTask.new('test:porter') do |t|
  t.libs << 'test/support'
  t.pattern = "test/porter/*_test.rb"
end

task default: :test
