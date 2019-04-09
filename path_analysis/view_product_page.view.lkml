view: view_product_pp_collection {
  sql_table_name: heap_production.view_product_pp_collection ;;


################### Measures #####################


################## Dimensions ####################

  dimension: looker_session_id {
    hidden: yes
    type: string
    sql:${user_id} || '-' || ${pdt_sessions_from_events.session_number} ;;
  }

  dimension: product_price {
    type: number
    value_format_name: usd
    sql: cast(${TABLE}.product_price as float) ;;
  }

  dimension: product_price_tier {
    type: tier
    tiers: [0,20,40,60,80,100,120,140,160,180,200,220,240,260]
    style: integer
    sql: ${product_price} ;;
  }

  dimension: previous_page {
    hidden: yes
    type: string
    sql: ${TABLE}.previous_page ;;
  }

    dimension_group: event {
    type: time
    timeframes: [raw, time]
    sql: ${TABLE}.time ;;
  }

 
  dimension: path {
    type: string
    sql: ${TABLE}.path ;;
  }


    dimension: product_name {
    type: string
    sql: ${TABLE}.product_name ;;
  }

    dimension: product_id {
    type: string
    sql: ${TABLE}.product_id ;;
  }

}
