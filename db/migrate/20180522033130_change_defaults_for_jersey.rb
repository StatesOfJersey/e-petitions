class ChangeDefaultsForJersey < ActiveRecord::Migration[4.2]
  def up
    change_column_default :sites, :title, 'Petition States Assembly'
    change_column_default :sites, :url, 'https://petitions.gov.je'
    change_column_default :sites, :email_from, '"Petitions: Jersey States Assembly" <no-reply@gov.je>'
    change_column_default :sites, :feedback_email, '"Petitions: Jersey States Assembly" <petitions@gov.je>'
    change_column_default :sites, :moderate_url, 'https://moderate.petitions.gov.je'
  end

  def down
    change_column_default :sites, :title, 'Petition parliament'
    change_column_default :sites, :url, 'https://petition.parliament.uk'
    change_column_default :sites, :email_from, '"Petitions: UK Government and Parliament" <no-reply@petition.parliament.uk>'
    change_column_default :sites, :feedback_email, '"Petitions: Jersey States Assembly" <no-reply@gov.je>'
    change_column_default :sites, :moderate_url, 'https://moderate.petition.parliament.uk'
  end
end
