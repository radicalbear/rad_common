class UserStatus < ApplicationRecord
  scope :not_pending, -> { where.not(id: default_pending_status.id) }
  scope :by_id, -> { order(:id) }

  alias_attribute :to_s, :name

  def self.default_pending_status
    UserStatus.find_by(name: 'Pending')
  end

  def self.default_active_status
    UserStatus.find_by(name: 'Active')
  end

  def self.default_inactive_status
    UserStatus.find_by(name: 'Inactive')
  end

  def self.seed_items
    UserStatus.create!(name: 'Pending', active: false, validate_email: true)
    UserStatus.create!(name: 'Active', active: true, validate_email: true)
    UserStatus.create!(name: 'Inactive', active: false, validate_email: false)
  end

  def button_style
    case name
    when 'Active'
      'btn-success'
    when 'Pending'
      'btn-warning'
    else
      'btn-danger'
    end
  end
end
