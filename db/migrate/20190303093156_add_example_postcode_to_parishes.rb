class AddExamplePostcodeToParishes < ActiveRecord::Migration[5.1]
  class Parish < ActiveRecord::Base
    before_create do
      self.slug = name.parameterize
    end
  end

  PARISHES = [
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

  def up
    add_column :parishes, :example_postcode, :string, limit: 10
    add_index :parishes, :example_postcode, unique: true

    PARISHES.each do |name, postcode|
      parish = Parish.find_or_create_by!(name: name)
      parish.update!(example_postcode: postcode)
    end
  end

  def down
    remove_column :parishes, :example_postcode
  end
end
