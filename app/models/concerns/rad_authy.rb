module RadAuthy
  extend ActiveSupport::Concern

  included do
    validate :validate_authy
    before_validation :maybe_update_authy
  end

  def reset_authy!
    update! authy_enabled: false, authy_id: nil
    update! authy_enabled: true
  end

  private

    def validate_authy
      if authy_enabled
        if RadCommon.authy_user_opt_in && mobile_phone.blank?
          errors.add(:mobile_phone, 'is required two factor authentication')
          return
        end

        if authy_id.present? && mobile_phone.present?
          # ok
        elsif authy_id.blank? && mobile_phone.blank?
          # ok
        else
          errors.add(:base, 'user is not valid for two factor authentication')
        end
      else
        errors.add(:base, 'user is not valid for two factor authentication') if authy_id.present?
      end
    end

    def maybe_update_authy
      return unless ENV['AUTHY_API_KEY'].present? && (authy_enabled_changed? || mobile_phone_changed?)

      # delete the authy user if it exists
      if authy_id.present?
        response = Authy::API.user_status(id: authy_id)

        if response.ok?
          response = Authy::API.delete_user(id: authy_id)

          if response.ok?
            self.authy_id = nil
          else
            errors.add(:base, "Could not remove authy user: #{response.message}")
            return
          end
        else
          self.authy_id = nil
        end
      end

      return unless authy_enabled? && mobile_phone.present? && email.present?

      # create the authy user if applicable
      response = Authy::API.register_user(email: email, country_code: '1', cellphone: mobile_phone)

      if response.ok?
        self.authy_id = response.id
      else
        if response.respond_to?(:message)
          errors.add(:base, "Could not register authy user: #{response.message}")
        else
          errors.add(:base, "Could not register authy user: #{response.errors}")
        end
      end
    end
end
