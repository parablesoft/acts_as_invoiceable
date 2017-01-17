FactoryGirl.define do
  factory :invoice_line_item do
    invoice 
    invoice_item 
    rate 100.00
  end

end
