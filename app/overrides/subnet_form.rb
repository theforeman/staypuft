Deface::Override.new(
    :virtual_path => "subnets/_form",
    :name => "add_staypuft_fields_to_subnet",
    :insert_bottom => 'div.tab-pane#primary',
    :partial => 'staypuft/subnets/additional_form'
)
