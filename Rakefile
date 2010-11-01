begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "dynamic_variable"
    gemspec.summary = "Provides dynamically scoped variables."
    gemspec.description = "Occasionally a method's behavior should depend on the context in which it is called. What is happening above me on the stack? DynamicVariable helps you in these context dependent situations."
    gemspec.email = "wtaysom@gmail.com"
    gemspec.homepage = "http://github.com/wtaysom/Ruby-DynamicVariable"
    gemspec.authors = ["William Taysom"]
    
    gemspec.add_development_dependency('jeweler', '~> 1.4')
    gemspec.add_development_dependency('rspec', '~> 2.0')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end