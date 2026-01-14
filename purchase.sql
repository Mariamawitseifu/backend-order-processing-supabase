create or replace function process_purchase(
  p_business_id uuid,
  p_customer_id uuid,
  p_items jsonb
)
returns uuid
language plpgsql
as $$
declare
  v_order_id uuid;
  v_total numeric := 0;
  v_customer customers;
  v_item record;
  v_product products;
begin
  -- Lock customer row
  select * into v_customer
  from customers
  where id = p_customer_id
    and business_id = p_business_id
  for update;

  if not found then
    raise exception 'Customer not found';
  end if;

  -- Validate stock + calculate total
  for v_item in
    select * from jsonb_to_recordset(p_items)
    as i(product_id uuid, quantity int)
  loop
    select * into v_product
    from products
    where id = v_item.product_id
      and business_id = p_business_id
    for update;

    if v_product.stock < v_item.quantity then
      raise exception 'Insufficient stock';
    end if;

    v_total := v_total + (v_product.price * v_item.quantity);
  end loop;

  -- Validate credit limit
  if v_customer.credit_used + v_total > v_customer.credit_limit then
    raise exception 'Credit limit exceeded';
  end if;

  -- Create order
  insert into orders (business_id, customer_id, total_amount)
  values (p_business_id, p_customer_id, v_total)
  returning id into v_order_id;

  -- Insert items + update stock
  for v_item in
    select * from jsonb_to_recordset(p_items)
    as i(product_id uuid, quantity int)
  loop
    select * into v_product
    from products
    where id = v_item.product_id;

    insert into order_items (
      order_id, product_id, quantity, unit_price
    )
    values (
      v_order_id,
      v_product.id,
      v_item.quantity,
      v_product.price
    );

    update products
    set stock = stock - v_item.quantity
    where id = v_product.id;
  end loop;

  -- Update customer credit
  update customers
  set credit_used = credit_used + v_total
  where id = p_customer_id;

  -- Record unpaid balance
  insert into credit_ledger (
    business_id, customer_id, order_id, amount
  )
  values (
    p_business_id, p_customer_id, v_order_id, v_total
  );

  return v_order_id;
end;
$$;
