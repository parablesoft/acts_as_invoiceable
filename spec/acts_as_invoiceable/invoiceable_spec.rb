require 'spec_helper'
describe ActsAsInvoiceable::Invoiceable do
  describe "#pdf_bill_to" do
    subject{create(:invoice)}
    it{expect(subject.pdf_bill_to).to eq "#{subject.billing_name}\n#{subject.billing_address_1}\n#{subject.billing_city}, #{subject.billing_state}, #{subject.billing_zip}"}
  end


  context "associations" do

    subject{build(:invoice)}
    it{is_expected.to respond_to :invoice_line_items}

    context "destroying invoice_line_items" do
      subject! do
	invoice = create(:invoice)
	create_list(:invoice_line_item,5,invoice: invoice)
	invoice
      end
      it{expect{subject.destroy}.to change{InvoiceLineItem.count}.by(-5)}
    end
  end



  describe "#total" do

    context "with invoice_line_items" do
      subject do
	invoice = create(:invoice)
	invoice.invoice_line_items << build(:invoice_line_item, quantity: 5, rate: 1000)
	invoice.invoice_line_items << build(:invoice_line_item, quantity: 1, rate: 200)
	invoice
      end

      it {expect(subject.total).to eq 5200}
    end
    context "no invoice_line_items" do
      subject{create(:invoice)}
      it{expect(subject.total).to eq 0}
    end
  end


  describe "#to_qb" do
    let(:interest){create(:invoice_item, name: "Interest")}
    let(:principal){create(:invoice_item, name: "Principal")}

    let(:invoice) do
      invoice = create(:invoice, :with_billing_details, due_date: Date.today,number: "2017-1234")
      allow(invoice).to receive(:po_number){"ABCD-1234"}
      invoice.invoice_line_items << create(:invoice_line_item, invoice_item: interest, description: "Interest for the month", rate: 100, quantity: 1)
      invoice.invoice_line_items << create(:invoice_line_item, invoice_item: principal, description: "Principal for the month", rate: 500, quantity: 2)
      invoice
    end
    let(:request) do

      {
	:invoice_add_rq => {
	  xml_attributes: {},
	  "InvoiceAdd" => {
	    "CustomerRef" => {
	      "FullName" => "#{invoice.billing_name}"
	    },
	    "TemplateRef" =>{
	      "FullName" => ""
	    },
	    "RefNumber" => "#{invoice.number}",
	    "BillAddress" => {
	      "Addr1" => "#{invoice.billing_address_1}",
	      "Addr2" => "#{invoice.billing_address_2}",
	      "City" => "#{invoice.billing_city}",
	      "State" => "#{invoice.billing_state}",
	      "PostalCode" => "#{invoice.billing_zip}"
	    },
	    "PONumber" => "ABCD-1234",
	    "TermsRef" => {
	      "FullName" => "Due on receipt"
	    },
	    "DueDate" => "#{Date.today}",
	    "Other" => "#{invoice.id}",
	    "InvoiceLineAdd" => [
	      {
		"ItemRef" => {
		  "FullName" => "Interest"
		},
		"Desc" => "Interest for the month",
		"Quantity" => "1",
		"Rate" => 100.00
	      },
	      {
		"ItemRef" => {
		  "FullName" => "Principal"
		},
		"Desc" => "Principal for the month",
		"Quantity" => "2",
		"Rate" => 500.00
	      }
	    ]
	  }
	}
      }
    end


    it{expect(invoice.to_qb).to eq request}
  end

  describe "to_pdf" do
    subject{create(:invoice, :with_line_items)}

    let(:pdf) do
      pdf = Payday::Invoice.new(invoice_number: subject.number, invoice_date: Date.today,bill_to: subject.pdf_bill_to, terms: "Due on receipt", po_number: "1234-ABCD")
      subject.invoice_line_items.each {|line_item| pdf.line_items << Payday::LineItem.new(price: line_item.rate, description: line_item.description, quantity: line_item.quantity)}
      pdf
    end
    it{expect(subject.to_pdf.line_items.count).to eq pdf.line_items.count}
    it{expect(subject.to_pdf.total).to eq pdf.total}
    it{expect(subject.to_pdf.bill_to).to eq pdf.bill_to}
    it{expect(subject.to_pdf.invoice_date).to eq pdf.invoice_date}
    it "gets the right po_number" do
      allow(subject).to receive(:po_number){"1234-ABCD"}
      expect(subject.to_pdf.po_number).to eq "1234-ABCD"
      expect(pdf.po_number).to eq "1234-ABCD"
    end

    it{expect(subject.to_pdf.terms).to eq "Due on receipt"}


  end


  context "invoice numbering" do

  let(:year){Date.today.year}

    context "default number field" do
      before do
	InvoiceNumberSequence.create({name: "invoice",next_number: 1})
      end
      let!(:next_number){InvoiceNumberSequence.first.next_number}
      subject {Invoice.create}
      it{expect(subject.number).to eq("#{year}-#{next_number}")}
      it{expect(subject.alt_number).to be_nil}
    end



    context "with a specified number field" do
      before do
	InvoiceNumberSequence.create({name: "invoice",next_number: 1})
      end
      let!(:next_number){InvoiceNumberSequence.first.next_number}
      subject {LegacyInvoice.create}
      it{expect(subject.number).to be_nil}
      it{expect(subject.alt_number).to eq("#{year}-#{next_number}")}

    end


    context "scoped invoices" do
      before do
	InvoiceNumberSequence.create({name: "deal_id_1"})
	InvoiceNumberSequence.create({name: "deal_id_2"})

	ScopedInvoice.create(deal_id: 1)
	ScopedInvoice.create(deal_id: 2)

      end
      it{expect(ScopedInvoice.count).to eq 2}
      it{expect(InvoiceNumberSequence.count).to eq 2}


      it{expect(ScopedInvoice.first.number).to eq "#{year}-1"}
      it{expect(ScopedInvoice.last.number).to eq "#{year}-1"}

      it "updates the invoice number if the scope changes" do
	invoice = ScopedInvoice.last
	invoice.update_attributes(deal_id: 1)
	expect(ScopedInvoice.first.number).to eq "#{year}-1"
	expect(ScopedInvoice.last.number).to eq "#{year}-2"
      end


      it "updates the invoice number after a double scope switch" do
	invoice = ScopedInvoice.last
	invoice.update_attributes(deal_id: 1)
	ScopedInvoice.create(deal_id: 2)
	invoice.update_attributes(deal_id: 2)
	expect(invoice.number).to eq "#{year}-3"
      end

      it "does not set the number until the scope is set" do
	invoice = ScopedInvoice.create
	expect(invoice.number).to be_nil
	invoice.update_attributes(deal_id: 2)
	expect(invoice.number).to eq "#{year}-2"
      end

    end



  end


end
