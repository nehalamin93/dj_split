module Delayed
  module Backend
    module ActiveRecord
      class Job < ::ActiveRecord::Base
        def self.reserve(worker, max_run_time = Worker.max_run_time)
          # scope to filter to records that are "ready to run"
          ready_scope = ready_to_run(worker.name, max_run_time)

          # scope to filter to the single next eligible job
          ready_scope = ready_scope.where("priority >= ?", Worker.min_priority) if Worker.min_priority
          ready_scope = ready_scope.where("priority <= ?", Worker.max_priority) if Worker.max_priority
          unless worker.split_group_id
            ready_scope = ready_scope.where(queue: Worker.queues) if Worker.queues.any?
          end
          # filter only jobs with worker job group id
          ready_scope = ready_scope.where(split_group_id: worker.split_group_id) if worker.split_group_id
          ready_scope = ready_scope.by_priority

          reserve_with_scope(ready_scope, worker, db_time_now)
        end
      end
    end
  end
end
