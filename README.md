# Delayed Job Split Feature

Class [**"DjSplit::Split"**](https://github.com/nehalamin93/dj_split/blob/master/lib/dj_split/split.rb) is designed to **Split Time Taking Delayed Jobs, Crons, Bulk Operations, etc** into **smaller size multiple Delayed Jobs**.
These **Jobs** should be **mutually exclusive** of each other and should be able to run **concurrently**.

These **Jobs** can be picked by **Delayed Job Workers** within or across **Multiple Servers**.

Performance can improve up to n+1 times, where n = number of workers picking the jobs.

Class behaves like **Delayed Job Worker**, it also **picks and processes delayed job** entries.

**Splitting** will be done on **one parameter** only.

## Purpose

To distribute the load among **Multiple Workers**.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dj_split'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install dj_split

Run the required database migrations:

    $ script/rails generate dj_split
    $ rake db:migrate

## Usage

```ruby
class A
  def self.function1(user_ids_array1, other_attr1)
    #do something
  end
end
```
      $ A.delay(queue: queue_name).function1(user_ids_array1, other_attr1)

  can be replace by:

      $ DjSplit::Split.new(queue_options: {queue: queue_name}, split_options: {size: 1000, by: 2}).enqueue(A, "function1", user_ids_array1, other_attr1)

## Note

* Arguments must be in exact order.
* "enqueue" parameters are (object/class, function_name, arguments of that function)
* split_options[:size] is splitting size
* split_options[:by] is position of splitting attribute in the enqueue function. In above example, splitting attribute is user_ids_array1 and has position 2(>=2).

* Here we are splitting on the basis of user_ids_array1. 
* We can also specify the: splitting_size, Otherwise it will take default Optimal Splitting Size
* After splitting and enqueuing, instead of waiting for the sub-jobs to be complete this function will behave like delayed job worker and will pick and process the sub-jobs instead of blocking.

## What DjSplit::Enqueue does

* Split the mentioned parameter into array of chunks(arrays) of size = split_options[:size]. 
* Loop through the array and insert each chunk into Delayed Job queue(array element is placed in place of splitting params)
* Queue jobs will be picked and executed by workers
* Instead of waiting for jobs to be picked and processed by workers this function will also pick and process those job

## Contributing

* Bug reports and pull requests are welcome on GitHub at https://github.com/nehalamin93/dj_split.
* Fork it
* Create your feature branch (git checkout -b my-new-feature)
* Commit your changes (git commit -am 'Add some feature')
* Push to the branch (git push origin my-new-feature)
* Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DjSplit project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/nehalamin93/dj_split/blob/master/CODE_OF_CONDUCT.md).

<!-- ## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org). -->
