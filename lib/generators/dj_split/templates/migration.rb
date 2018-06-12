class AddJobGroupIdToDelayedJobs < ActiveRecord::Migration
  def self.up
    add_column :job_group_id, :string
  end
  
  def self.down
    remove_column :job_group_id, :string
  end
end