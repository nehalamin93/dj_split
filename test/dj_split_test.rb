require "test_helper"
require "break"

class DjSplitTest < ActiveSupport::TestCase

  def test_that_it_has_a_version_number
    assert_equal '0.1.0', ::DjSplit::VERSION
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
end

