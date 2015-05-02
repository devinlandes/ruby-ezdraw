Gem::Specification.new do |s|
  s.name        = 'ezdraw'
  s.version     = File.read('VERSION').chomp
  s.date        = '2015-05-01'
  s.summary     = "Simple Processing-esq Drawing API"
  s.description = s.summary
  s.authors     = ["Devin Landes"]
  s.email       = 'devinlandes@users.noreply.github.com'
  s.files       = Dir['lib/*'] +
                  Dir['res/*'] +
                  Dir['examples/*']
  s.homepage    = 'https://github.com/devinlandes/ruby-ezdraw'
  s.license     = 'MIT'
end

