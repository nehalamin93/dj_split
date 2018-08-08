require "test_helper"
require "break"

class DjSplitTest < ActiveSupport::TestCase

  def test_that_it_has_a_version_number
    assert_equal '1.1.0', ::DjSplit::VERSION
  end

  def test_dj_testing
    assert_difference 'Delayed::Job.count', 1 do
      Break.create(text: "split").delay.whatever
    end
  end

  def test_split
    Delayed::Job.delete_all
    t = Time.now
    DjSplit::Split.new(queue_options: {}, split_options: {size: 10, by: 2}).enqueue(Break, "aggr", Array(0...20))
    assert_equal 2, (Time.now - t).to_i
    assert_equal 0, Delayed::Job.count
  end

  def test_enqueue
    Delayed::Job.delete_all
    mock_obj = mock()
    Delayed::PerformableMethod.stubs(:new).returns(mock_obj)
    Delayed::Job.expects(:enqueue).once 
    DjSplit::Split.new(queue_options: {queue: "high_priority"}, split_options: {size: 1000, by: 2}).enqueue(Break, "aggr", Array(0...100))
    assert_equal 0, Delayed::Job.count
  end

  def test_failed_jobs
    Delayed::Job.delete_all
    # Insert failed Job for testing handling failed jobs case:
    queue_name = "high_priority"
    user_ids = Array(0..5)
    Break.delay({queue: queue_name}).aggr(user_ids)
    Delayed::Job.where(queue: queue_name).update_all(run_at: Time.now, locked_at: Time.now, failed_at: Time.now, split_group_id: "99")
    begin
      DjSplit::Split.any_instance.stubs(:get_random_split_group_id).returns("99")
      DjSplit::Split.new(queue_options: {queue: queue_name}, split_options: {size: 10, by: 2}).enqueue(Break, "aggr", user_ids)
    rescue => e
      assert_equal true, e.message.starts_with?("Failed Delayed Jobs of Group Id(99):")
    end
    Delayed::Job.where(queue: queue_name).delete_all
  end

  def test_handle_stale_jobs
    Delayed::Job.delete_all
    # Insert stale Job for testing handling failed jobs case:
    user_ids = Array(0..5)
    queue_name = "high_priority"
    Break.delay({queue: queue_name}).aggr(user_ids)
    Delayed::Job.where(queue: queue_name).update_all(run_at: Time.now, locked_at: Time.now, locked_by:"host:Nehal pid:XXXX", split_group_id: "99")
    begin
      DjSplit::Split.any_instance.stubs(:get_delayed_jobs_pids).returns([])
      DjSplit::Split.any_instance.stubs(:check_stale_jobs?).returns(true)
      DjSplit::Split.new(queue_options: {queue: queue_name}, split_options: {size: 10, by: 2}).enqueue(Break, "aggr", user_ids)
    rescue => e
      assert_equal true, e.message.starts_with?("Stale Delayed Jobs of Group Id(99):")
    end
    Delayed::Job.where(queue: queue_name).delete_all
  end
end

