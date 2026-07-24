class CreateRuntimeAiResults < ActiveRecord::Migration[8.1]
  def change
    create_table :runtime_ai_results do |table|
      table.references :user, null: false, foreign_key: true
      table.text :prompt, null: false
      table.text :content, null: false
      table.string :provider, null: false
      table.string :model, null: false
      table.timestamps
    end
  end
end
