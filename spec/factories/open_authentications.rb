FactoryGirl.define do
  factory :open_authentication do
    sequence(:provider) { |n| "provider_#{n}" }
    sequence(:uid) {|n| "#{n}2345668" }
    sequence(:user_id)  {n }
  end
end  