# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "test-patient-generator"
  s.summary = "A utility to generate patients for unit testing clinical quality measure logic."
  s.description = "A utility to generate patients for unit testing clinical quality measure logic. The instructions for generation are guided by HQMF documents and exported into various health standards, e.g. C32, CCR."
  s.email = "talk@projectpophealth.org"
  s.homepage = "https://github.com/pophealth/test-patient-generator"
  s.authors = ["Adam Goldstein"]
  s.version = '1.1.2'

  s.add_dependency 'health-data-standards', '~> 2.2.1'
  s.add_dependency 'hquery-patient-api', '~> 1.0.0'
  s.add_dependency 'hqmf-parser', '~> 1.1.0'
  s.add_dependency 'hqmf2js', '~> 1.1.0'
  s.add_dependency 'qrda_generator', '~> 1.0.1'

  s.files = Dir.glob('lib/**/*.rb') + ["Gemfile", "Rakefile", "public/cda.xsl"]
end
