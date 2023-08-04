namespace :jpets do
  namespace :parishes do
    desc "Load the list of parishes"
    task :load => :environment do
      parishes = [
        ["Grouville",    "JE39GA"],
        ["St. Brelade",  "JE38BS"],
        ["St. Clement",  "JE26FP"],
        ["St. Helier",   "JE23NN"],
        ["St. John",     "JE34EJ"],
        ["St. Lawrence", "JE31NG"],
        ["St. Martin",   "JE36HW"],
        ["St. Mary",     "JE33AS"],
        ["St. Ouen",     "JE32HY"],
        ["St. Peter",    "JE37AH"],
        ["St. Saviour",  "JE27LF"],
        ["Trinity",      "JE35JB"]
      ]

      parishes.each do |name, postcode|
        parish = Parish.find_or_create_by!(name: name)
        parish.update!(example_postcode: postcode)
      end
    end
  end
end
