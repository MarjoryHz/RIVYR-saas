class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :commission, null: false, foreign_key: true
      t.references :invoice, null: false, foreign_key: true
      t.string :status
      t.integer :amount_cents
      t.datetime :paid_at
      t.string :payment_type
      t.string :reference

      t.timestamps
    end
  end
end
