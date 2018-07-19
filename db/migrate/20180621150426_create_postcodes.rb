class CreatePostcodes < ActiveRecord::Migration[5.1]
  def change
    create_table :postcodes, id: false do |t|
      t.primary_key :postcode, :string, limit: 10
      t.string :parish, limit: 30, null: false
      t.datetime :created_at, null: false
      t.datetime :expires_at
    end
  end
end
