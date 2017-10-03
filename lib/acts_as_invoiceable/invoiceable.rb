module ActsAsInvoiceable
  module Invoiceable
    def self.included(base)

      base.class_eval do
	defaults = {
	  number_field: :number,
	  scope: nil,
	  prefix: "#{Date.today.year}-"
	}

	field,scope,prefix = defaults.merge(base.invoiceable_configuration).values
	sequence = scope ?  ->(invoice) { "#{scope}_#{invoice[scope]}"} : nil

	assign_if =  -> (invoice) do 
	  invoice.changed_attributes.include?(scope) || invoice[field].nil? 
	end

	has_invoice_number field, assign_if: assign_if, prefix: prefix, invoice_number_sequence: sequence,scope: scope
	has_many :invoice_line_items, dependent: :destroy
      end


    end

    def invoice_template

    end
    def pdf_bill_to
      "#{billing_name}\n#{billing_address_1}\n#{billing_city}, #{billing_state}, #{billing_zip}"
    end

    TERMS_DUE_ON_RECEIPT = "Due on receipt"
    def to_pdf
      payday = Payday::Invoice.new(invoice_number: number, bill_to: pdf_bill_to,invoice_date: Date.today, po_number: po_number, terms: TERMS_DUE_ON_RECEIPT )
      invoice_line_items.each {|li| payday.line_items << Payday::LineItem.new(li.pdf_params)}
      payday
    end

    def to_qb
      {
	:invoice_add_rq => {
	  xml_attributes: {},
	  "InvoiceAdd" => {
	    "CustomerRef" => {
	      "FullName" => "#{billing_name}"
	    },
	    "TemplateRef" =>{
	      "FullName" => "#{invoice_template}",
	    },
	    "RefNumber" => "#{number}",
	    "BillAddress" => {
	      "Addr1" => "#{billing_address_1}",
	      "Addr2" => "#{billing_address_2}",
	      "City" => "#{billing_city}",
	      "State" => "#{billing_state}",
	      "PostalCode" => "#{billing_zip}"
	    },
	    "PONumber" => "#{po_number}",
	    "TermsRef" => {
	      "FullName" => TERMS_DUE_ON_RECEIPT
	    },
	    "DueDate" => "#{due_date}",
	    "Other" => "#{id}",
	    "InvoiceLineAdd" => invoice_line_items.order(:id).map(&:to_qb)
	  }
	}
      }
    end

    def total
      invoice_line_items.map{|item|item.amount}.sum
    end

  end
end
