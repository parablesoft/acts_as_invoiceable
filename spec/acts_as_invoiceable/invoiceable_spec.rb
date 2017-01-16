require 'spec_helper'


ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

ActiveRecord::Schema.define(:version => 1) do
  create_table :invoices do |t|
    t.string :number
    t.string :alt_number
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
end




class Invoice < ActiveRecord::Base
  acts_as_invoiceable
end

class LegacyInvoice < ActiveRecord::Base
  acts_as_invoiceable(number_field: :alt_number)
end

class ScopedInvoice < ActiveRecord::Base
  acts_as_invoiceable(scope: :deal_id)
end

class InvoiceNumberSequence < ActiveRecord::Base
end

InvoiceNumberSequence.create({name: "invoice",next_number: 1})

describe ActsAsInvoiceable::Invoiceable do


  let(:year){Date.today.year}
  


  context "default number field" do
    let!(:next_number){InvoiceNumberSequence.first.next_number}
    subject {Invoice.create}
    it{expect(subject.number).to eq("#{year}-#{next_number}")}
    it{expect(subject.alt_number).to be_nil}
  end



  context "with a specified number field" do
    let!(:next_number){InvoiceNumberSequence.first.next_number}
    subject {LegacyInvoice.create}
    it{expect(subject.number).to be_nil}
    it{expect(subject.alt_number).to eq("#{year}-#{next_number}")}

  end


  context "scoped invoices" do


    before do

      InvoiceNumberSequence.create(name: "deal_1")
      InvoiceNumberSequence.create(name: "deal_2")
      ScopedInvoice.create(deal_id: 1)
      ScopedInvoice.create(deal_id: 2)

    end
    it{expect(ScopedInvoice.count).to eq 2}

    it{expect(ScopedInvoice.first.number).to eq "#{year}-1"}
    it{expect(ScopedInvoice.last.number).to eq "#{year}-1"}

  end





end
