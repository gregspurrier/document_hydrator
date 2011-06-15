require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "document_hydrator"
  gem.homepage = "http://github.com/gregspurrier/document_hydrator"
  gem.license = "MIT"
  gem.summary = %Q{DocumentHydrator takes a document, represented as a Ruby Hash, and efficiently updates it so that embedded references to other documents are replaced with their corresponding subdocuments.}
  gem.description = %Q{TODO: longer description of your gem}
  gem.email = "gspurrier@linkedin.com"
  gem.authors = ["Greg Spurrier"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

task :default => :spec
