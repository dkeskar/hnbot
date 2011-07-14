require 'spec_helper'

describe Comment, :wip => true do
  before :all do
    Factory :comment_pid_1
  end

  describe '#add' do
    it 'should add new comment' do
      Comment.add(:cid => '2', :text => 'Test Comment').should be_true
      Comment.find_by_cid('2').text.should == 'Test Comment'
    end
  end

  describe '#watched_for' do
    it 'should return list of comments that watched for selected pid' do
      Comment.watched_for(1).should_not be_empty
    end
  end
end
 
