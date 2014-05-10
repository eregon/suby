Gem::Specification.new do |s|
  s.name = 'suby'
  s.summary = "Subtitles' downloader"
  s.description = "Find and download subtitles"
  s.author = 'eregon'
  s.email = 'eregontp@gmail.com'
  s.homepage = 'https://github.com/eregon/suby'
  s.license = 'MIT'

  s.files = Dir['bin/*', 'lib/**/*.rb', '.gitignore', 'README.md', 'suby.gemspec']
  s.executables = ['suby']

  s.required_ruby_version = '>= 1.9.2'
  s.add_dependency 'path', '~> 1.3'
  s.add_dependency 'nokogiri', '~> 1.6'
  s.add_dependency 'rubyzip', '~> 1.1'
  s.add_dependency 'term-ansicolor', '~> 1.2'
  s.add_dependency 'mime-types', '~> 1.19'

  s.version = '0.4.4'
end
