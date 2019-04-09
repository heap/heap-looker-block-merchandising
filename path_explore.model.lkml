explore: pdt_paths_w_orders {
  label: "Path-based Site Behavior"
  hidden: yes
  join: view_homepage {
    view_label: "(1) Collections"
    type: left_outer
    relationship: one_to_one
    sql_on: ${pdt_paths_w_orders.event_id_collections} = ${view_homepage.event_id} ;;
  }
  join: view_product {
    view_label: "(2) Product"
    fields: [product_name, title]
    type: left_outer
    relationship: one_to_one
    sql_on: ${pdt_paths_w_orders.event_id_product}  = ${view_product.event_id} ;;
  }
  join: add_to_cart_pp_collection {
    view_label: "(3) Add to Cart"
    fields: [product_name, add_to_cart_pp_collection.product_price, add_to_cart_pp_collection.title]
    type: left_outer
    relationship: one_to_one
    sql_on: ${pdt_paths_w_orders.event_id_atc}  = ${add_to_cart_pp_collection.event_id} ;;
  }
  join: confirmed_order {
    view_label: "(4) Confirmed Order"
    relationship: many_to_many
    type: left_outer
    sql_on: ${pdt_sessions_from_events.order_id} = ${confirmed_order.order_id} ;;
  }
}