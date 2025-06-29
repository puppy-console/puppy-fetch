Gem::Specification.new do |s|
  s.name          = "puppy-fetch"
  s.version       = "1.0.0"
  s.summary       = "Github branch intersection command line tool"
  s.description   = "Gets intersecting files between branches on GitHub"
  s.authors       = ["puppy-tools", "nik0-dev"]
  s.bindir        = 'bin'
  s.require_paths = ["lib"]
  s.files         = Dir["lib/**/*.rb"] + Dir['bin/*'] + ["README.md", "LICENSE"]
  s.homepage      = "https://github.com/puppy-tools/puppy-fetch"
  s.license       = "MIT"
  s.executables << "puppy-fetch"
end