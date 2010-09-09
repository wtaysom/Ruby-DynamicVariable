require 'rubygems'
require 'ruby-debug'
require 'dynamic_variable'

@troubled = DynamicVariable.new(false)

def source_of_the_trouble
  @troubled.with(true) { in_the_middle }
end

def in_the_middle
  frequently_called
end

def frequently_called  
  debugger if @troubled.value
  puts "I'm called all the time."
end

1000.times { in_the_middle }
source_of_the_trouble