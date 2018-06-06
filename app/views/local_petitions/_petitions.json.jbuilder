json.parish parish.name

json.petitions petitions do |petition|
  json.action petition.action
  json.url petition_url(petition)
  json.state petition.state
  json.parish_signature_count petition.parish_signature_count
  json.total_signature_count petition.signature_count
end
