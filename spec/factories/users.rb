FactoryBot.define do
  factory :user do |this|
    first_name { 'Test' }
    last_name { 'User' }
    mobile_phone { '(999) 231-1111' }
    sequence(:email) { |n| "example#{n}@example.com" }
    password { 'password' }
    password_confirmation { 'password' }
    confirmed_at { Time.zone.now }
    association :user_status, factory: %i[user_status active]
    do_not_notify_approved { true }
    security_roles { [create(:security_role)] }

    factory :admin do
      security_roles { [create(:security_role, :admin)] }
    end

    factory :super_admin do |f|
      f.after(:create) do |user|
        user.update! security_roles: [create(:security_role, :admin)]
        user.update!(super_admin: true)
      end
    end

    factory :pending do
      association :user_status, factory: %i[user_status pending]
    end
  end
end
