# frozen_string_literal: true

class ProcedureMirror < ApplicationRecord
  belongs_to :procedure

  validates :public_instance_url, presence: true
  validates :public_procedure_number, presence: true

  def public_api_url
    "#{public_instance_url}/api/v2/graphql"
  end
end
