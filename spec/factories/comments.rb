FactoryGirl.define do
  factory :comment_pid_1, :class => Comment do
    pid   1
    cid   1
    text  'Test Comment'
    avatar {|avatar| Avatar.find_by_name('patio11') || Factory.create(:patio11_avatar)} 
  end

  factory :comment_cid_3, :class => Comment do
    pid 1
    cid 3
    text  'Test Comment 3'
    avatar {|avatar| avatar = Avatar.find_by_name('patio11') || Factory.create(:patio11_avatar)} 
    posted_at {|posted_at| posted_at = Time.now}
  end

  factory :comment_cid_4, :class => Comment do
    pid 1
    cid 4
    text  'Test Comment 4'
    avatar {|avatar| avatar = Avatar.find_by_name('patio11') || Factory.create(:patio11_avatar)} 
    posted_at {|posted_at| posted_at = Time.now}
  end

  factory :comment_cid_5, :class => Comment do
    pid 1
    cid 5
    text  'Test Comment 5'
    avatar {|avatar| avatar = Avatar.find_by_name('patio11') || Factory.create(:patio11_avatar)} 
    posted_at {|posted_at| posted_at = Time.now}
  end
end
 
