require File.dirname(__FILE__)+'/../../lib/dynamic_variable'

describe 'DynamicVariable::Mixin' do it "should behave" do

class MixinExample
  include DynamicVariable::Mixin

  attr_accessor :x

  def try
    self.x = 4
    x.should == 4
    with(:x, 3) do
      x.should == 3
      self.x = 2
      x.should == 2
      with(:x, 1) do
        x.should == 1
      end
      x.should == 2
    end
    x.should == 4
  end
end

MixinExample.new.try

end end