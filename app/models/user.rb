class User < ApplicationRecord
  devise :database_authenticatable, :rememberable, :validatable

  enum :role, { employee: 0, manager: 1 }

  validates :name, presence: true
end
