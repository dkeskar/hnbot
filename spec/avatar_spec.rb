require "#{File.dirname(__FILE__)}/spec_helper"

describe 'avatar' do
  before(:each) do
    @avatar = Avatar.new(:name => 'test user')
  end

  specify 'should be valid' do
    @avatar.should be_valid
  end

  specify 'should require a name' do
    @avatar = Avatar.new
    @avatar.should_not be_valid
    @avatar.errors[:name].should include("can't be empty")
  end
end
