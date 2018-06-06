class RemoveParishIdFromInvalidations < ActiveRecord::Migration[5.1]
  def change
    remove_column :invalidations, :parish_id, :string, limit: 30
  end
end
