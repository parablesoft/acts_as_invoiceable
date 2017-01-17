$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "byebug"
require "acts_as_invoiceable"
require 'ffaker'
require "database_cleaner"
require "factory_girl"
require "payday"
# require 'shoulda/matchers'

Dir["spec/factories/**/*.rb"].each {|f| load f}

load "spec/database.rb"

# Shoulda::Matchers.configure do |config|
#   config.integrate do |with|
#     with.test_framework :rspec
#     with.library :rails
#   end
# end

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.include FactoryGirl::Syntax::Methods

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

end

