json.cache! [:local_petitions, @parish], expires_in: 5.minutes do
  json.partial! 'petitions', petitions: @petitions, parish: @parish
end
