module Notifications
  class NewUserSignedUpNotification < ::NotificationType
    def self.notify_email!(subject)
      RadbearMailer.new_user_signed_up(notify_user_ids(subject), subject).deliver_later
    end

    class << self
      private

        def feed_content(subject)
          # TODO: add link
          "#{subject} signed up."
        end

        def sms_content(subject)
          feed_content(subject)
        end

        def exclude_user_ids(_subject)
          []
        end
    end
  end
end
