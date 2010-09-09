# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dynamic_variable}
  s.version = "0.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["William Taysom"]
  s.date = %q{2010-09-09}
  s.description = %q{Occasionally a method's behavior should depend on the context in which it is called. What is happening above me on the stack? DynamicVariable helps you in these context dependent situations.}
  s.email = %q{wtaysom@gmail.com}
  s.extra_rdoc_files = [
    "README.md"
  ]
  s.files = [
    ".gitignore",
     "README.md",
     "Rakefile",
     "VERSION",
     "doc/readme_code/01example_at_start.rb",
     "doc/readme_code/02example_with_debug.rb",
     "doc/readme_code/03simple_with.rb",
     "lib/dynamic_variable.rb",
     "spec/dynamic_variable_spec.rb"
  ]
  s.homepage = %q{http://github.com/wtaysom/Ruby-DynamicVariable}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Provides dynamically scoped variables.}
  s.test_files = [
    "spec/dynamic_variable_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

