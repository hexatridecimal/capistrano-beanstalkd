# -*- encoding: utf-8 -*-

require File.expand_path("../lib/capistrano-beanstalkd/version", __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "capistrano-beanstalkd"
  gem.version     = CapistranoBeanstalkd::VERSION.dup
  gem.author      = "Jonathan Jeffus"
  gem.email       = "jjeffus@gmail.com"
  gem.homepage    = "https://github.com/jjeffus/capistrano-beanstalkd"
  gem.summary     = %q{beanstalkd integration for Capistrano}
  gem.description = %q{Capistrano plugin that integrates beanstalkd server tasks.}

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{|f| File.basename(f)}
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "capistrano"
  gem.add_runtime_dependency "backburner"
end
