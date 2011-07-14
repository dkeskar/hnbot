require 'spec_helper'

describe Avatar, :wip => true do
  before :all do
    @patio11_avatar = Factory :patio11_avatar
  end

  describe '#watch' do
    it 'should increment watcher counter' do
      avatar = Avatar.find_by_name(@patio11_avatar.name)
      watcher_counter = avatar.nwx
      Avatar.watch(avatar.name).nwx.should == watcher_counter + 1
    end
  end

  describe '#unwatch' do
    it 'should decrement watcher counter' do
      avatar = Avatar.find_by_name(@patio11_avatar.name)
      watcher_counter = avatar.nwx
      Avatar.unwatch(avatar.name).nwx.should == watcher_counter - 1
    end
  end

  describe '#watched' do
    it 'should return list of all avatar marked as watched' do
      watched_avatars = Avatar.watched
      watched_avatars.should_not be_empty
      watched_avatars.each do |avatar|
        avatar.should be_is_watched
      end
    end
  end

  describe '#is_watched' do
    it 'should return true for patio11 avatar' do
      @patio11_avatar.should be_is_watched
    end
  end

  describe '#unwatch' do
    it 'should unwatch patio11 avatar' do
      watcher_counter = @patio11_avatar.nwx
      @patio11_avatar.unwatch(1).nwx.should == watcher_counter - 1
    end
  end

  describe '#invalid!' do
    it 'should set value to false for pation11 avatar' do
      @patio11_avatar.invalid!.valid.should be_false
    end
  end
end
 
