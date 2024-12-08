csv_builder = lambda do |csv|
  csv << ['Petition', 'URL', 'State', 'Signatures Count']

  @petitions.find_each do |petition|
    csv << [
      petition.action,
      petition_url(petition),
      petition.state,
      petition.signature_count
    ]
  end
end

CSV.generate(&csv_builder)
