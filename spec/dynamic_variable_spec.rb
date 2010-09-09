require 'dynamic_variable'
  
describe DynamicVariable do
  subject { DynamicVariable.new }
  
  before do
    extend subject.with_module
  end
  
  ### Utilities ###
  
  def x_and_y_bindings
    [[:x, 1], [:y, 2], [:y, 3], [:x, 4]]
  end
  
  def set_x_any_y_bindings
    subject.bindings = x_and_y_bindings
  end
  
  def bindings_should_equal_x_and_y_bindings
    subject.bindings.should == x_and_y_bindings
  end
  
  def bindings_should_be_empty
    subject.bindings.should == []
  end
  
  def expect_should_raise_unbound_variable(&block)
    expect do
      block[]
    end.should raise_error ArgumentError, "unbound variable :z"
  end
  
  ### Examples ###
  
  example "typical usage" do
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
  end
  
  example "reflection" do
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
  end
  
  describe '.new' do
    context "when called" do
      context "with no arguments" do        
        it "should have no bindings" do
          DynamicVariable.new.bindings.should == []
        end
      end
      
      context "with one argument" do
        it "should bind :value to argument" do
          DynamicVariable.new(:argument).bindings.should ==
            [[:value, :argument]]
        end
      end
      
      context "with two arguments" do
        it "should bind the first to the second" do
          DynamicVariable.new(:first, :second).bindings.should ==
            [[:first, :second]]
        end
      end
      
      context "with an odd number of arguments" do
        it "should bind :value to the second to last" do
          DynamicVariable.new(:first, :second, :last).bindings.should == 
            [[:first, :second], [:value, :last]]
        end
      end
      
      context "with an even number of arguments" do
        it "should bind variable, value pairs" do
          DynamicVariable.new(:var1, :val1, :var2, :val2, :var3,
            :val3).bindings.should ==
              [[:var1, :val1], [:var2, :val2], [:var3, :val3]]
        end
      end
      
      context "with a block" do
        it "should pass self to the block" do
          dv_in_block = nil;
          dv = DynamicVariable.new do |dv|
            dv.should be_a(DynamicVariable)
            dv.value.should == nil
            dv_in_block = dv
          end
          dv.should == dv_in_block
          expect do
            dv.value
          end.should raise_error(ArgumentError, "unbound variable :value")
        end
      end
    end
  end
  
  describe '#push' do
    it "should return the binding pair" do
      subject.push(:x, 1).should == [:x, 1]
    end
    
    it "should add binding pairs" do
      subject.push(:x, 1)
      subject.push(:y, 2)
      subject.push(:z, 3)
      subject.push(:x, 4)
      
      subject.bindings.should == [[:x, 1], [:y, 2], [:z, 3], [:x, 4]]
    end
    
    it "should allow a variable to be any object" do
      subject.push(1337, 1)
      subject.push(nil, 2)
      subject.push("", 3)
      subject.push([], 4)
      
      subject.bindings.should == [[1337, 1], [nil, 2], ["", 3], [[], 4]]
    end
  end
  
  describe '#pop' do
    before { set_x_any_y_bindings }
    
    it "should return the value of the variable" do
      subject.pop(:x).should == 4
    end
    
    it "should remove last occurence of variable" do
      subject.pop(:x)
      subject.bindings.should == [[:x, 1], [:y, 2], [:y, 3]]
      
      subject.pop(:x)
      subject.bindings.should == [[:y, 2], [:y, 3]]
    end
    
    it "should remove last occurence leaving other variables in order" do
      subject.pop(:y)
      subject.bindings.should == [[:x, 1], [:y, 2], [:x, 4]]
      
      subject.pop(:y)
      subject.bindings.should == [[:x, 1], [:x, 4]]
    end
    
    context "when variable is not found" do
      it "should return nil and do nothing" do
        subject.pop(:z).should == nil
        bindings_should_equal_x_and_y_bindings
      end
    end
  end
  
  describe '#with' do
    it "should make bindings and clean up when done" do
      with(:key, :value) do
        subject.bindings.should == [[:key, :value]]
      end
      bindings_should_be_empty
    end
    
    it "should yield self to the block" do
      with do |dv|
        dv.should == subject
      end
    end
    
    it "should return the result of its block" do
      with{:result}.should == :result
    end
    
    it "should nest nicely" do
      with(:value) do
        subject.bindings.should == [[:value, :value]]
        with(:second_value) do
          subject.bindings.should == [[:value, :value], [:value, :second_value]]
        end
        subject.bindings.should == [[:value, :value]]
      end
      bindings_should_be_empty
    end
    
    it "should be exception safe" do
      expect do
        with(:value) do
          subject.bindings.should == [[:value, :value]]
          raise
        end
      end.should raise_error
      bindings_should_be_empty
    end
    
    context "when called" do
      context "with no arguments" do
        it "should bind :value to nil" do
          with do
            subject.bindings.should == [[:value, nil]]
          end
        end
      end
      
      context "with one argument" do
        it "should bind :value to argument" do
          with(:argument) do
            subject.bindings.should == [[:value, :argument]]
          end
        end
      end
      
      context "with two arguments" do
        it "should bind the first to the second" do
          with(:first, :second) do
            subject.bindings.should == [[:first, :second]]
          end
        end
      end
      
      context "with an odd number of arguments" do
        it "should bind :value to the second to last" do
          with(:first, :second, :last) do
            subject.bindings.should == [[:first, :second], [:value, :last]]
          end
        end
      end
      
      context "with an even number of arguments" do
        it "should bind variable, value pairs" do
          with(:var1, :val1, :var2, :val2, :var3, :val3) do
            subject.bindings.should ==
              [[:var1, :val1], [:var2, :val2], [:var3, :val3]]
          end
        end
      end
      
      context "with a variable repeated more than once" do
        it "should bind the variable twice and unbind when done" do
          with(:var, 1, :var, 2) do
            subject.bindings.should == [[:var, 1], [:var, 2]]
          end
          subject.bindings.should == []
        end
      end
      
      context "without a block" do
        it "should raise \"no block given\"" do
          expect do
            subject.with(:key, :value)
          end.should raise_error LocalJumpError, /no block given/
          bindings_should_be_empty
        end
      end
    end
  end
  
  describe '#with_module' do
    it "should return a Module with a #with method" do
      mod = subject.with_module
      mod.should be_a Module
      methods = mod.instance_methods(false)
      methods.map(&:to_sym).should == [:with]
    end
  end
  
  describe '#[]' do
    before { set_x_any_y_bindings }
    
    it "should return the nearest binding for a variable" do
      subject[:x].should == 4
      subject[:y].should == 3
    end
    
    context "when there is no binding" do
      it "should raise \"unbound variable\"" do
        expect_should_raise_unbound_variable do
          subject[:z]
        end
      end
    end
  end
  
  describe '#[]=' do
    before { set_x_any_y_bindings }
    
    it "should update nearest binding for a variable" do
      subject[:x] = -1
      subject[:y] = -2
      
      subject.bindings.should == [[:x, 1], [:y, 2], [:y, -2], [:x, -1]]
    end
    
    it "should return the value" do
      (subject[:x] = -1).should == -1
    end
    
    context "when there is no binding" do
      it "should raise \"unbound variable\"" do
        expect_should_raise_unbound_variable do
          subject[:z] = -2
        end
      end
    end
  end
  
  describe '#method_missing', " reader and writer generation" do
    before { set_x_any_y_bindings }
    
    it "should initially have no variable readers or writers defined" do
      subject.methods(false).should == []
    end
    
    it "should generate variable readers as needed" do
      subject.x.should == 4
      subject.methods(false).map(&:to_sym).should == [:x]
    end
    
    it "should generate variable writers as needed" do
      (subject.x = 4).should == 4
      subject.methods(false).map(&:to_sym).should == [:x=]
    end
    
    context "when variable is unbound" do
      it "should raise \"unbound variable\"" do
        expect_should_raise_unbound_variable do
          subject.z
        end
        
        expect_should_raise_unbound_variable do
          subject.z = 3
        end
      end
      
      it "should not generate readers or writers" do
        expect do
          subject.z
          subject.z = 3
        end.should raise_error
        
        subject.methods(false).should == []
      end
    end
    
    context "with to many arguments to be a writer" do
      it "should raise NoMethodError" do
        expect do
          subject.too_many(1, 2)
        end.should raise_error NoMethodError,
          /undefined method `too_many' for/
      end
    end
    
    context "with one argument but method name does not end in \"=\"" do
      it "should raise NoMethodError" do
        expect do
          subject.not_writer(1)
        end.should raise_error NoMethodError,
          /undefined method `not_writer' for/
      end
    end  
  end
  
  describe '#variables' do
    before { set_x_any_y_bindings }
    
    it "should return hash of all variables with their current bindings" do
      subject.variables.should == {:x => 4, :y => 3}
    end
  end
  
  describe '#variables=' do
    before { set_x_any_y_bindings }
    
    it "should update current bindings of variables" do
      subject.variables = {:x => -1, :y => -2}
      subject.bindings.should == [[:x, 1], [:y, 2], [:y, -2], [:x, -1]]
    end
    
    it "should return the variables" do
      variables = {:x => -1, :y => -2}
      (subject.variables = variables).should be_equal variables
    end
    
    it "should accept assoc array as argument" do
      subject.variables = [[:x, -1], [:y, -2]]
      subject.bindings.should == [[:x, 1], [:y, 2], [:y, -2], [:x, -1]]
    end
    
    context "when some variables are not mentioned" do
      it "should retain the old bindings" do
        subject.variables = {:y => -2}
        subject.bindings.should == [[:x, 1], [:y, 2], [:y, -2], [:x, 4]]
      end
    end
    
    context "when an unbound variable is mentioned" do
      it "should raise \"unbound variable\"" do
        expect_should_raise_unbound_variable do
          subject.variables = {:z => -3}
        end
      end
      
      it "should NOT update atomically" do
        expect_should_raise_unbound_variable do
          subject.variables = [[:y, -2], [:z, -3]]
        end
        subject.y.should == -2
      end
    end    
  end
  
  describe '#bindings' do
    before { set_x_any_y_bindings }
    
    context "with no argument" do
      it "should return an array of all variable bindings" do
        bindings_should_equal_x_and_y_bindings
      end
      
      it "should not be affected by changes to the returned array" do
        bindings = subject.bindings
        bindings[0][1] = -1
        bindings_should_equal_x_and_y_bindings
      end
    end
    
    context "with variable as argument" do
      it "should return array of all bindings for variable" do
        subject.bindings(:x).should == [1, 4]
        subject.bindings(:y).should == [2, 3]
      end
      
      context "when an unbound variable is used" do
        it "should return empty array" do
          subject.bindings(:z).should == []
        end
      end
    end
  end
  
  shared_examples_for "bindings writer" do       
    it "should update all bindings" do
      subject.send(bindings_writer, x_and_y_bindings)
      bindings_should_equal_x_and_y_bindings
    end
    
    it "should return the argument" do
      bindings = x_and_y_bindings
      subject.send(bindings_writer, bindings).should be_equal bindings
    end
    
    it "should use a copy of bindings" do
      bindings = x_and_y_bindings
      subject.send(bindings_writer, bindings)
      bindings[0][1] = -9
      bindings_should_equal_x_and_y_bindings
    end
    
    context "when bindings does not respond to #map" do
      it "should raise NoMethodError" do
        expect do
          subject.send(bindings_writer, :oops)
        end.should raise_error NoMethodError
        bindings_should_be_empty
      end
    end
    
    context "when a binding is not an Array" do
      it "should raise ArgumentError" do
        expect do
          subject.send(bindings_writer, [66])
        end.should raise_error ArgumentError,
          /expected \[variable, value\] pair, got/
        bindings_should_be_empty
      end
    end
    
    context "when a binding is of the wrong size" do
      it "should raise ArgumentError" do
        expect do
          subject.send(bindings_writer, [[1, 2, 3]])
        end.should raise_error ArgumentError,
          /expected \[variable, value\] pair, got/
        bindings_should_be_empty
      end
    end    
  end
  
  describe '#bindings=' do
    let(:bindings_writer) { :bindings= }
    
    it_should_behave_like "bindings writer"
  end
  
  describe '#set_bindings' do
    context "with one argument" do
      let(:bindings_writer) { :set_bindings }
      
      it_should_behave_like "bindings writer"
    end
    
    context "with two arguments" do
      before { set_x_any_y_bindings }
      
      it "should replace existing bindings for variable" do
        subject.set_bindings(:x, [-1, -2])
        subject.bindings.should == [[:x, -1], [:y, 2], [:y, 3], [:x, -2]]
      end
      
      it "should return the bindings array" do
        bindings = [-1, -2]
        subject.set_bindings(:x, bindings).should be_equal bindings
      end
      
      context "when there are fewer new bindings than existing bindings" do
        it "should delete bindings from the end" do
          subject.set_bindings(:x, [-1])
          subject.bindings.should == [[:x, -1], [:y, 2], [:y, 3]]
        end
      end
      
      context "when there are more new bindings than existing bindings" do
        it "should add bindings to the end" do
          subject.set_bindings(:x, [-1, -2, -3])
          subject.bindings.should ==
            [[:x, -1], [:y, 2], [:y, 3], [:x, -2], [:x, -3]]
        end
      end
      
      context "when argument is not an array" do
        it "should raise ArgumentError" do
          expect do
            subject.set_bindings(:x, :not_this)
          end.should raise_error ArgumentError,
            "expected bindings to be Array, got a Symbol"
        end
      end   
    end
  end
end