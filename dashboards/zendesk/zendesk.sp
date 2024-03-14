dashboard "zendesk_dashboard" {
  title = "Zendesk Dashboard"

  tags = {
    service  = "Zendesk"
    plugin   = "zendesk"
    type     = "Dashboard"
    category = "Summary"
  }

  container {

    card {
      width = "2"
      sql   = query.zendesk_open_ticket_age.sql
    }

    card {
      width = "2"
      sql   = query.zendesk_ticket_total_age.sql
    }

    # card {
    #   width = "2"
    #   sql   = query.zendesk_oldest_unsolved_ticket.sql
    # }

    card {
      width = "2"
      sql   = <<-EOQ
    select count(*) as "Unsolved Tickets" from zendesk_ticket where status not in ('closed','solved', 'hold');
    EOQ
    }

    card {
      width = "2"
      type  = "info"
      sql   = <<-EOQ
    select count(*) as "Open" from zendesk_ticket where status in ('open', 'new');
    EOQ
    }

    card {
      width = "2"
      type  = "info"
      sql   = <<-EOQ
    select count(*) as "Pending" from zendesk_ticket where status = 'pending';
    EOQ
    }

    card {
      width = "2"
      type  = "info"
      sql   = <<-EOQ
    select count(*) as "Hold" from zendesk_ticket where status = 'hold';
    EOQ
    }

    # chart {
    #  width    = 6
    #  type     = "donut"
    #  grouping = "compare"
    #  title    = "Tickets by Product"
    #  sql      = query.open_ticket_by_product.sql
    # }

    chart {
      width    = 4
      type     = "donut"
      grouping = "compare"
      title    = "Unsolved Tickets by Status"
      sql      = query.tickets_by_status.sql
    }

    chart {
      width = 4
      type  = "donut"
      title = "Tickets created via in last 30 days"
      sql   = query.tickets_created_in_last_30_days.sql
    }

    chart {
      width = 4
      type  = "donut"
      title = "Ticket types solved in last 30 days"
      sql   = query.ticket_types_solved_in_last_30_days.sql
    }

    chart {
      width    = 6
      type     = "column"
      grouping = "compare"
      title    = "Unsolved Tickets by Organization - new, open, pending, hold"
      sql      = query.tickets_by_organization.sql
    }

    chart "issue_age_stats" {
      type  = "column"
      title = "Ticket Aging Metrics  - new, open, pending, hold"
      width = 6

      sql = <<-EOQ
      WITH age_counts AS (
        SELECT
          CASE
          WHEN now()::date - created_at::date > 180 THEN '>6 Months'
          WHEN now()::date - created_at::date > 90 THEN '>3 Months'
          WHEN now()::date - created_at::date >= 30 THEN '>1 Month'
          END AS age_group,
          1 AS issue_count
        FROM
          zendesk_ticket
        WHERE
          status IN ('new', 'open', 'pending', 'hold')
      )
      SELECT
        age_group,
        COUNT(issue_count) AS number_of_tickets
      FROM
        age_counts
      WHERE
        age_group IS NOT NULL
      GROUP BY
        age_group
      ORDER BY
        age_group;
    EOQ
    }

    table {
      column "Ticket" {
        href = <<-EOT
          https://turbot.zendesk.com/agent/tickets/{{.'Ticket' | @uri}}
        EOT
      }
      title = "New and Open Tickets"
      sql   = query.new_and_open_tickets_report.sql
    }

    table {
      column "Ticket" {
        href = <<-EOT
          https://turbot.zendesk.com/agent/tickets/{{.'Ticket' | @uri}}
        EOT
      }
      title = "All Unsolved Tickets"
      sql   = query.all_unsolved_tickets_report.sql
    }
  }
}


query "zendesk_open_ticket_age" {
  sql = <<-EOQ
  select
      sum(date_part('day', now() - t.created_at)) as "Age - new, open (days)"
    from
      zendesk_ticket as t
    where
      t.status in ('new', 'open')
  EOQ
}

