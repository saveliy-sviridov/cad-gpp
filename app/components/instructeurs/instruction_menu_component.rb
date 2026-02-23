# frozen_string_literal: true

class Instructeurs::InstructionMenuComponent < ApplicationComponent
  attr_reader :dossier

  attr_reader :accept_disabled

  def initialize(dossier:)
    @dossier = dossier
    @accept_disabled = !dossier.all_public_champs_validated?
  end

  def render?
    dossier.en_instruction?
  end

  def menu_label
    t(".instruct")
  end
end
