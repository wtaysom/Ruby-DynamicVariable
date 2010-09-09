# Introduction

Occasionally a method's behavior should depend on the context in which it is called.  What is happening above me on the stack?  DynamicVariable helps you in these context dependent situations.

DynamicVariable is similar to [dynamic scope](http://c2.com/cgi/wiki?DynamicScoping), [fluid-let](http://www.megasolutions.net/scheme/fluid-binding-25366.aspx), [SRFI 39 parameters](http://srfi.schemers.org/srfi-39/srfi-39.html), [cflow pointcuts](http://www.eclipse.org/aspectj/doc/released/progguide/semantics-pointcuts.html#d0e5410), even [Scala has its own DynamicVariable](http://www.scala-lang.org/api/current/scala/util/DynamicVariable.html).

# Example: Context Dependent Debugging

Suppose we have a method which is `frequently_called`.  It works fine except when called from `source_of_the_trouble`.  Suppose further that `source_of_the_trouble` doesn't directly invoke `frequently_called` instead there's a method `in_the_middle`.  Our setup looks like this:

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

With DynamicVariable, we can easily change `frequently_called` so that it only brings up the `debugger` when called from `source_of_the_trouble`:

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

# Typical Usage

A DynamicVariable storing one `:value` and then `:another`:

	DynamicVariable.new(1) do |dv|
	  dv.value.should == 1
	  dv.value = 2
	  dv.value.should == 2

	  dv.with(:another, :middle, 3) do
	    dv.another.should == :middle
	    dv.value.should == 3

	    dv.with(:another, :inner, 4) do
	      dv.another.should == :inner
	      dv.value.should == 4
	    end

	    dv.another.should == :middle
	    dv.value.should == 3
	  end

	  expect do
	    dv.another
	  end.should raise_error(ArgumentError, "unbound variable :another")
	  dv.value.should == 2
	end

# Why have a library?

Isn't it easy to set and reset a flag as the context changes?  Sure, just watch out for raise, throw, and nesting:

	def simple_with(value)
	  old_value = $value
	  $value = value
	  yield
	ensure
	  $value = old_value
	end

DynamicVariable adds the ability to reflect on your bindings.  You can inspect them, and you can tinker with them if you feel the need:

	dv = DynamicVariable.new(:v, 1, :w, 2) do |dv|
	  dv.with(:w, 3) do
	    dv.with(:v, 4) do
	      dv.bindings.should == [[:v, 1], [:w, 2], [:w, 3], [:v, 4]]
	      dv.bindings(:v).should == [1, 4]
	      dv.bindings(:w).should == [2, 3]

	      dv.set_bindings(:v, [-1, -2, -3])
	      dv.set_bindings(:w, [-4])
	      dv.bindings.should == [[:v, -1], [:w, -4], [:v, -2], [:v, -3]]
	    end

	    dv.bindings.should == [[:v, -1], [:w, -4], [:v, -2]]
	  end

	  dv.bindings.should == [[:v, -1], [:v, -2]]
	end

	dv.bindings.should == [[:v, -1]]

	dv.bindings = []
	dv.bindings.should == []