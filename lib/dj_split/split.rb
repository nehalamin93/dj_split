# 
# Class is designed to Split Time Taking Delayed Jobs, Crons, Bulk Operations, etc into smaller size multiple Delayed Jobs.
# These Jobs should be Independent of each other.
# Splitting will be done on one parameter only.
#
# Purpose: To distribute the load among multiple application servers.
#
# Usage:
# => DjSplit::Split.new(queue_options: {queue: queue_name}, split_options: {size: 1000, by: 2}).enqueue(match_client, "bulk_mentor_match", student_ids, mentor_ids)
# instead of:
# => match_client.bulk_mentor_match(student_ids, mentor_ids)
#
# Note: Arguments must be in exact order.
# "enqueue" parameters are (object, function_name, arguments of that function)
# split_options[:size] is splitting size
# split_options[:by] is position of splitting attribute in the enqueue function. In above example, splitting attribute is student_ids and has position 2(>=2).
#
# Here we are splitting on the basis of student_ids. 
# We can also specify the :splitting_size, Otherwise it will take default Optimal Splitting Size
# After splitting and enqueing, we wait for the sub-jobs to be complete and also process subjobs instead of blocking.
#
# Steps:
# => 1) Split splitting params into array of arrays. Each array element is of size <= split_options[:size]   
# => 2) Loop through the array and insert it into Delayed Job queue(array element is placed in place of splitting params)
# => 3) Queue jobs will be picked and executed by workers
# => 4) Instead of waiting for jobs to be picked and processed by workers we will also pick and process those job
#
#
module DjSplit
  class Split

    OPTIMAL_SPLIT_SIZE = 200
    DEFAULT_SPLIT_INDEX = 2

    def initialize(options)
      @queue_options  = options[:queue_options]
      @job_group_id = get_random_job_group_id
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
      Delayed::Job.where(job_group_id: @job_group_id, locked_at: nil).exists?
    end

    def waiting_for_other_workers_to_process_jobs
      count = 0
      while(jobs_processed_by_other_workers_currently?)
        count += 1
        sleep(1.0/5.0)
        handle_stale_jobs if check_stale_jobs?(count)
      end
    end

    # handles a scenario when Job is locked by a worker and worker got killed
    def handle_stale_jobs
      stale_jobs = get_processing_jobs_by_other_workers.select{ |dj| !get_delayed_jobs_pids.include?(dj.locked_by.split("pid:")[1].strip) }
      raise "Stale Delayed Jobs of Group Id(#{@job_group_id}): #{stale_jobs.pluck(:id)}" if stale_jobs.present?
    end

    def get_processing_jobs_by_other_workers
      Delayed::Job.where(job_group_id: @job_group_id, failed_at: nil).where.not(locked_by: nil)
    end

    def get_delayed_jobs_pids
      bash_op = `ps aux | grep delayed_job  | grep -v 'grep' | grep -v 'bin/sh' | grep -v 'tail' | grep -v 'ruby' | grep -v 'trace'` 
      processes = bash_op.split("\n")
      pid_array = []
      processes.each do |process|
        split_process = process.split(" ")
        pid_array << split_process[1]
      end
      pid_array
    end

    def handle_failed_jobs
      failed_jobs = Delayed::Job.where(job_group_id: @job_group_id).where.not(failed_at: nil)
      raise "Failed Delayed Jobs of Group Id(#{@job_group_id}): #{failed_jobs.pluck(:id)}" if failed_jobs.exists?
    end

    def jobs_processed_by_other_workers_currently?
      Delayed::Job.where(job_group_id: @job_group_id, failed_at: nil).exists?
    end

    def get_split_size
      @split_options[:size] || OPTIMAL_SPLIT_SIZE
    end

    def get_sliced_ids(ids) 
      ids.each_slice(get_split_size)
    end

    def get_splitting_index
      (@split_options[:by] || DEFAULT_SPLIT_INDEX) - 2
    end

    # Collision is still OK. Probabilty of collision is negligible. 
    def get_random_job_group_id
      Time.now.to_i.to_s[5..-1] + rand(1000000000).to_s
    end

    # Check for stale jobs 1 out of 2000 times.
    def check_stale_jobs?(count)
      (count%2000 == 1999) 
    end
  end 
end