# 
# Class is designed to Split Time Taking Delayed Jobs, Crons, Bulk Operations, etc into smaller size multiple Delayed Jobs.
# These Jobs should be Independent of each other.
# Splitting will be done on one parameter only.
#
# Purpose: To distribute the load among multiple application servers.
#
# Usage:
# => DjSplit.new(queue_options: {queue: queue_name}, split_options: {size: 1000, by: 2}).enqueue(match_client, "bulk_mentor_match", student_ids, mentor_ids)
# instead of:
# => match_client.bulk_mentor_match(student_ids, mentor_ids)
#
# Note: Arguments must be in exact order.
# "enqueue" parameters are (object, function_name, arguments of that function)
# split_options[:size] is splitting size
# split_options[:by] is position of splitting attribute in the enqueue function. In above example, splitting attribute is student_ids and has position 2(>=2).
# Here we are splitting on the basis of student_ids. 
# We can also specify the :splitting_size, Otherwise it will take default Optimal Splitting Size
#
require 'active_support'
require 'active_record'
require 'delayed_job'
require 'delayed_job_active_record'
require "dj_split/version"
require "dj_split/delayed_job_overrides"

class DjSplit

  OPTIMAL_SPLIT_SIZE = 200

  def initialize(options)
    @queue_options  = options[:queue_options]
    @job_group_id = rand(100000000) # Collision is still OK
    @queue_options.merge!(job_group_id: @job_group_id)
    @split_options = options[:split_options]
  end

  def enqueue(object, method_name, *args)
    splitting_index = get_splitting_index
    sliced_ids_array = get_sliced_ids(args[splitting_index])

    sliced_ids_array.each do |slice_set|
      args[splitting_index] = slice_set
      delayed_job_object = Delayed::PerformableMethod.new(object, method_name.to_sym, args)
      Delayed::Job.enqueue(delayed_job_object, @queue_options) 
    end

    wait_check_and_execute_delayed_jobs
  end

  private

  def wait_check_and_execute_delayed_jobs
    while(pending_jobs_of_group_id?)
      pick_and_invoke_delayed_job
    end

    waiting_for_other_workers_to_process_jobs
    handle_failed_jobs
  end

  def pick_and_invoke_delayed_job
    worker_object = Delayed::Worker.new
    worker_object.job_group_id = @job_group_id
    worker_object.work_off(1)
  end

  def pending_jobs_of_group_id?
    pending_jobs_count = Delayed::Job.where(job_group_id: @job_group_id, locked_at: nil).count
    (pending_jobs_count > 0)? true: false
  end

  def waiting_for_other_workers_to_process_jobs
    while(get_count_of_processing_jobs_by_other_workers > 0)
      sleep(1.0/5.0)
    end
  end

  def handle_failed_jobs
    failed_jobs = Delayed::Job.where(job_group_id: @job_group_id).where.not(failed_at: nil)
    raise "Failed Delayed Jobs of Group Id(#{@job_group_id}): #{failed_jobs}" if failed_jobs.count > 0
  end

  def get_count_of_processing_jobs_by_other_workers
    Delayed::Job.where(job_group_id: @job_group_id, failed_at: nil).count
  end

  def get_split_size
    @split_options[:size] || OPTIMAL_SPLIT_SIZE
  end

  def get_sliced_ids(ids) 
    ids.each_slice(get_split_size)
  end

  def get_splitting_index
    @split_options[:by] - 2
  end
end 