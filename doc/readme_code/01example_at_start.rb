def source_of_the_trouble
  in_the_middle
end

def in_the_middle
  frequently_called
end

def frequently_called
  puts "I'm called all the time."
end

1000.times { in_the_middle }
source_of_the_trouble