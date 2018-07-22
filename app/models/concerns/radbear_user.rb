module RadbearUser
  extend ActiveSupport::Concern

  included do
    attr_accessor :approved_by
    scope :by_permission, ->(permission_attr) { joins(:security_roles).where("#{permission_attr} = TRUE").active }
    validate :validate_email_address
    after_save :notify_user_approved
  end

  def company
    Company.main
  end

  def notify_new_user
    User.admins.each do |admin|
      RadbearMailer.new_user_signed_up(admin, self).deliver_later
    end
  end

  def permission?(permission)
    security_roles.where("#{permission} = TRUE").count.positive?
  end

  def all_permissions
    permissions = []

    security_roles.each do |role|
      permissions += role.permission_attributes.to_a.reject { |item| !item[1] }.to_h.keys
    end

    permissions
  end

  def auto_approve?
    # override this as needed in model
    false
  end

  def greeting
    "Hello #{first_name}"
  end

  def audits_created(_)
    Audited::Audit.unscoped.where('user_id = ?', id).order('created_at DESC')
  end

  def update_firebase_info(app)
    firebase_user = get_firebase_data(app, firebase_reference)
    return unless firebase_user

    Audited.audit_class.as_user(self) do
      update!(mobile_client_platform: firebase_user['platform'], mobile_client_version: firebase_user['version'], current_device_type: firebase_user['deviceType'])
    end
  end

  def firebase_device_tokens(app)
    response = app.client.get firebase_reference + '/messagingTokens'

    unless response.success?
      raise response.raw_body
    end

    if response.body && response.body.count != 0
      response.body
    else
      []
    end
  end

  private

  def validate_email_address
    return if email.blank? || user_status_id.nil? || !user_status.validate_email || company.valid_user_domains.count.zero?

    domains = company.valid_user_domains

    components = email.split('@')
    if components.count == 2 && domains.include?(components[1])
      return
    end

    errors.add(:email, 'is invalid for this application, please contact the system administrator')
  end

  def notify_user_approved
    return if auto_approve?
    return unless saved_change_to_user_status_id? && user_status && user_status.active && (!respond_to?(:invited_to_sign_up?) || !invited_to_sign_up?)

    RadbearMailer.your_account_approved(self).deliver_later

    User.admins.each do |admin|
      if admin.id != id
        RadbearMailer.user_was_approved(admin, self, approved_by).deliver_later
      end
    end
  end
end
