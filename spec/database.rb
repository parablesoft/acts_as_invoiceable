ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

ActiveRecord::Schema.define(:version => 1) do
  create_table :invoices do |t|
    t.string :number
    t.string :alt_number
    t.string :po_number
    t.date :due_date
    [:name,:address_1,:address_2,:city,:state,:zip].each do |field|
      t.string "billing_#{field}".to_sym
    end
  end

  create_table :legacy_invoices do |t|
    t.string :number
    t.string :alt_number
  end


  create_table :scoped_invoices do |t|
    t.string :number
    t.integer :deal_id
  end

  create_table "invoice_number_sequences", force: :cascade do |t|
    t.string  "name"
    t.integer "next_number", default: 1
  end


  create_table "invoice_items", force: :cascade do |t|
    t.string   "name"
    t.string   "qb_id"
  end

  create_table "invoice_line_items", force: :cascade do |t|
    t.integer  "invoice_id"
    t.integer  "invoice_item_id"
    t.decimal  "rate",            precision: 15, scale: 2
    t.integer  "quantity", default: 1
    t.string   "description"
  end
end




class Invoice < ActiveRecord::Base
  acts_as_invoiceable
  has_many :invoice_line_items, dependent: :destroy
end

class LegacyInvoice < ActiveRecord::Base
  acts_as_invoiceable(number_field: :alt_number)
end

class ScopedInvoice < ActiveRecord::Base
  acts_as_invoiceable(scope: :deal_id)
end

class InvoiceNumberSequence < ActiveRecord::Base
end



class InvoiceLineItem < ActiveRecord::Base
  belongs_to :invoice
  belongs_to :invoice_item
  
  def amount
    quantity * rate
  end

  def pdf_params
    {price: rate, description: description, quantity: quantity}
  end


  def to_qb
      {
	"ItemRef" => {
	  "FullName" => "#{invoice_item.name}"
	},
	"Desc" => "#{description}",
	"Quantity" => "#{quantity}",
	"Rate" => rate
      }
  end

  
end

class InvoiceItem < ActiveRecord::Base
  has_many :invoice_line_items

  def self.qb_request
      {
	:item_query_rq => {
	}
      }
  end
end
