Gem::Specification.new do |s|
  s.name        = 'sequel-geocoder'
  s.version     = '0.1.0'
  s.date        = '2014-03-04'
  s.summary     = 'Allows Sequel models to be used with the Geocoder gem.'
  s.description = s.summary
  s.author      = 'Joshua Hansen'
  s.email       = 'joshua@epicbanality.com'
  s.files       = Dir.glob('lib/**/*')
  s.homepage    = 'https://github.com/binarypaladin/sequel-geocoder'
  s.license     = 'MIT'

  s.add_runtime_dependency 'sequel'
  s.add_runtime_dependency 'geocoder'
end
