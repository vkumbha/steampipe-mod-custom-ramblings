dashboard "dashboard_tutorial" {
  title = "Zendesk Report"

  text {
    value = "Zendesk Tickets Report"
  }

  container {

    card {
      width = "2"
      sql   = query.zendesk_ticket_total_age.sql
    }

    card {
      width = "2"
      sql   = <<-EOQ
    select count(*) as "Total Tickets" from zendesk_ticket where status not in ('closed','solved');
    EOQ
    }

    card {
      width = "2"
      type  = "info"
      sql   = <<-EOQ
    select count(*) as "Open" from zendesk_ticket where status = 'open';
    EOQ
    }

    card {
      width = "2"
      type  = "info"
      sql   = <<-EOQ
    select count(*) as "Hold" from zendesk_ticket where status = 'hold';
    EOQ
    }

    card {
      width = "2"
      type  = "info"
      sql   = <<-EOQ
    select count(*) as "Pending" from zendesk_ticket where status = 'pending';
    EOQ
    }

    chart {
      width = 4
      type  = "column"
      grouping = "compare"
      title = "Tickets by Organization"
      sql   = query.tickets_by_organization.sql
    }

    chart {
      width = 4
      type  = "donut"
      title = "Ticket types solved in last 30 days"
      sql   = query.ticket_types_solved_in_last_30_days.sql
    }

    chart {
      width = 4
      type  = "donut"
      title = "Tickets created via in last 30 days"
      sql   = query.tickets_created_in_last_30_days.sql
    }

    table {
      sql = query.zendesk_ticket_aging_report.sql
    }

  }
}

query "zendesk_ticket_total_age" {
  sql = <<-EOQ
  select
      sum(date_part('day', now() - t.created_at)) as "Total Age (days)"
    from
      zendesk_ticket as t
    where
      t.status in ('open', 'pending', 'hold')
  EOQ
}

query "zendesk_ticket_aging_report" {
  sql = <<-EOQ
  (
    select
      date_part('day', now() - t.created_at) as age,
      t.id,
      t.status,
      case
        when t.assignee_id is null then 'Unassigned'
      end as agent,
      o.name as organization,
      substring(t.subject for 100) as ticket
    from
      zendesk_ticket as t,
      zendesk_organization as o
    where
      t.organization_id = o.id
      and t.status in ('open', 'pending', 'hold')
      and t.assignee_id is null
  )
  UNION ALL
  (
    select
      date_part('day', now() - t.created_at) as age,
      t.id,
      t.status,
      u.name as agent,
      o.name as organization,
      substring(t.subject for 100) as ticket
    from
      zendesk_ticket as t,
      zendesk_user as u,
      zendesk_organization as o
    where
      t.assignee_id = u.id
      and t.organization_id = o.id
      and t.status in ('open', 'pending', 'hold')
  )
  order by
    id asc
  EOQ
}

query "tickets_by_organization" {
  sql = <<-EOQ
    select
      o.name as organization,
      count(t.id) as tickets
    from
      zendesk_ticket as t,
      zendesk_organization as o
    where
      t.organization_id = o.id
      and t.status in ('open', 'pending', 'hold')
    group by
      o.name
    order by
      tickets desc
  EOQ
}

query "tickets_created_in_last_30_days" {
  sql = <<-EOQ
    select
      via_channel,
      count(via_channel)
    from
      zendesk_ticket
    where
      created_at >= now() - interval '30' day
    group by
      via_channel
  EOQ
}

query "ticket_types_solved_in_last_30_days" {
  sql = <<-EOQ
    WITH
  custom_field_values AS (
    SELECT
      id,
      (jsonb_array_elements(custom_fields) ->> 'id') AS field_id,
      (jsonb_array_elements(custom_fields) ->> 'value') AS field_value
    FROM
      zendesk_ticket
    WHERE
      status in ('solved', 'closed')
      and updated_at >= now() - interval '30' day
  ),
  all_types as (
    SELECT
      id,
      case
        when field_value is null
        or field_value = '' then 'other'
        when field_value is not null then field_value
      end as field_value
    FROM
      custom_field_values
    WHERE
      field_id = '360008999512'
  )
  select
    field_value,
    count(field_value)
  from
    all_types
  group by
    field_value
  order by
    count
  EOQ
}