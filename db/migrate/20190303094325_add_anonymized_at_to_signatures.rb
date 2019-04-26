class AddAnonymizedAtToSignatures < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    unless column_exists?(:signatures, :anonymized_at)
      add_column :signatures, :anonymized_at, :datetime
    end

    unless index_exists?(:signatures, [:anonymized_at, :petition_id])
      add_index :signatures, [:anonymized_at, :petition_id], algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:signatures, [:anonymized_at, :petition_id])
      remove_index :signatures, [:anonymized_at, :petition_id]
    end

    if column_exists?(:signatures, :anonymized_at)
      remove_column :signatures, :anonymized_at
    end
  end
end
