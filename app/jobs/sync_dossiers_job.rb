# frozen_string_literal: true

class SyncDossiersJob < ApplicationJob
  def perform(procedure_id)
    procedure = Procedure.find(procedure_id)
    mirror = procedure.procedure_mirror

    return if mirror.nil?

    api_token = ENV['PUBLIC_DS_API_TOKEN']
    return if api_token.blank?

    service = PublicDossierSyncService.new(
      public_instance_url: mirror.public_instance_url,
      api_token: api_token
    )

    result = service.sync_dossiers(procedure)

    mirror.update!(last_synced_at: Time.current)

    Rails.logger.info("Auto-sync procedure #{procedure_id}: created=#{result[:created]}, updated=#{result[:updated]}, skipped=#{result[:skipped]}, errors=#{result[:errors].size}")
  rescue => e
    Rails.logger.error("Auto-sync error for procedure #{procedure_id}: #{e.message}")
  ensure
    reenqueue_if_needed(procedure_id)
  end

  private

  def reenqueue_if_needed(procedure_id)
    mirror = ProcedureMirror.find_by(procedure_id: procedure_id)
    return if mirror.nil? || mirror.auto_sync_frequency.nil?

    SyncDossiersJob.set(wait: mirror.auto_sync_frequency.minutes).perform_later(procedure_id)
  end
end
