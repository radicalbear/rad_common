namespace :rad_common do
  task :global_validity, [:override_model] => :environment do |_t, args|
    Timeout.timeout(24.hours) do
      global_validity = GlobalValidation.new
      global_validity.override_model = args[:override_model]
      global_validity.run
    end
  end

  task redo_authy: :environment do
    Timeout.timeout(1.hour) do
      User.where(authy_enabled: true).find_each do |user|
        user.update!(authy_enabled: false)
        user.update!(authy_enabled: true)
        sleep 2 # avoid DDOS throttling
      end
    end
  end

  task check_database_use: :environment do
    Timeout.timeout(30.minutes) do
      DatabaseUseChecker.generate_report
    end
  end
end
