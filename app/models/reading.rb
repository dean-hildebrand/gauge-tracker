class Reading < ApplicationRecord
  belongs_to :gauge
  belongs_to :entered_by,  class_name: "User"
  belongs_to :approved_by, class_name: "User", optional: true

  def approved? = approved_at.present?
end
