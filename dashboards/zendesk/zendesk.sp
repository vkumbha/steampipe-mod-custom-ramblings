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

