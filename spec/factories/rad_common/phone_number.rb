FactoryBot.define do
  factory :phone_number, class: 'String' do
    skip_create

    transient do
      phone_number do
        if RadicalTwilio.twilio_enabled?
          ENV.fetch('TEST_PHONE_NUMBER')
        else
          Faker::PhoneNumber.phone_number
        end
      end
    end

    trait :mobile do
      phone_number do
        if RadicalTwilio.twilio_enabled?
          ENV.fetch('TEST_MOBILE_PHONE')
        else
          Faker::PhoneNumber.cell_phone
        end
      end
    end

    trait :fax do
      phone_number do
        if RadicalTwilio.twilio_enabled?
          ENV.fetch('TEST_FAX_NUMBER')
        else
          Faker::PhoneNumber.phone_number
        end
      end
    end

    initialize_with { new(phone_number) }
  end
end
