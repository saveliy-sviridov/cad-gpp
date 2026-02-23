# frozen_string_literal: true

class ChampNote < ApplicationRecord
  belongs_to :champ

  has_many_attached :documents
end
