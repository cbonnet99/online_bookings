class AddQaToClients < ActiveRecord::Migration
  def self.up
    add_column :clients, :question, :string, :limit => 500 
    add_column :clients, :answer, :string
  end

  def self.down
    remove_column :clients, :answer
    remove_column :clients, :question
  end
end
