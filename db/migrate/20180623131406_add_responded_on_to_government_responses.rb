class AddRespondedOnToGovernmentResponses < ActiveRecord::Migration[5.1]
  def change
    change_table :government_responses do |t|
      t.date :responded_on
    end
  end
end
