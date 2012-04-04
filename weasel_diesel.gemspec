# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "weasel_diesel/version"

Gem::Specification.new do |s|
  s.name        = "weasel_diesel"
  s.version     = WeaselDiesel::VERSION
  s.authors     = ["Matt Aimonetti"]
  s.email       = ["mattaimonetti@gmail.com"]
  s.homepage    = "https://github.com/mattetti/Weasel-Diesel"
  s.summary     = %q{Web Service DSL}
  s.description = %q{Ruby DSL describing Web Services without implementation details.}

  s.rubyforge_project = "wsdsl"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec"
  s.add_development_dependency "rack-test"
  s.add_development_dependency "yard"
  s.add_development_dependency "sinatra"
  if RUBY_VERSION =~ /1.8/
    s.add_runtime_dependency "backports"
    s.add_runtime_dependency "json"
  end
end
