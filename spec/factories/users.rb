FactoryBot.define do
  factory :user do
    first_name { 'Test' }
    last_name { 'User' }
    mobile_phone { '(999) 231-1111' }
    sequence(:email) { |n| "example#{n}@example.com" }
    password { 'password' }
    password_confirmation { 'password' }
    confirmed_at { Time.current }
    association :user_status, factory: %i[user_status active]
    do_not_notify_approved { true }
    security_roles { [create(:security_role)] }

    trait :external do
      external { true }
    end

    factory :admin do
      security_roles { [create(:security_role, :admin)] }
    end

    factory :pending do
      association :user_status, factory: %i[user_status pending]
    end
  end
end
