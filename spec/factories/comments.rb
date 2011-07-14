FactoryGirl.define do
  factory :comment_pid_1, :class => Comment do
    pid   1
    cid   1
    text  'Test Comment'
    association :avatar, :factory => :patio11_avatar 
  end
end
 
