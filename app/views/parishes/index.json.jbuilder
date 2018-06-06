json.cache! :parishes, expires_in: 1.hour do
  @parishes.each do |parish|
    json.set! parish.id do
      json.parish parish.name
    end
  end
end
