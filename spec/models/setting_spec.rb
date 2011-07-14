require 'spec_helper'

describe Setting do
  describe '#setval' do
    it 'should set 10 for property test' do
      Setting.setval(:test, 10)
      Setting.find_by_name(:test).value.should == '10'
    end
  end

  describe '#getval' do
    it 'should get 10 for property test' do
      Setting.setval(:test, 10)
      Setting.getval(:test).should == 10
    end
  end

  describe '#remove' do
    it 'should remove property test' do
      Setting.setval(:test, 10)
      Setting.remove :test
      Setting.find_by_name(:test).should be_nil
    end
  end
end
 
