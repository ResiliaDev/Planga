Gem::Specification.new do |s|
  s.name         = 'planga'
  s.version      = '0.0.1'
  s.date         = '2018-09-13'
  s.summary      = "Planga"
  s.description  = "Wrapper for interacting with the Planga chat server."
  s.authors      = ["Wiebe Marten Wijnja", "Jeroen Hoekstra"]
  s.files        = Dir['README.md', 'VERSION', 'Gemfile', 'Rakefile', '{bin,lib,config,vendor}/**/*']
  s.require_path = 'lib'
  s.homepage     = 'https://github.com/ResiliaDev/Planga'
  s.license      = 'MIT'

  s.add_dependency('jose')
end