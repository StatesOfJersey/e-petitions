class AddAnonymizedAtToPetitions < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    unless column_exists?(:petitions, :anonymized_at)
      add_column :petitions, :anonymized_at, :datetime
    end

    unless index_exists?(:petitions, :anonymized_at)
      add_index :petitions, :anonymized_at, algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:petitions, :anonymized_at)
      remove_index :petitions, :anonymized_at
    end

    if column_exists?(:petitions, :anonymized_at)
      remove_column :petitions, :anonymized_at
    end
  end
end
