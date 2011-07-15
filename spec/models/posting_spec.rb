require 'spec_helper'

describe Posting do
  before :all do
    @post_pid_1 = Factory :post_pid_1

    [3,4,5].each do |cid|
      Factory "comment_cid_#{cid}".to_sym
    end
  end

  describe '#add' do
    it 'should add new post with title Test Post' do
      Posting.add(:pid => 2, :title => 'Test Post').should be_true
      Posting.find_by_title('Test Post').should_not be_nil
    end
  end

  describe '#bump' do
    it 'should increment wacx value to one' do
      wacx = @post_pid_1.wacx
      Posting.bump(1)
      Posting.find_by_pid(@post_pid_1.pid).wacx.should == wacx + 1
    end
  end

  describe '#unfetched' do
    it 'should return all unfetched posts' do
      Posting.unfetched.should_not be_empty
    end
  end

  describe '#top', :wip => true do
    it 'should return top posting by watched user activity in last 24 hours' do
      Posting.top.should_not be_empty
    end
  end

  describe '#invalid!' do
    it 'should set value to false for post pid 1' do
      @post_pid_1.invalid!.valid.should be_false
    end
  end
end
 
