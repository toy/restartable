# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = 'restartable'
  s.version     = '1.0.1'
  s.summary     = %q{Run code, Ctrl-C to restart, once more Ctrl-C to stop}
  s.homepage    = "http://github.com/toy/#{s.name}"
  s.authors     = ['Ivan Kuchin']
  s.license     = 'MIT'

  s.rubyforge_project = s.name

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w[lib]

  s.add_dependency 'colored', '~> 1.2'
  s.add_dependency 'sys-proctable', '~> 0.9.3'
  s.add_development_dependency 'cucumber'
  if RUBY_VERSION >= '2.1'
    s.add_development_dependency 'rubocop', '~> 0.53'
  end
end
