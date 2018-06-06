class CreateParishes < ActiveRecord::Migration[4.2]
  def change
    create_table :parishes do |t|
      t.string :name, limit: 100, null: false
      t.string :slug, limit: 100, null: false
      t.timestamps null: false
    end

    add_index :parishes, :slug, unique: true

    rename_column :signatures, :constituency_id, :parish_id
    rename_column :invalidations, :constituency_id, :parish_id
    rename_column :constituency_petition_journals, :constituency_id, :parish_id
  end
end
