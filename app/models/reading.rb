class Reading < ApplicationRecord
  class ImmutableError < StandardError; end

  belongs_to :gauge
  belongs_to :entered_by,  class_name: "User"
  belongs_to :approved_by, class_name: "User", optional: true

  validates :period_start, presence: true, uniqueness: { scope: :gauge_id }
  validates :value, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_update :guard_immutability

  scope :approved, -> { where.not(approved_at: nil) }
  scope :pending,  -> { where(approved_at: nil) }

  def approved? = approved_at.present?

  def approve!(manager)
    raise ImmutableError, "Reading is already approved" if approved?

    update!(approved_at: Time.current, approved_by: manager)
  end

  private

  # Use approved_at_was since "before_update" fires mid save - check current value in DB instead
  def guard_immutability
    return if approved_at_was.blank?

    errors.add(:base, "Approved readings cannot be modified")
    throw :abort
  end
end
