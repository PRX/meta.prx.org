require 'rake/testtask'
require 'dotenv'

Dotenv.load

namespace :load do

  desc 'Load test dovetail stitching'
  task :dovetail, [:total, :concurrency, :per] do |t, args|
    $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/load")
    $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/test")
    require 'dovetail/file_cache'

    args.with_defaults(total: 10, concurrency: 5, per: 1)
    loader = FileCache.new(args[:total].to_i, args[:concurrency].to_i, args[:per].to_i)
    loader.load!
  end

end

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.pattern = "test/**/*_test.rb"
end

task default: :test
