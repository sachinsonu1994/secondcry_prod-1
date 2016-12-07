class CreatePayuResponses < ActiveRecord::Migration
  def change
    create_table :payu_responses do |t|

      t.timestamps null: false
    end
  end
end
