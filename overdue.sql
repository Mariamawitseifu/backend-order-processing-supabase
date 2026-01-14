select
  c.id,
  c.name,
  sum(l.amount) as overdue_amount
from credit_ledger l
join customers c on c.id = l.customer_id
where l.paid = false
  and l.created_at < now() - interval '30 days'
group by c.id, c.name
having sum(l.amount) > 0;
