Dir[Rails.root.join('../factories/**/*.rb')].each { |f| require f }

NotificationType.seed_items if NotificationType.count.zero?
user_status = UserStatus.default_active_status
SecurityRole.seed_items if SecurityRole.count.zero?

if User.count.zero?
  FactoryBot.create :admin, email: 'admin@example.com',
                            first_name: 'Test',
                            last_name: 'Admin',
                            user_status: user_status,
                            security_roles: [SecurityRole.admin_role]

  FactoryBot.create :user, email: 'user@example.com',
                           first_name: 'Test',
                           last_name: 'User',
                           user_status: user_status,
                           security_roles: [SecurityRole.find_by(name: 'User')]

  FactoryBot.create :user, :external, email: 'admin@abc.com',
                                      first_name: 'Portal',
                                      last_name: 'Admin',
                                      user_status: user_status,
                                      security_roles: [SecurityRole.find_by(name: 'Portal Admin')]

  FactoryBot.create :user, :external, email: 'user@abc.com',
                           first_name: 'Portal',
                           last_name: 'User',
                           user_status: user_status,
                           security_roles: [SecurityRole.find_by(name: 'Portal User')]
end
