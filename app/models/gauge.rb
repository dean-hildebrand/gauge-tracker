class Gauge < ApplicationRecord
  enum :time_unit, { daily: 0, weekly: 1, monthly: 2, yearly: 3 }

  belongs_to :created_by, class_name: "User"
  # No gauge deletion implemented in UI but would want to avoid leaving orphaned readings if it were.
  has_many :readings, dependent: :destroy

  validates :name, presence: true, length: { maximum: 120 }
  validates :unit, presence: true
  validates :starts_on, :ends_on, presence: true
  validate  :ends_on_after_starts_on
  validate  :period_shape_frozen_when_locked, on: :update

  # True once the gauge has readings: its period shape can no longer be edited.
  def period_shape_locked?
    persisted? && readings.exists?
  end

  # Calendar-aligned periods, first and last truncated to the gauge range.
  def periods
    return [] if starts_on.blank? || ends_on.blank? || ends_on < starts_on

    result = []
    start_date = starts_on

    while start_date <= ends_on
      boundary = period_boundary_after(start_date)
      result << (start_date..[ boundary, ends_on ].min) # Truncate the last period to the gauge range.
      start_date = boundary + 1.day
    end

    result
  end

  # A date is a valid reading key only if it is the first day of one of this gauge's periods.
  def covers_period?(date)
    periods.any? { |range| range.first == date }
  end

  def readings_by_period
    # Return each period's start date to the corresponding reading, if any.
    readings.index_by(&:period_start)
  end

  def approved_count = readings.approved.count

  private

  def period_boundary_after(date)
    case time_unit.to_sym
    when :daily   then date
    when :weekly  then date.end_of_week
    when :monthly then date.end_of_month
    when :yearly  then date.end_of_year
    end
  end

  def ends_on_after_starts_on
    return if starts_on.blank? || ends_on.blank?

    errors.add(:ends_on, "must be after the start date") if ends_on <= starts_on
  end

  def period_shape_frozen_when_locked
    # check whether locked attrs actually got changed
    return unless period_shape_locked?

    %i[starts_on ends_on time_unit].each do |attribute|
      errors.add(attribute, "cannot be changed once the gauge has readings") if attribute_changed?(attribute)
    end
  end
end
