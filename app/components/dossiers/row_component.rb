# frozen_string_literal: true

class Dossiers::RowComponent < ApplicationComponent
  attr_reader :label
  attr_reader :profile
  attr_reader :updated_at
  attr_reader :seen_at
  attr_reader :content_class

  renders_one :value
  renders_one :blank

  def initialize(label:, profile: nil, updated_at: nil, seen_at: nil, content_class: nil, copyable: true)
    @label = label
    @profile = profile
    @updated_at = updated_at
    @seen_at = seen_at
    @content_class = content_class
    @copyable = copyable
  end

  def usager?
    @profile == 'usager'
  end
end
