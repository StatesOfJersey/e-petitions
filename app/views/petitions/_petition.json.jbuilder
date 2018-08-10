json.type "petition"
json.id petition.id

json.links do
  json.self petition_url(petition, format: :json)
end if defined?(is_collection)

json.attributes do
  json.action petition.action
  json.background petition.background
  json.additional_details petition.additional_details
  json.state petition.state
  json.signature_count petition.signature_count

  json.created_at api_date_format(petition.created_at)
  json.updated_at api_date_format(petition.updated_at)
  json.rejected_at api_date_format(petition.rejected_at)
  json.opened_at api_date_format(petition.opened_at)
  json.closed_at api_date_format(petition.closed_at)
  json.moderation_threshold_reached_at api_date_format(petition.moderation_threshold_reached_at)
  json.response_threshold_reached_at api_date_format(petition.response_threshold_reached_at)
  json.ministers_response_at api_date_format(petition.government_response_at)
  json.debate_threshold_reached_at api_date_format(petition.debate_threshold_reached_at)
  json.scheduled_debate_date api_date_format(petition.scheduled_debate_date)
  json.debate_outcome_at api_date_format(petition.debate_outcome_at)

  if petition.open?
    json.creator_name petition.creator_name
  else
    json.creator_name nil
  end

  if rejection = petition.rejection
    json.rejection do
      json.code rejection.code
      json.details rejection.details
    end
  else
    json.rejection nil
  end

  if response = petition.government_response
    json.ministers_response do
      json.responded_on api_date_format(response.responded_on)
      json.summary response.summary
      json.details response.details
      json.created_at api_date_format(response.created_at)
      json.updated_at api_date_format(response.updated_at)
    end
  else
    json.ministers_reponse nil
  end

  if debate_outcome = petition.debate_outcome
    json.debate do
      json.debated_on debate_outcome.date
      json.transcript_url debate_outcome.transcript_url
      json.video_url debate_outcome.video_url
      json.debate_pack_url debate_outcome.debate_pack_url
      json.overview debate_outcome.overview
    end
  else
    json.debate nil
  end

  if petition_page? && petition.published?
    json.signatures_by_parish petition.signatures_by_parish do |parish|
      json.name parish.name
      json.signature_count parish.signature_count
    end
  end
end
