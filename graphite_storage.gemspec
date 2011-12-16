# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "graphite_storage/version"

Gem::Specification.new do |s|
  s.name        = "graphite_storage"
  s.version     = GraphiteStorage::VERSION
  s.authors     = ["Michael Leinartas"]
  s.email       = ["mleinartas@gmail.com"]
  s.homepage    = "https://github.com/mleinart/graphite_storage"
  s.summary     = %q{A Ruby interface to Graphite's storage formats}
  s.description = %q{A Ruby interface to Graphite's storage formats: Whisper and Ceres}

  s.rubyforge_project = "graphite_storage"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec"
end
