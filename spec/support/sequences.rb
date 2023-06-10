RSpec.configure do |config|
  config.before(:suite) do
    ActiveRecord::Base.connection_pool.with_connection do |connection|
      connection.execute <<~SQL
        ALTER SEQUENCE petitions_id_seq START WITH 100000 RESTART WITH 100000 MINVALUE 100000
      SQL
    end
  end
end
