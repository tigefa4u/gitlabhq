# frozen_string_literal: true

require 'database_cleaner/active_record/deletion'
require_relative 'db_cleaner'

module FakeInformationSchema
  # Work around a bug in DatabaseCleaner when using the deletion strategy:
  # https://github.com/DatabaseCleaner/database_cleaner/issues/347
  #
  # On MySQL, if the information schema is said to exist, we use an inaccurate
  # row count leading to some tables not being cleaned when they should
  def information_schema_exists?(_connection)
    false
  end
end

DatabaseCleaner::ActiveRecord::Deletion.prepend(FakeInformationSchema)

RSpec.configure do |config|
  include DbCleaner

  config.before(:suite) do
    setup_database_cleaner
  end

  config.around(:each, :delete) do |example|
    self.class.use_transactional_tests = false
    DatabaseCleaner.strategy = :deletion, { except: deletion_except_tables, cache_tables: false }
    DatabaseCleaner.cleaning do
      example.run
    end
    self.class.use_transactional_tests = true
  end

  config.around(:each, :migration) do |example|
    self.class.use_transactional_tests = false
    DatabaseCleaner.strategy = :deletion, { cache_tables: false }
    DatabaseCleaner.cleaning do
      example.run
    end
    self.class.use_transactional_tests = true
  end
end
