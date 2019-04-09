view: confirmed_order {
  sql_table_name: heap_production.confirmed_order ;;


################## Measures ##################

  measure: count_sessions {
    type: count_distinct
    hidden: yes
    sql: ${looker_session_id} ;;
  }

  measure: conversion_rate_s {
    view_label: "(0) Measures"
    label: "Conversion Rate (Sessions)"
    type: number
    value_format_name: percent_2
    sql: 1.0*${count_sessions}/nullif(${pdt_sessions_from_events.count_sessions},0) ;;
  }

  measure: count_users {
    type: count_distinct
    hidden: yes
    sql: ${user_id} ;;
  }

  measure: conversion_rate_u {
    label: "Conversion Rate (Users)"
    view_label: "(0) Measures"
    type: number
    value_format_name: percent_2
    sql: 1.0*${count_users}/nullif(${pdt_sessions_from_events.count_users},0) ;;
  }

  measure: count_orders {
    type: count_distinct
    view_label: "(0) Measures"
    sql: ${order_id} ;;
    drill_fields: [order_id, user_id, looker_session_id, line_item_names, total_price, event_time]
  }

  measure: total_price_usd {
    type: sum
    view_label: "(0) Measures"
    value_format_name: usd
    sql: cast(${price_usd} as float) ;;
  }

  measure: avg_price_usd {
    type: average
    view_label: "(0) Measures"
    value_format_name: usd
    sql: cast(${price_usd} as float) ;;
  }

  measure: rev_per_session {
    type: number
    view_label: "(0) Measures"
    description: "Average Revenue per Session"
    value_format_name: usd
    sql: ${total_price_usd} /nullif(${pdt_sessions_from_events.count_sessions},0) ;;
  }

  measure: avg_num_products_in_order {
    type: average
    view_label: "(0) Measures"
    value_format_name: decimal_2
    sql: ${unique_products_in_order} ;;
  }

################## Dimensions ####################

  dimension: unique_products_in_order {
    type: number
    sql: regexp_count(${line_item_product_ids}, '","') + 1 ;;
  }

  dimension: looker_session_id {
    hidden: yes
    type: string
    sql:${user_id} || '-' || ${pdt_sessions_from_events.session_number} ;;
  }

  dimension: browser_ip {
    hidden: yes
    type: string
    sql: ${TABLE}.browser_ip ;;
  }

  dimension: landing_site_utm_campaign {
    hidden: yes
    type: string
    sql: ${TABLE}.landing_site_utm_campaign ;;
  }

  dimension: landing_site_utm_medium {
    hidden: yes
    type: string
    sql: ${TABLE}.landing_site_utm_medium ;;
  }

  dimension: landing_site_utm_source {
    hidden: yes
    type: string
    sql: ${TABLE}.landing_site_utm_source ;;
  }

  dimension: discount_codes {
    type: string
    sql: ${TABLE}.discount_codes ;;
  }

  dimension: shop_url {
    hidden: yes
    type: string
    sql: ${TABLE}.shop_url ;;
  }

  dimension: referring_site {
    hidden: yes
    type: string
    sql: ${TABLE}.referring_site ;;
  }

  dimension: customer_locale {
    hidden: yes
    type: string
    sql: ${TABLE}.customer_locale ;;
  }

  dimension: landing_site {
    hidden: yes
    type: string
    sql: ${TABLE}.landing_site ;;
  }

  dimension: total_weight {
    hidden: yes
    type: string
    sql: ${TABLE}.total_weight ;;
  }

  dimension: line_item_product_ids {
    type: string
    sql: ${TABLE}.line_item_product_ids ;;
  }

  dimension: billing_address_province {
    type: string
    sql: ${TABLE}.billing_address_province ;;
  }

  dimension: line_item_skus {
    type: string
    sql: ${TABLE}.line_item_skus ;;
  }

  dimension: buyer_accepts_marketing {
    type: string
    sql: ${TABLE}.buyer_accepts_marketing ;;
  }

  dimension: currency {
    type: string
    sql: ${TABLE}.currency ;;
  }

  dimension: line_item_names {
    type: string
    sql: ${TABLE}.line_item_names ;;
    suggest_explore: pdt_sessions_from_events
    suggest_dimension: add_to_cart_pp_collection.product_name
  }

  dimension: line_item_titles {
    type: string
    sql: ${TABLE}.line_item_titles ;;
  }

  dimension: line_items {
    type: string
    sql: ${TABLE}.line_items ;;
  }

  dimension: name {
    hidden: yes
    type: string
    sql: ${TABLE}.name ;;
  }

  dimension: net_revenue {
    type: string
    sql: ${TABLE}.net_revenue ;;
  }

  dimension: order_id {
    type: string
    primary_key: yes
    sql: ${TABLE}.order_id ;;
  }

  dimension: order_number {
    type: string
    sql: ${TABLE}.order_number ;;
  }

  dimension: processing_method {
    hidden: yes
    type: string
    sql: ${TABLE}.processing_method ;;
  }

  dimension: source_name {
    hidden: yes
    type: string
    sql: ${TABLE}.source_name ;;
  }

  dimension: subtotal_price {
    type: number
    sql: ${TABLE}.subtotal_price ;;
  }

  dimension: taxes_included {
    type: string
    sql: ${TABLE}.taxes_included ;;
  }

  dimension: total_discounts {
    type: number
    sql: ${TABLE}.total_discounts ;;
  }

  dimension: total_line_items_price {
    type: number
    sql: ${TABLE}.total_line_items_price ;;
  }

  dimension: total_price {
    type: number
    sql: ${TABLE}.total_price ;;
  }

  dimension: price_usd {
    type: number
    sql: ${TABLE}.total_price_usd ;;
  }

  dimension: total_tax {
    type: number
    sql: ${TABLE}.total_tax ;;
  }

  dimension: continent {
    type: string
    sql: ${TABLE}.continent ;;
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

  dimension: session_id {
    hidden: yes
    type: number
    sql: ${TABLE}.session_id ;;
  }

  dimension_group: event {
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}."time" ;;
  }

  dimension: type {
    hidden: yes
    type: string
    sql: ${TABLE}.type ;;
  }

  dimension: library {
    hidden: yes
    type: string
    sql: ${TABLE}.library ;;
  }

################# Unused #####################
#
#   dimension: browser_type {
#     type: string
#     sql: ${TABLE}.browser_type ;;
#   }
#
#   dimension: cancel_reason {
#     type: string
#     sql: ${TABLE}.cancel_reason ;;
#   }
#
#   dimension: city {
#     type: string
#     sql: ${TABLE}.city ;;
#   }
#
#   dimension: country {
#     type: string
#     map_layer_name: countries
#     sql: ${TABLE}.country ;;
#   }
#
#   dimension: custom_marketing_channel_jonathan {
#     type: string
#     sql: ${TABLE}.custom_marketing_channel_jonathan ;;
#   }
#
#   dimension: desktop_breadcrumbs {
#     type: string
#     sql: ${TABLE}.desktop_breadcrumbs ;;
#   }
#
#   dimension: device_type {
#     type: string
#     sql: ${TABLE}.device_type ;;
#   }
#
#   dimension: href_category {
#     type: string
#     sql: ${TABLE}.href_category ;;
#   }
#
#   dimension: ip {
#     type: string
#     sql: ${TABLE}.ip ;;
#   }
#
#   dimension: landing_site_utm_content {
#     type: string
#     sql: ${TABLE}.landing_site_utm_content ;;
#   }
#
#   dimension: landing_site_utm_term {
#     type: string
#     sql: ${TABLE}.landing_site_utm_term ;;
#   }
#
#   dimension: main_pcp_image_on_model {
#     type: string
#     sql: ${TABLE}.main_pcp_image_on_model ;;
#   }
#
#   dimension: marketing_channel {
#     type: string
#     sql: ${TABLE}.marketing_channel ;;
#   }
#
#   dimension: page_referrer_category {
#     type: string
#     sql: ${TABLE}.page_referrer_category ;;
#   }
#
#   dimension: page_type {
#     type: string
#     sql: ${TABLE}.page_type ;;
#   }
#
#   dimension: path_category {
#     type: string
#     sql: ${TABLE}.path_category ;;
#   }
#
#   dimension: pcp_main_hover_image {
#     type: string
#     sql: ${TABLE}.pcp_main_hover_image ;;
#   }
#
#   dimension: pcp_main_image {
#     type: string
#     sql: ${TABLE}.pcp_main_image ;;
#   }
#
#   dimension: platform {
#     type: string
#     sql: ${TABLE}.platform ;;
#   }
#
#   dimension: previous_page {
#     type: string
#     sql: ${TABLE}.previous_page ;;
#   }
#
#   dimension: promo_code_channels {
#     type: string
#     sql: ${TABLE}.promo_code_channels ;;
#   }
#
#   dimension: referrer {
#     type: string
#     sql: ${TABLE}.referrer ;;
#   }
#
#   dimension: refunds {
#     type: string
#     sql: ${TABLE}.refunds ;;
#   }
#
#   dimension: region {
#     type: string
#     sql: ${TABLE}.region ;;
#   }
#
#   dimension: search_engine {
#     type: string
#     sql: ${TABLE}.search_engine ;;
#   }
#
#   dimension_group: session {
#     type: time
#     timeframes: [
#       raw,
#       time,
#       date,
#       week,
#       month,
#       quarter,
#       year
#     ]
#     sql: ${TABLE}.session_time ;;
#   }
#
#   dimension: social_network {
#     type: string
#     sql: ${TABLE}.social_network ;;
#   }
#
#   dimension: tags {
#     type: string
#     sql: ${TABLE}.tags ;;
#   }
#
#   dimension: target_text {
#     type: string
#     sql: ${TABLE}.target_text ;;
#   }

}
