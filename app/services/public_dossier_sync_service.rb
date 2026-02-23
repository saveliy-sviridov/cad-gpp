# frozen_string_literal: true

# Service to sync dossiers from a linked public procedure
# Creates local dossiers for each dossier found on the public instance
class PublicDossierSyncService
  class SyncError < StandardError; end

  DOSSIERS_QUERY = <<~GQL
    query getDossiers($number: Int!) {
      demarche(number: $number) {
        id
        number
        title
        dossiers {
          nodes {
            id
            number
            state
            usager {
              email
            }
            demandeur {
              ... on PersonnePhysique {
                civilite
                nom
                prenom
              }
            }
          }
          pageInfo {
            hasNextPage
            endCursor
          }
        }
      }
    }
  GQL

  def initialize(public_instance_url:, api_token:)
    @public_instance_url = public_instance_url.chomp('/')
    @api_token = api_token
  end

  # Sync dossiers from a public procedure to a local procedure
  # Returns { created: count, skipped: count, errors: [] }
  def sync_dossiers(local_procedure)
    mirror = local_procedure.procedure_mirror
    raise SyncError, "Procedure has no linked public procedure" unless mirror

    public_procedure_number = mirror.public_procedure_number
    result = { created: 0, updated: 0, skipped: 0, errors: [] }

    # Fetch dossiers from public instance
    public_dossiers = fetch_public_dossiers(public_procedure_number)

    # Find a user to create dossiers (use first admin or create a system user)
    system_user = find_or_create_system_user

    public_dossiers.each do |public_dossier|
      begin
        # Check if we already have a linked dossier for this public dossier
        existing = LinkedDossier.find_by(
          public_instance_url: @public_instance_url,
          public_dossier_number: public_dossier['number']
        )

        if existing
          if existing.public_dossier_state != public_dossier['state']
            existing.update!(public_dossier_state: public_dossier['state'])
            result[:updated] += 1
          else
            result[:skipped] += 1
          end
          next
        end

        # Create a new local dossier
        dossier = create_local_dossier(local_procedure, public_dossier, system_user)
        if dossier
          result[:created] += 1
        else
          result[:errors] << "Failed to create dossier for public ##{public_dossier['number']}"
        end
      rescue => e
        result[:errors] << "Error syncing public dossier ##{public_dossier['number']}: #{e.message}"
        Rails.logger.error("PublicDossierSyncService error: #{e.message}")
      end
    end

    result
  end

  private

  def fetch_public_dossiers(procedure_number)
    all_dossiers = []
    cursor = nil

    loop do
      response = execute_query(DOSSIERS_QUERY, { number: procedure_number })

      if response['errors'].present?
        raise SyncError, "API Error: #{response['errors'].map { it['message'] }.join(', ')}"
      end

      demarche = response.dig('data', 'demarche')
      raise SyncError, "Procedure ##{procedure_number} not found" if demarche.nil?

      dossiers_data = demarche.dig('dossiers', 'nodes') || []
      all_dossiers.concat(dossiers_data)

      page_info = demarche.dig('dossiers', 'pageInfo')
      break unless page_info&.dig('hasNextPage')

      cursor = page_info['endCursor']
    end

    all_dossiers
  end

  def create_local_dossier(procedure, public_dossier, user)
    # Extract usager info
    usager_email = public_dossier.dig('usager', 'email')
    demandeur = public_dossier['demandeur'] || {}
    usager_nom = demandeur['nom']
    usager_prenom = demandeur['prenom']
    usager_civilite = demandeur['civilite']

    dossier = nil

    ActiveRecord::Base.transaction do
      # Create the dossier
      dossier = Dossier.new(
        revision: procedure.active_revision,
        user: user,
        state: 'en_instruction',
        groupe_instructeur: procedure.defaut_groupe_instructeur,
        for_procedure_preview: false,
        prefilled: true  # Mark as prefilled since it's auto-created
      )

      dossier.build_default_values

      unless dossier.save(validate: false)
        Rails.logger.error("Failed to create dossier: #{dossier.errors.full_messages.join(', ')}")
        raise ActiveRecord::Rollback
      end

      # Set timestamps
      now = Time.current
      dossier.update_columns(
        depose_at: now,
        en_construction_at: now,
        en_instruction_at: now
      )

      # Create the link to the public dossier
      LinkedDossier.create!(
        dossier: dossier,
        public_instance_url: @public_instance_url,
        public_dossier_number: public_dossier['number'],
        public_dossier_graphql_id: public_dossier['id'],
        usager_email: usager_email,
        usager_nom: usager_nom,
        usager_prenom: usager_prenom,
        usager_civilite: usager_civilite,
        public_dossier_state: public_dossier['state']
      )

      # Update individual record if procedure is for individuals
      # (build_default_values already created an empty Individual)
      if procedure.for_individual? && dossier.individual.present?
        dossier.individual.update!(
          nom: usager_nom || 'Importé',
          prenom: usager_prenom || 'Dossier',
          gender: demandeur['civilite'] == 'M' ? 'M.' : 'Mme'
        )
      end

      Rails.logger.info("Created local dossier ##{dossier.id} linked to public dossier ##{public_dossier['number']}")
    end

    # Return nil if transaction was rolled back (dossier won't be persisted)
    dossier&.persisted? ? dossier : nil
  end

  def find_or_create_system_user
    # Try to find an existing system user
    system_email = 'system@gipcad.local'
    user = User.find_by(email: system_email)
    return user if user

    # Create a system user
    user = User.new(
      email: system_email,
      password: SecureRandom.hex(32),
      confirmed_at: Time.current
    )

    if user.save
      Rails.logger.info("Created system user for dossier sync: #{system_email}")
      user
    else
      # Fallback to first user if system user creation fails
      User.first
    end
  end

  def execute_query(query, variables)
    response = Typhoeus.post(
      "#{@public_instance_url}/api/v2/graphql",
      headers: {
        'Authorization' => "Bearer #{@api_token}",
        'Content-Type' => 'application/json',
      },
      body: { query: query, variables: variables }.to_json,
      timeout: 60
    )

    if response.success?
      JSON.parse(response.body)
    else
      raise SyncError, "HTTP #{response.code}: #{response.status_message}"
    end
  end
end
