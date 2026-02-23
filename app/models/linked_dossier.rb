# frozen_string_literal: true

class LinkedDossier < ApplicationRecord
  belongs_to :dossier

  validates :public_dossier_number, presence: true
  validates :dossier_id, uniqueness: true

  def public_dossier_url
    return nil if public_instance_url.blank? || public_dossier_number.blank?
    "#{public_instance_url}/dossiers/#{public_dossier_number}"
  end

  def usager_full_name
    [usager_prenom, usager_nom].compact.join(' ').presence || usager_email
  end
end
