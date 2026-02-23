# frozen_string_literal: true

# On startup, enqueue auto-sync jobs for any procedure mirrors that have
# a configured frequency but no pending job in the queue.
ActiveSupport.on_load(:active_record) do
  next unless defined?(ProcedureMirror)

  begin
    ProcedureMirror.where.not(auto_sync_frequency: nil).find_each do |mirror|
      pending = Delayed::Job.where("handler LIKE ?", "%SyncDossiersJob%").where("handler LIKE ?", "%#{mirror.procedure_id}%")
      next if pending.exists?

      SyncDossiersJob.set(wait: mirror.auto_sync_frequency.minutes).perform_later(mirror.procedure_id)
    end
  rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad, ActiveRecord::StatementInvalid
    # Database not ready yet
  end
end
