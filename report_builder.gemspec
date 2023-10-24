Gem::Specification.new do |s|
  s.name                              = 'report_builder'
  s.metadata['rubygems_mfa_required'] = 'true'
  s.version                           = '1.9.1'
  s.bindir                            = 'bin'
  s.summary                           = 'ReportBuilder'
  s.description                       = 'Ruby gem to merge Cucumber JSON reports and build mobile-friendly HTML Test Report, JSON report and retry file.'
  s.post_install_message              = 'Happy reporting!'
  s.authors                           = ['Jason Phebus']
  s.email                             = 'phebus@gmail.com'
  s.license                           = 'MIT'
  s.required_ruby_version             = '>= 3.2.0'
  s.requirements << 'Cucumber >= 2.1.0 test results in JSON format'

  s.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(sample/|css/|js/|pkg/|spec/|coverage/|.gitignore|_config.yml|Gemfile|Rakefile|rb.ico)}) }
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }

  s.add_runtime_dependency 'json', '>= 2.3.0'
end
