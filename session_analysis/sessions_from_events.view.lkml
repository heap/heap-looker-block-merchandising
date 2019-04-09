view: pdt_sessions_from_events {
  derived_table: {
    datagroup_trigger: page_views_update
    distribution: "user_id"
    sortkeys: ["session_start_at", "session_end_at"]
    sql: with all_events as

            --This query redefines sessions without the Heap session id.  This may be needed
            --if there are multiple Heap session ids associated with a single user id
            --during the same time period.  This can happen with certain mobile devices
            --or browsers that automatically delete cookies.

            --All unique event times and user ids.
            (select distinct
                    "time" as event_time
                    ,user_id
                    ,event_id
            from heap_production.all_events),

        last_and_next_times as

            --Window functions calculate the previous and next event times
            --for each event and each user, and the time between those events and the
            --previous and next events.
            (select *
                    ,lag(event_time) over(partition by user_id order by event_time) as last_time
                    ,lead(event_time) over(partition by user_id order by event_time) as next_time
                    ,datediff(minute, lag(event_time) over(partition by user_id order by event_time), event_time) as time_from_last
                    ,datediff(minute, event_time, lead(event_time) over(partition by user_id order by event_time)) as time_to_next
            from all_events),

      sessions_start as

          --Define session start time as either the first event for a user, or the first
          --event for a user is 30 or more minutes.  We also identify the session
          --number for each user.
          (select user_id
                ,event_time as session_start_at
                ,event_id as event_id_start
                ,rank() over(partition by user_id order by event_time) as session_number
          from last_and_next_times
          where last_time is null or time_from_last >= 30),

      sessions_end as

          --Define session end time as either the last event for a user, or the last
          --event before 30 or more minutes of inactivity.
          (select user_id
                ,event_time as session_end_at
                ,event_id as event_id_end
                ,rank() over(partition by user_id order by event_time) as session_number
          from last_and_next_times
          where next_time is null or time_to_next >= 30),

      sessions as

          --Start and end times are joined together and we create a new session id
          --that is the user id concatenated with the session number.
          (select ss.user_id
                ,ss.session_number
                ,ss.user_id || '-' || ss.session_number as looker_session_id
                ,ss.session_start_at
                ,dateadd(minute, 30, se.session_end_at) as session_end_at
                ,ss.event_id_start
                ,se.event_id_end
          from sessions_start ss
          join sessions_end se
              on ss.user_id = se.user_id
              and ss.session_number = se.session_number
          where cast(ss.session_start_at as date) >= '2019-01-16')

      select * from sessions
       ;;
  }

################### Measures #######################

  measure: count_sessions {
    type: count_distinct
    view_label: "(0) Measures"
    sql: ${looker_session_id} ;;
  }

  measure: count_users {
    view_label: "(0) Measures"
    type: count_distinct
    sql: ${user_id} ;;
  }

  measure: avg_length_session {
    view_label: "(0) Measures"
    type: average
    value_format_name: decimal_2
    sql: ${length_of_sess_min} ;;
  }

################## Dimensions ######################


  dimension: user_id {
    type: number
    sql: ${TABLE}.user_id ;;
  }

  dimension: sess_with_order {
    type: yesno
    sql: ${confirmed_order.order_id} is not null ;;
  }

  dimension: event_id_start {
    hidden: yes
    type: number
    sql: ${TABLE}.event_id_start ;;
  }

  dimension: event_id_end {
    hidden: yes
    type: number
    sql: ${TABLE}.event_id_end ;;
  }

  dimension: session_number {
    type: number
    sql: ${TABLE}.session_number ;;
  }

  dimension: looker_session_id {
    type: string
    description: "This is the user id with the user's session sequence number"
    primary_key: yes
    sql: ${TABLE}.looker_session_id ;;
  }

  dimension_group: session_start {
    type: time
    timeframes: [raw, time, date, day_of_week]
    sql: ${TABLE}.session_start_at ;;
  }

  dimension_group: session_end {
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.session_end_at ;;
  }


  dimension: length_of_sess_min {
    type: number
    value_format_name: decimal_2
    sql: datediff(second, ${session_start_raw}, ${session_end_raw})/60 ;;
  }



  set: detail {
    fields: [user_id, session_number, session_start_time, session_end_time]
  }
}
