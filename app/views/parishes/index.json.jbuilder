@parishes.each do |parish|
  json.set! parish.id do
    json.parish parish.name
  end
end
