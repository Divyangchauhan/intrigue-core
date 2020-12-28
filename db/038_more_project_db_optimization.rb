Sequel.migration do
  change do

    alter_table(:entities) do
      add_index [:project_id,:type,:name]
      add_index [:project_id,:name]
    end

  end
end