query "zendesk_ticket_total_age" {
  sql = <<-EOQ
  select
      sum(date_part('day', now() - t.created_at)) as "Age - new, open, pending (days)"
    from
      zendesk_ticket as t
    where
      t.status in ('new', 'open', 'pending')
  EOQ
}

query "zendesk_oldest_unsolved_ticket" {
  sql = <<-EOQ
    SELECT
      date_part('day', now() - t.created_at) as "Oldest Ticket Age (days)"
    FROM
      zendesk_ticket as t
    WHERE
      t.status IN ('new', 'open', 'pending')
    ORDER BY
      t.created_at ASC
    LIMIT 1
  EOQ
}

query "new_and_open_tickets_report" {
  sql = <<-EOQ
  (
    select
      date_part('day', now() - t.created_at) as "Age (days)",
      t.id as "Ticket",
      t.status as "Status",
      substring(t.subject for 100) as "Subject",
      o.name as "Organization",
      case
        when t.assignee_id is null then 'Unassigned'
      end as "Assignee"
    from
      zendesk_ticket as t,
      zendesk_organization as o
    where
      t.organization_id = o.id
      and t.status in ('new', 'open')
      and t.assignee_id is null
  )
  UNION ALL
  (
    select
      date_part('day', now() - t.created_at) as "Age (days)",
      t.id as "Ticket",
      t.status as "Status",
      substring(t.subject for 100) as "Subject",
      o.name as "Organization",
      u.name as "Assignee"
    from
      zendesk_ticket as t,
      zendesk_user as u,
      zendesk_organization as o
    where
      t.assignee_id = u.id
      and t.organization_id = o.id
      and t.status in ('new', 'open')
  )
  order by
    "Ticket" asc
  EOQ
}

query "all_unsolved_tickets_report" {
  sql = <<-EOQ
    (
      select
        date_part('day', now() - t.created_at) as "Age (days)",
        t.id as "Ticket",
        t.status as "Status",
        substring(t.subject for 100) as "Subject",
        o.name as "Organization",
        case
          when t.assignee_id is null then 'Unassigned'
        end as "Assignee"
      from
        zendesk_ticket as t,
        zendesk_organization as o
      where
        t.organization_id = o.id
        and t.status in ('new', 'open', 'pending', 'hold')
        and t.assignee_id is null
    )
    UNION ALL
    (
      select
        date_part('day', now() - t.created_at) as "Age (days)",
        t.id as "Ticket",
        t.status as "Status",
        substring(t.subject for 100) as "Subject",
        o.name as "Organization",
        u.name as "Assignee"
      from
        zendesk_ticket as t,
        zendesk_user as u,
        zendesk_organization as o
      where
        t.assignee_id = u.id
        and t.organization_id = o.id
        and t.status in ('new', 'open', 'pending', 'hold')
    )
    order by
      "Ticket" asc
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
      and t.status in ('new', 'open', 'pending', 'hold')
    group by
      o.name
    order by
      tickets asc
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

query "open_ticket_by_product" {
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
      status in ('new', 'open', 'hold', 'pending')
  ),
  products as (
    SELECT
      id,
      case
        when field_value is null or field_value = '' then 'other'
        when field_value is not null then field_value
      end as product
    FROM
      custom_field_values
    WHERE
      field_id = '360008999512'
  )
  select
    product,
    count(product)
  from
    products
  group by
    product
  order by
    count
  EOQ
}

query "tickets_by_status" {
  sql = <<-EOQ
    select
    CASE
      WHEN t.status = 'pending' AND EXISTS (SELECT 1  FROM JSONB_ARRAY_ELEMENTS_TEXT(tags) AS tag WHERE tag = 'customer_action') THEN 'customer_action'
      WHEN t.status = 'pending' AND NOT EXISTS (SELECT 1  FROM JSONB_ARRAY_ELEMENTS_TEXT(tags) AS tag WHERE tag = 'customer_action') THEN 'customer_reply'
      ELSE t.status 
    END AS "Status",
      count(Status)
    from
      zendesk_ticket as t
    where
      status in ('new','open','pending','hold')
    group by
      "Status"
  EOQ
}
