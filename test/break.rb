begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"
  # Activate the gem you are reporting the issue against.
  gem "activejob"
  gem "delayed_job", '>= 3.0'
  gem "delayed_job_active_record", '>= 0.4'
  gem "sqlite3"
end

require "minitest/autorun"
require "active_job"
require "delayed_job"

# Ensure backward compatibility with Minitest 4
Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :delayed_jobs, force: true do |table|
    table.integer :priority, default: 0, null: false # Allows some jobs to jump to the front of the queue
    table.integer :attempts, default: 0, null: false # Provides for retries, but still fail eventually.
    table.text :handler,                 null: false # YAML-encoded string of the object that will do work
    table.text :last_error                           # reason for last failure (See Note below)
    table.datetime :run_at                           # When to run. Could be Time.zone.now for immediately, or sometime in the future.
    table.datetime :locked_at                        # Set when a client is working on this object
    table.datetime :failed_at                        # Set when all retries have failed (actually, by default, the record is deleted instead)
    table.string :locked_by                          # Who is working on this object (if locked)
    table.string :queue                              # The name of the queue this job is in
    table.timestamps null: true
    table.string :split_group_id
  end

  create_table :breaks, :force => true do |table|
    table.string :text
  end

  add_index :delayed_jobs, [:priority, :run_at], name: "delayed_jobs_priority"
end

# Purely useful for test cases...
class Break < ActiveRecord::Base

  def self.aggr(arry = [])
    sleep 1
    arry.each do |x| 
      # Do something
    end
  end

  def whatever
    # puts "-Testing-"
    # Do something
  end
  handle_asynchronously :whatever, :priority => 10

end