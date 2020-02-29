class NotificationType < ApplicationRecord
  has_many :notification_security_roles, dependent: :destroy
  has_many :security_roles, through: :notification_security_roles, dependent: :destroy
  has_many :notification_settings, dependent: :destroy

  enum auth_mode: { security_roles: 0, absolute_user: 1 }
  alias_attribute :to_s, :description

  scope :by_name, -> { order(:name) }

  validate :validate_auth, on: :update

  def description
    name.gsub('Notifications::', '').underscore.titleize.gsub(' Notification', '')
  end

  def permitted_users
    users = User.active

    if security_roles?
      where_clause = 'users.id IN (SELECT user_id FROM security_roles_users WHERE security_role_id IN '\
                     '(SELECT security_role_id FROM notification_security_roles WHERE notification_type_id = ?))'

      users = users.where(where_clause, id)
    end

    users
  end

  def self.seed_items
    items = %w[Notifications::NewUserSignedUpNotification
               Notifications::UserWasApprovedNotification
               Notifications::UserAcceptsInvitationNotification
               Notifications::GlobalValidityNotification]

    items.each { |item| NotificationType.create! name: item }
  end

  def self.notify!(subject)
    klass = to_s.constantize

    klass.notify_email!(subject)
    klass.notify_feed!(subject)
    klass.notify_sms!(subject)
  end

  def enabled_for_method?(user_id, notification_method)
    setting = notification_settings.find_by(user_id: user_id)

    if notification_method == :email
      return true if setting.blank?

      setting.enabled? && setting.email?
    elsif setting.blank? || !setting.enabled
      false
    else
      setting.send(notification_method)
    end
  end

  class << self
    protected

      def notify_email!(subject)
        if mailer_class == 'RadbearMailer' && mailer_method == 'simple_message'

          RadbearMailer.simple_message(notify_user_ids_opted(subject, :email),
                                       mailer_subject(subject),
                                       mailer_message(subject),
                                       mailer_options(subject)).deliver_later

        else
          mailer = mailer_class.constantize
          mailer.send(mailer_method, notify_user_ids_opted(subject, :email), subject).deliver_later
        end
      end

      def notify_feed!(subject)
        notification_type = set_notification_type

        all_ids = notify_user_ids_all(subject)
        opted_ids = notify_user_ids_opted(subject, :feed)

        all_ids.each do |user_id|
          Notification.create! user_id: user_id,
                               notification_type: notification_type,
                               content: feed_content(subject),
                               record: feed_record(subject),
                               unread: opted_ids.include?(user_id)
        end
      end

      def notify_sms!(subject)
        return unless RadicalTwilio.twilio_enabled?

        SystemSmsJob.perform_later "Message from #{I18n.t(:app_name)}: #{sms_content(subject)}",
                                   notify_user_ids_opted(subject, :sms),
                                   nil
      end

    private

      def notify_user_ids_all(subject)
        notification_type = set_notification_type

        if notification_type.security_roles? && notification_type.notification_security_roles.count.zero?
          notification_type.notification_security_roles.create! security_role: SecurityRole.admin_role
        end

        if notification_type.security_roles?
          users = notification_type.permitted_users
        else
          user = User.find(absolute_user_id(subject))
          raise 'absolute user must be active' unless user.active

          users = User.where(id: user.id)
        end

        user_ids = users.where
                        .not(id: NotificationSetting.where(notification_type: notification_type, enabled: false)
                        .pluck(:user_id)).pluck(:id)

        raise 'no users to notify' if notification_type.security_roles? && user_ids.count.zero?

        return user_ids unless notification_type.security_roles?
        raise 'exclude_user_ids is invalid' unless exclude_user_ids(subject).is_a?(Array)

        user_ids - exclude_user_ids(subject)
      end

      def notify_user_ids_opted(subject, notification_method)
        user_ids = notify_user_ids_all(subject)
        user_ids - opt_out_by_notification_method(notification_method, user_ids)
      end

      def opt_out_by_notification_method(notification_method, user_ids)
        notification_type = set_notification_type
        opted_out = []

        user_ids.each do |user_id|
          opted_out.push(user_id) unless notification_type.enabled_for_method?(user_id, notification_method)
        end

        opted_out
      end

      def set_notification_type
        notification_type = NotificationType.find_by(name: to_s)
        notification_type = NotificationType.create! name: to_s if notification_type.blank?
        notification_type
      end
  end

  private

    def validate_auth
      errors.add(:auth_mode, 'invalid with security roles') if absolute_user? && security_roles.count.positive?
      errors.add(:auth_mode, 'invalid without security roles') if security_roles? && security_roles.count.zero?
    end
end
