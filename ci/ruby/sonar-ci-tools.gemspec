Gem::Specification.new do |s|
  s.name        = 'sonar-ci-tools'
  s.version     = '0.1.0'
  s.summary     = "CI tooling for Sonar project"
  s.authors     = ["NHSX"]
  s.files       = Dir.glob('lib/**/*')
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'minitest-reporters'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'webmock'
end
