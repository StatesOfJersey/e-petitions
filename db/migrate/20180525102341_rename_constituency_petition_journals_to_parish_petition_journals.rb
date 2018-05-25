class RenameConstituencyPetitionJournalsToParishPetitionJournals < ActiveRecord::Migration[4.2]
  def up
    rename_table :constituency_petition_journals, :parish_petition_journals

    add_index :parish_petition_journals, [:petition_id, :parish_id], unique: true, name: 'idx_parish_petition_journal_uniqueness'
  end

  def down
    rename_table :parish_petition_journals, :constituency_petition_journals

    add_index :constituency_petition_journals, [:petition_id, :constituency_id], unique: true, name: 'idx_constituency_petition_journal_uniqueness'
  end
end
