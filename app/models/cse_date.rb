# frozen_string_literal: true

class CseDate < ApplicationRecord
  belongs_to :procedure

  validates :date, presence: true
end
