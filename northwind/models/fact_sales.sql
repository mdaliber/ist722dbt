with stg_orders as 
(
    select
        OrderID,  
        {{ dbt_utils.generate_surrogate_key(['employeeid']) }} as employeekey, 
        {{ dbt_utils.generate_surrogate_key(['customerid']) }} as customerkey, 
        replace(to_date(orderdate)::varchar,'-','')::int as orderdatekey,
        from {{source('northwind','Orders')}}
),
stg_order_details as
(
    select
        orderid,
        {{ dbt_utils.generate_surrogate_key(["productid"]) }} as productkey,
        sum(Quantity) as quantity,
        sum(Quantity*UnitPrice) as extendedpriceamount,
        sum(Quantity*UnitPrice*Discount) as discountamount,
        sum((Quantity*UnitPrice) - (Quantity*UnitPrice*Discount)) as soldamount
    from {{source("northwind","Order_Details")}}
    group by orderid, productid
),
stg_shippers as (
    select * from {{source('northwind','Shippers')}}
)
select  
    o.*,
    s.companyname as shippercompanyname,
    od.quantityonorder, od.totalorderamount,
    o.shippeddatekey - o.orderdatekey as daysfromordertoshipped,
    o.requireddatekey - o.orderdatekey as daysfromordertorequired,
    o.shippeddatekey - o.requireddatekey as shippedtorequireddelta,
    case when o.shippeddatekey - o.requireddatekey <=0 then 'Y' else 'N' end as shippedontime
from stg_orders o
    join stg_order_details od on o.orderid = od.orderid
    join stg_shippers s on s.shipperid = o.shipvia
