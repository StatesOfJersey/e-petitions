class AddPetitionReportsToSite < ActiveRecord::Migration[5.1]
  def change
    change_table :sites do |t|
      t.string :petition_report_email, limit: 100, null: false, default: '"Petitions: Jersey States Assembly" <petitions@gov.je>'
      t.column :petition_report_day_of_week, :integer, default: 0
      t.column :petition_report_hour_of_day, :integer, default: 9
    end
  end
end
