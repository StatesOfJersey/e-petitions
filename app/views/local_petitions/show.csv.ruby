csv_cache [:local_petitions, @parish], expires_in: 5.minutes do
  CSV.generate do |csv|
    csv << ['Petition', 'URL', 'State', 'Local Signatures', 'Total Signatures']

    @petitions.each do |petition|
      csv << [
        petition.action,
        petition_url(petition),
        petition.state,
        petition.parish_signature_count,
        petition.signature_count
      ]
    end
  end
end
