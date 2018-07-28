class AddSplitGroupIdToDelayedJobs < ActiveRecord::Migration
  def self.up
    add_column :delayed_jobs, :split_group_id, :string, :limit => 20
    add_index :delayed_jobs, :split_group_id
  end
  
  def self.down
    remove_column :delayed_jobs, :split_group_id, :string
  end
end