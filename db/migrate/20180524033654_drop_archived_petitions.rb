class DropArchivedPetitions < ActiveRecord::Migration[5.1]
  def up
    remove_foreign_key :archived_debate_outcomes, column: :petition_id
    remove_foreign_key :archived_government_responses, column: :petition_id
    remove_foreign_key :archived_notes, column: :petition_id
    remove_foreign_key :archived_petition_emails, column: :petition_id
    remove_foreign_key :archived_petitions, :parliaments
    remove_foreign_key :archived_rejections, column: :petition_id
    remove_foreign_key :archived_signatures, column: :petition_id

    remove_index :petitions, :archived_at
    remove_index :signatures, [:archived_at, :petition_id]

    remove_column :petitions, :archived_at
    remove_column :petitions, :archiving_started_at
    remove_column :signatures, :archived_at

    drop_table :archived_debate_outcomes
    drop_table :archived_government_responses
    drop_table :archived_notes
    drop_table :archived_petition_emails
    drop_table :archived_petitions
    drop_table :archived_rejections
    drop_table :archived_signatures
    drop_table :parliaments
  end

  def down
    create_table :archived_debate_outcomes do |t|
      t.integer :petition_id, null: false
      t.date :debated_on
      t.string :transcript_url, limit: 500
      t.string :video_url, limit: 500
      t.text :overview
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.boolean :debated, default: true, null: false
      t.string :commons_image_file_name
      t.string :commons_image_content_type
      t.integer :commons_image_file_size
      t.datetime :commons_image_updated_at
      t.string :debate_pack_url, limit: 500
      t.index [:petition_id, :debated_on]
      t.index [:petition_id], unique: true
      t.index [:updated_at]
    end

    create_table :archived_government_responses do |t|
      t.integer :petition_id
      t.string :summary, limit: 500, null: false
      t.text :details
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.index [:petition_id], unique: true
      t.index [:updated_at]
    end

    create_table :archived_notes do |t|
      t.integer :petition_id
      t.text :details
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.index [:petition_id], unique: true
    end

    create_table :archived_petition_emails do |t|
      t.integer :petition_id
      t.string :subject, null: false
      t.text :body
      t.string :sent_by
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.index [:petition_id]
    end

    create_table :archived_petitions do |t|
      t.string :state, limit: 10, default: "closed", null: false
      t.datetime :opened_at
      t.datetime :closed_at
      t.integer :signature_count, default: 0
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.integer :parliament_id
      t.string :action, limit: 255
      t.string :background, limit: 300
      t.text :additional_details
      t.datetime :government_response_at
      t.date :scheduled_debate_date
      t.datetime :last_signed_at
      t.datetime :response_threshold_reached_at
      t.datetime :debate_threshold_reached_at
      t.datetime :rejected_at
      t.datetime :debate_outcome_at
      t.datetime :moderation_threshold_reached_at
      t.string :debate_state, limit: 30
      t.datetime :stopped_at
      t.boolean :special_consideration
      t.jsonb :signatures_by_constituency
      t.jsonb :signatures_by_country
      t.datetime :email_requested_for_government_response_at
      t.datetime :email_requested_for_debate_scheduled_at
      t.datetime :email_requested_for_debate_outcome_at
      t.datetime :email_requested_for_petition_email_at
      t.integer :tags, default: [], null: false, array: true
      t.datetime :locked_at
      t.integer :locked_by_id
      t.integer :moderation_lag
      t.index "tags gin__int_ops", name: "index_archived_petitions_on_tags", using: :gin
      t.index "to_tsvector('english'::regconfig, (action)::text)", name: "index_archived_petitions_on_action", using: :gin
      t.index "to_tsvector('english'::regconfig, (background)::text)", name: "index_archived_petitions_on_background", using: :gin
      t.index "to_tsvector('english'::regconfig, additional_details)", name: "index_archived_petitions_on_additional_details", using: :gin
      t.index [:locked_by_id]
      t.index [:moderation_threshold_reached_at, :moderation_lag], name: "index_archived_petitions_on_mt_reached_at_and_moderation_lag"
      t.index [:parliament_id]
      t.index [:signature_count]
      t.index [:state, :closed_at]
    end

    create_table :archived_rejections do |t|
      t.integer :petition_id
      t.string :code, limit: 50, null: false
      t.text :details
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.index [:petition_id], unique: true
    end

    create_table :archived_signatures do |t|
      t.string :name, limit: 255, null: false
      t.string :state, limit: 20, default: "pending", null: false
      t.string :perishable_token, limit: 255
      t.string :postcode, limit: 255
      t.string :ip_address, limit: 20
      t.integer :petition_id
      t.datetime :created_at
      t.datetime :updated_at
      t.boolean :notify_by_email, default: false
      t.string :email, limit: 255
      t.string :unsubscribe_token
      t.string :constituency_id
      t.datetime :validated_at
      t.integer :number
      t.datetime :invalidated_at
      t.integer :invalidation_id
      t.datetime :government_response_email_at
      t.datetime :debate_scheduled_email_at
      t.datetime :debate_outcome_email_at
      t.datetime :petition_email_at
      t.uuid :uuid
      t.boolean :creator, default: false, null: false
      t.boolean :sponsor, default: false, null: false
      t.index [:constituency_id]
      t.index [:created_at, :ip_address, :petition_id], name: "index_archived_signatures_on_creation_ip_and_petition_id"
      t.index [:email, :petition_id, :name], unique: true
      t.index [:invalidation_id]
      t.index [:ip_address, :petition_id]
      t.index [:petition_id]
      t.index [:petition_id], name: "index_archived_signatures_on_petition_id_where_creator_is_true", unique: true, where: "(creator = true)"
      t.index [:petition_id], name: "index_archived_signatures_on_petition_id_where_sponsor_is_true", where: "(sponsor = true)"
      t.index [:state, :petition_id]
      t.index [:updated_at]
      t.index [:uuid]
      t.index [:validated_at]
    end

    create_table :parliaments do |t|
      t.datetime :dissolution_at
      t.text :dissolution_message
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :dissolution_heading, limit: 100
      t.string :dissolution_faq_url, limit: 500
      t.string :dissolved_heading, limit: 100
      t.text :dissolved_message
      t.datetime :notification_cutoff_at
      t.datetime :registration_closed_at
      t.string :government, limit: 100
      t.datetime :opening_at
      t.datetime :archived_at
      t.integer :threshold_for_response, default: 10000, null: false
      t.integer :threshold_for_debate, default: 100000, null: false
      t.integer :petition_duration, default: 6
      t.datetime :archiving_started_at
    end

    add_column :petitions, :archived_at, :datetime
    add_column :petitions, :archiving_started_at, :datetime
    add_column :signatures, :archived_at, :datetime

    add_index :petitions, :archived_at
    add_index :signatures, [:archived_at, :petition_id]

    add_foreign_key :archived_debate_outcomes, :archived_petitions, column: :petition_id, on_delete: :cascade
    add_foreign_key :archived_government_responses, :archived_petitions, column: :petition_id, on_delete: :cascade
    add_foreign_key :archived_notes, :archived_petitions, column: :petition_id, on_delete: :cascade
    add_foreign_key :archived_petition_emails, :archived_petitions, column: :petition_id, on_delete: :cascade
    add_foreign_key :archived_petitions, :parliaments
    add_foreign_key :archived_rejections, :archived_petitions, column: :petition_id, on_delete: :cascade
    add_foreign_key :archived_signatures, :archived_petitions, column: :petition_id, on_delete: :cascade
  end
end
