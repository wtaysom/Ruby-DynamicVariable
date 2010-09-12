def simple_with(value)
  old_value = $value
  $value = value
  yield
ensure
  $value = old_value
end


describe '#simple_with' do it "should behave" do

simple_with(3) do
  simple_with(4) do
    $value.should == 4
  end
  $value.should == 3
end
$value.should == nil

end end