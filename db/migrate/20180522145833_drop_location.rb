class DropLocation < ActiveRecord::Migration[5.1]
  def up
    remove_column :archived_signatures, :location_code
    remove_column :invalidations, :location_code
    remove_column :signatures, :location_code

    drop_table :country_petition_journals
    drop_table :locations
  end

  def down
    add_column :archived_signatures, :location_code, :string, limit: 30
    add_column :invalidations, :location_code, :string, limit: 30
    add_column :signatures, :location_code, :string, limit: 30

    create_table :country_petition_journals do |t|
      t.integer :petition_id, null: false
      t.integer :signature_count, default: 0, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :location_code, limit: 30
      t.index [:petition_id, :location_code], name: "index_country_petition_journals_on_petition_and_location", unique: true
    end

    create_table :locations do |t|
      t.string :code, limit: 30, null: false
      t.string :name, limit: 100, null: false
      t.date :start_date
      t.date :end_date
      t.datetime :created_at
      t.datetime :updated_at
      t.index :code, unique: true
      t.index :name, unique: true
      t.index [:start_date, :end_date]
    end
  end
end
