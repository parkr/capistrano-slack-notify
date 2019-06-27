# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "capistrano-slack-notify"
  spec.version       = "1.3.4"
  spec.authors       = ["Parker Moore"]
  spec.email         = ["parkrmoore@gmail.com"]
  spec.summary       = %q{Minimalist Capistrano 2 notifier for Slack.}
  spec.homepage      = "https://github.com/parkr/capistrano-slack-notify"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").grep(%r{^(bin|lib)/})
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "capistrano", "~> 2.10"

  spec.add_development_dependency "rake", "~> 10.0"
end
