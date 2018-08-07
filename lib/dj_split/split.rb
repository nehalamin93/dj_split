module DjSplit
  class Split

    OPTIMAL_SPLIT_SIZE = 200
    DEFAULT_SPLIT_INDEX = 2
    STALE_JOBS_TIMEOUT = 900 # Seconds. Can be passed in options.
    SLEEP_TIME = 0.2 # Seconds.

    def initialize(options)
      @queue_options  = options[:queue_options] || {}
      @split_group_id = get_random_split_group_id
      @queue_options.merge!(split_group_id: @split_group_id)
      @split_options = options[:split_options] || {}
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
      worker_object.split_group_id = @split_group_id
      worker_object.work_off(1)
    end

    def pending_jobs_of_group_id?
      Delayed::Job.where(split_group_id: @split_group_id, locked_at: nil).exists?
    end

    def waiting_for_other_workers_to_process_jobs
      count = 0
      while(jobs_processed_by_other_workers_currently?)
        count += 1
        sleep(SLEEP_TIME)
        handle_stale_jobs if check_for_timeout?(count)
      end
    end

    # Raise an error in scenario such as: Job is locked by a worker and worker got killed
    def handle_stale_jobs
      stale_jobs = get_processing_jobs_by_other_workers
      raise "Stale Delayed Jobs of Group Id(#{@split_group_id}): #{stale_jobs.pluck(:id)}"
    end

    def get_processing_jobs_by_other_workers
      Delayed::Job.where(split_group_id: @split_group_id, failed_at: nil).where.not(locked_by: nil)
    end

    def handle_failed_jobs
      failed_jobs = Delayed::Job.where(split_group_id: @split_group_id).where.not(failed_at: nil)
      raise "Failed Delayed Jobs of Group Id(#{@split_group_id}): #{failed_jobs.pluck(:id)}" if failed_jobs.exists?
    end

    def jobs_processed_by_other_workers_currently?
      Delayed::Job.where(split_group_id: @split_group_id, failed_at: nil).exists?
    end

    def get_split_size
      @split_options[:size] || OPTIMAL_SPLIT_SIZE
    end

    def get_stale_job_timeout_value
      @split_options[:timeout] || STALE_JOBS_TIMEOUT
    end

    def get_sliced_ids(ids)
      ids.each_slice(get_split_size)
    end

    def get_splitting_index
      (@split_options[:by] || DEFAULT_SPLIT_INDEX) - 2
    end

    # Collision is still OK. Probabilty of collision is negligible. 
    def get_random_split_group_id
      Time.now.to_i.to_s[5..-1] + rand(1000000000).to_s
    end

    # Check whether the timeout is reached?
    def check_for_timeout?(count)
      (SLEEP_TIME * count) > get_stale_job_timeout_value
    end
  end 
end