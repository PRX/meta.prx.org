require 'rake/testtask'
require 'dotenv'

Dotenv.load

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = "test/**/*_test.rb"
end

task default: :test
