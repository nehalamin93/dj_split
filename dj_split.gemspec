
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dj_split/version"

Gem::Specification.new do |spec|
  spec.name          = "dj_split"
  spec.version       = DjSplit::VERSION
  spec.authors       = ["Md Nehal Amin"]
  spec.email         = ["nehalamin93@gmail.com"]

  spec.summary       = %q{Parallelise Time Taking Job across Multiple Processes in Single or Multiple Servers by Splitting into Delayed Jobs.}
  spec.description   = %q{Gem is designed to "Split or Break" Time Taking Jobs(Delayed Jobs, Crons, Bulk Operations, etc.) into smaller size Mutually Exclusive Delayed Jobs. These Sub-Jobs can be picked by multiple workers in Single or Multiple Servers. After splitting and enqueuing, the process will wait for the sub-jobs to complete and also processes sub-jobs instead of blocking. Parallelism can be achieved across multiple servers through Delayed Jobs which can directly impact performance. Performance can improve up to "n+1" times, where n = number of workers picking the jobs.}
  spec.homepage      = ""
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "5.11.3"
  spec.add_development_dependency 'rspec', '~> 3.6'
  spec.add_development_dependency "mocha", "~> 1.2"

  spec.add_dependency 'delayed_job', '>= 3.0'
  spec.add_dependency 'sqlite3'
  spec.add_dependency 'delayed_job_active_record', '>= 0.4'
  spec.add_development_dependency 'rails'
end
