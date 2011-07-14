require 'spec_helper'

describe Stream do
  before :all do
    Factory :patio11_avatar 
  end

  describe '#create' do
    it 'should create new stream record' do
      stream = Stream.create :sid => 1, :title => 'Test', :config => {:user => 'patio11'}
      stream.should_not be_nil
      stream.sid.should == 1
      stream.title.should == 'Test'
    end
  end
end
