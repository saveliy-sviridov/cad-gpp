# frozen_string_literal: true

class Procedure::Card::CseCalendarComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  def render?
    true
  end
end
