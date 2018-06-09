require 'rails/generators'
require 'rails/generators/migration'
require 'rails/generators/active_record'

class DjSplitGenerator < Rails::Generators::Base

  include Rails::Generators::Migration
  
  def self.source_root
     @source_root ||= File.join(File.dirname(__FILE__), 'templates')
  end

  def create_migration_file
    migration_template('migration.rb', 'db/migrate/add_job_group_id_to_delayed_jobs.rb') if defined?(ActiveRecord)
  end

  def self.next_migration_number(dirname)
    next_migration_number = current_migration_number(dirname) + 1
    if ActiveRecord::Base.timestamped_migrations
      [Time.now.utc.strftime("%Y%m%d%H%M%S"), "%.14d" % next_migration_number].max
    else
      "%.3d" % next_migration_number
    end
  end
end