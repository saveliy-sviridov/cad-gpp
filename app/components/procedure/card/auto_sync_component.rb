# frozen_string_literal: true

class Procedure::Card::AutoSyncComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  def render?
    true
  end

  private

  def frequency
    @procedure.procedure_mirror&.auto_sync_frequency
  end

  def active?
    frequency.present?
  end

  def frequency_label
    minutes = frequency
    if minutes >= 1440 && (minutes % 1440).zero?
      value = minutes / 1440
      value == 1 ? "1 jour" : "#{value} jours"
    elsif minutes >= 60 && (minutes % 60).zero?
      value = minutes / 60
      value == 1 ? "1 heure" : "#{value} heures"
    else
      "#{minutes} min"
    end
  end
end
