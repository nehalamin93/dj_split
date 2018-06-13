class AddJobGroupIdToDelayedJobs < ActiveRecord::Migration
  def self.up
    add_column :job_group_id, :string, :limit => 20
  end
  
  def self.down
    remove_column :job_group_id, :string
  end
end