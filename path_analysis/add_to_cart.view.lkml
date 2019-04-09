view: add_to_cart {
  sql_table_name: heap_production.add_to_cart ;;



################## Dimensions ####################

  dimension: looker_session_id {
    hidden: yes
    type: string
    sql:${user_id} || '-' || ${pdt_sessions_from_events.session_number} ;;
  }

  dimension: cart_total_value {
    type: string
    sql: ${TABLE}.cart_total_value ;;
  }

  dimension: product_price {
    type: string
    sql: ${TABLE}.product_price ;;
  }

  dimension: quantity_added_to_cart {
    type: string
    sql: ${TABLE}.quantity_added_to_cart ;;
  }

  dimension: color_added_to_cart {
    type: string
    sql: ${TABLE}.color_added_to_cart ;;
  }

  dimension: product_name {
    type: string
    sql: ${TABLE}.product_name ;;
  }

  dimension: previous_page {
    hidden: yes
    type: string
    sql: ${TABLE}.previous_page ;;
  }

  dimension: event_id {
    hidden: yes
    type: number
    sql: ${TABLE}.event_id ;;
  }

  dimension: user_id {
    hidden: yes
    type: number
    sql: ${TABLE}.user_id ;;
  }

  dimension_group: event {
    type: time
    timeframes: [raw, time]
    sql: ${TABLE}."time" ;;
  }

  dimension: path {
    type: string
    sql: ${TABLE}.path ;;
  }

}
