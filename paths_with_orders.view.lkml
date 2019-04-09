view: pdt_paths_w_orders {
  derived_table: {
    datagroup_trigger: page_views_update
    distribution: "user_id"
    sortkeys: ["event_time_collections"]
    sql:
      --This query defines paths of user behavior through the site.
      --A path is defined as a one-way journey through the site, in this
      --case starting at a Collections page, then clicking on a Product page,
      --then adding that product to cart, then finally purchasing that product.
      --Most paths won't complete all four steps, so a path could be just
      --a Collections page event, or that and a Product page event, and so on.
      --
      --The first three CTEs of this query get the essential fields from the
      --event tables and use a window function to get the timestamp of the
      --next event of that type.  These are used to join together the different
      --events to define the paths.

      --We could choose to do a select * from these tables and pull all fields
      --though, but it is cleaner to only bring the event_id though and then
      --join the event tables back to this table when needed.  For performance
      --considerations, we do need to define these paths in one query and then
      --create a PDT instead of making these joins in the Explore.
      with homepage as

          (select user_id
                ,event_id
                ,path
                ,"time" as event_time
                ,lead("time") over(partition by user_id order by "time") as event_time_next
          from heap_production.view_homepage),

      product as

          (select user_id
                ,event_id
                ,path
                ,"time" as event_time
                ,lead("time") over(partition by user_id order by "time") as event_time_next
                ,coalesce(previous_page, page_referrer) as previous_page
          from heap_production.view_product),

      add_to_cart as

          (select user_id
                ,event_id
                ,path
                ,"time" as event_time
                ,lead("time") over(partition by user_id order by "time") as event_time_next
                ,product_name
                ,title as product_title
                ,quantity_added_to_cart
                ,product_price
                ,coalesce(previous_page, page_referrer) as previous_page
          from heap_production.add_to_cart),

      --This is where we join these three different events to define our paths.
      --A Product event follows a Collections event when the user id is the same,
      --the Product event time is after the Collection event but before the
      --next Collections event, and the previous page of the Product page event
      --matches the path of the Collections event. The add-to-cart
      --event is then joined to the Product page event using the same logic.
      paths as

          (select c.user_id
              ,h.event_time as event_time_homepage
              ,h.path as path_homepage
              ,h.event_id as event_id_homepage
              ,p.event_time as event_time_product
              ,p.path as path_product
              ,p.event_id as event_id_product
              ,atc.event_time as event_time_atc
              ,atc.path as path_atc
              ,atc.event_id as event_id_atc
              ,atc.product_name
              ,atc.product_title
              ,cast(atc.quantity_added_to_cart as FLOAT8) as quantity_added_to_cart
              ,cast(atc.product_price as FLOAT8) as product_price
          from homepage h
          left join product p
            on h.user_id = p.user_id
            and h.event_time <= p.event_time
            and h.event_time_next >= p.event_time
            and p.previous_page like '%' || h.path || '%'
          left join add_to_cart atc
            on p.user_id = atc.user_id
            and p.event_time <= atc.event_time
            and p.event_time_next >= atc.event_time
            and atc.previous_page like '%' || c.path || '%'),

      --Here we pull in essential fields from the Orders table and use a window
      --function to get the next order time for each customer.
      orders as

          (select "time" as order_time
                ,lag("time") over(partition by user_id order by "time") as last_order_time
                ,order_id
                ,user_id
                ,line_item_names
         from heap_production.confirmed_order),

      --Finally, we join the orders to the paths.  This is a little tricky because
      --if the user purchased more than one product, there will be multiple
      --paths joining to one order.  The Shopify order table doesn't break down the
      --order by line items, but rather gives the total order value and a list of
      --products in the order.  This means that to calculate the value of the
      --individual paths, we need to use the quantity and price information from the
      --add-to-cart event and then join to the orders table with the product name
      --to verify that that product was purchased.

      --We attribute an order to a path if the user id is the same, the add-to-cart
      --event timestamp is before the order, but after the users last order, and
      --the product name from the add-to-cart event matches one of the product names
      --from the order table.
      paths_w_orders as

          (select p.*
              ,rank() over(partition by p.user_id order by p.event_time_collections
                                                          ,p.event_time_product
                                                          ,p.event_time_atc) as path_number
              ,o.order_time as event_time_order
              ,o.order_id
              ,o.line_item_names
          from paths as p
          left join orders o
              on p.user_id = o.user_id
              and p.event_time_atc <= o.order_time
              and (p.event_time_atc > o.last_order_time or o.last_order_time is null)
              and o.line_item_names like '%' || p.product_name || '%')

      select *
            ,user_id || '-' || path_number as path_id
      from paths_w_orders
       ;;
  }

############################ Measures ##############################


  measure: gross_revenue {
    view_label: "(5) Measures"
    type: sum
    value_format_name: usd_0
    sql: ${line_item_value} ;;
    filters: {
      field: order_id
      value: "-null"
    }
  }

  measure: count_items_in_order {
    view_label: "(5) Measures"
    type: sum
    value_format_name: decimal_0
    sql: ${quantity_added_to_cart} ;;
    filters: {
      field: order_id
      value: "-null"
    }
  }

  measure: avg_quantity_per_order {
    view_label: "(5) Measures"
    type: average
    value_format_name: decimal_2
    sql: ${quantity_added_to_cart} ;;
    filters: {
      field: order_id
      value: "-null"
    }
  }

  measure: count_paths {
    view_label: "(5) Measures"
    type: count_distinct
    value_format_name: decimal_0
    sql: ${path_id} ;;
  }

  measure: count_converting_paths {
    view_label: "(5) Measures"
    type: count_distinct
    value_format_name: decimal_0
    sql: ${path_id} ;;
    filters: {
      field: order_id
      value: "-null"
    }
  }

  measure: count_users {
    view_label: "(5) Measures"
    type: count_distinct
    value_format_name: decimal_0
    sql: ${user_id} ;;
  }

    measure: count_converted_users {
    view_label: "(5) Measures"
    type: count_distinct
    value_format_name: decimal_0
    sql: ${user_id} ;;
    filters: {
      field: order_id
      value: "-null"
    }
  }

  measure: count_orders {
    view_label: "(5) Measures"
    type: count_distinct
    value_format_name: decimal_0
    sql: ${order_id} ;;
  }

  measure: conversion_rate_by {
    view_label: "(5) Measures"
    type: number
    value_format_name: percent_2
    sql: 1.0*${count_converting_paths} / nullif(${count_paths}, 0) ;;
  }

########################## Dimensions ##############################

  dimension: user_id {
    view_label: "(0) Paths"
    type: number
    sql: ${TABLE}.user_id ;;
  }

  dimension: path_id {
    view_label: "(0) Paths"
    type: string
    sql: ${TABLE}.path_id ;;
  }


  dimension: path_with_order {
    view_label: "(0) Paths"
    type: yesno
    sql: ${order_id} is not null ;;
  }

  dimension_group: homepage_event {
    label: "Homepage Event"
    view_label: "(1) Homepage"
    type: time
    timeframes: [raw,time,date]
    sql: ${TABLE}.event_time_homepage ;;
  }

  dimension: path_collections {
    label: "Homepage Path"
    view_label: "(1) Homepage"
    type: string
    sql: ${TABLE}.path_collections ;;
  }

  dimension: event_id_collections {
    label: "Homepage Event ID"
    view_label: "(1) Homepage"
    type: number
    sql: ${TABLE}.event_id_collections ;;
  }

  dimension_group: event_product {
    label: "Product Event"
    view_label: "(2) Product"
    type: time
    timeframes: [raw,time,date]
    sql: ${TABLE}.event_time_product ;;
  }

  dimension: path_product {
    label: "Product Path"
    view_label: "(2) Product"
    type: string
    sql: ${TABLE}.path_product ;;
  }

  dimension: event_id_product {
    label: "Product Event ID"
    view_label: "(2) Product"
    type: number
    sql: ${TABLE}.event_id_product ;;
  }

  dimension_group: event_atc {
    label: "Add to Cart Event"
    view_label: "(3) Add to Cart"
    type: time
    timeframes: [raw,time,date]
    sql: ${TABLE}.event_time_atc ;;
  }

  dimension: path_atc {
    label: "Add to Cart Path"
    view_label: "(3) Add to Cart"
    type: string
    sql: ${TABLE}.path_atc ;;
  }

  dimension: event_id_atc {
    label: "Add to Cart Event ID"
    view_label: "(3) Add to Cart"
    type: number
    sql: ${TABLE}.event_id_atc ;;
  }

  dimension: product_name {
    label: "Add to Cart Product Name"
    view_label: "(3) Add to Cart"
    type: string
    sql: ${TABLE}.product_name ;;
  }

  dimension: product_title {
    label: "Add to Cart Product Title"
    view_label: "(3) Add to Cart"
    type: string
    sql: ${TABLE}.product_title ;;
  }

  dimension: quantity_added_to_cart {
    label: "Add to Cart Quantity"
    view_label: "(3) Add to Cart"
    type: string
    sql: ${TABLE}.quantity_added_to_cart ;;
  }

  dimension: product_price {
    label: "Add to Cart Product Price"
    view_label: "(3) Add to Cart"
    type: string
    sql: ${TABLE}.product_price ;;
  }

  dimension_group: order_event {
    view_label: "(4) Order"
    type: time
    timeframes: [raw,time,date]
    sql: ${TABLE}.event_time_order ;;
  }

  dimension: order_id {
    view_label: "(4) Order"
    type: string
    sql: ${TABLE}.order_id ;;
  }

  dimension: line_item_names {
    view_label: "(4) Order"
    type: string
    sql: ${TABLE}.line_item_names ;;
  }


}
