# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ferb}
  s.version = "0.6"

  s.required_rubygems_version = nil if s.respond_to? :required_rubygems_version=
  s.authors = ["Jim Powers"]
  s.autorequire = %q{erb}
  s.cert_chain = nil
  s.date = %q{2009-08-01}
  s.email = %q{jim@corruptmemory.com}
  s.extra_rdoc_files = ["README", "LGPL30"]
  s.files = ["lib/ferb.rb", "lib/method_args.rb", "lib/ferb_helper.rb", "README"]
  s.has_rdoc = true
  s.homepage = %q{http://www.corruptmemory.com/}
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new("> 0.0.0")
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Makes it easy to write functions that expand to arbitrary tempaltes using ERB}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 1

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
