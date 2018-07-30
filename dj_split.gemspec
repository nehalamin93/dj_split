
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dj_split/version"

Gem::Specification.new do |spec|
  spec.name          = "dj_split"
  spec.version       = DjSplit::VERSION
  spec.authors       = ["Md Nehal Amin"]
  spec.email         = ["nehalamin93@gmail.com"]

  spec.summary       = %q{Splitting, Enqueuing and Executing time taking jobs(eg: Delayed Job) without Blocking.}
  spec.description   = %q{Gem is designed to Split Time Taking Jobs(delayed jobs, crons, bulk operations, etc.) into smaller size independent Delayed Jobs. These Delayed Jobs can pick by multiple workers in single or multiple servers. After splitting and enqueuing, the gem will wait for the sub-jobs to be complete and also process sub-jobs instead of blocking.}
  spec.homepage      = ""
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "5.11.3"

  spec.add_dependency 'delayed_job', '>= 3.0'
  spec.add_dependency 'sqlite3'
  spec.add_dependency 'delayed_job_active_record', '>= 0.4'
  spec.add_development_dependency 'rails'
end
