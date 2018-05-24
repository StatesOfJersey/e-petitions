class RemoveStoppedAtFromPetitions < ActiveRecord::Migration[5.1]
  def up
    remove_column :petitions, :stopped_at
  end

  def down
    add_column :petitions, :stopped_at, :timestamp
  end
end
