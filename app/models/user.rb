class User < ApplicationRecord
  devise :database_authenticatable, :rememberable, :validatable

  enum :role, { employee: 0, manager: 1 }

  validates :name, presence: true

  has_many :gauges, foreign_key: :created_by_id, dependent: :restrict_with_error
  has_many :readings, foreign_key: :entered_by_id, dependent: :restrict_with_error
end
