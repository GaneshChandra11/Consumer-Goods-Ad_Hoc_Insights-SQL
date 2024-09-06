select * from dim_customer;

/* Request Query -1 */

select distinct(market)
from dim_customer
where region = 'APAC'
and customer = 'Atliq Exclusive';

/*----------------------------------*/

select * from fact_sales_monthly;
select * from dim_product;

/* Request Query -2 */


with up_fy as (
select
	count(distinct case when fiscal_year =2020 then product_code end) as unique_products_2020,
    count(distinct case when fiscal_year =2021 then product_code end) as unique_products_2021 
from fact_sales_monthly
)

select unique_products_2020,unique_products_2021,
concat(
round(((unique_products_2021-unique_products_2020)*100)/unique_products_2020,2),
'%') as percentage_chg
from up_fy;


/*----------------------------------*/

select * from dim_product;

/* Request Query -3 */

select 
segment, count(distinct product_code) as product_count 
from dim_product
group by segment
order by product_count desc;



/*----------------------------------*/

/* Request Query -4 */

with upc_20_21 as(
select 
prd.segment as segment,
count(distinct case when fsm.fiscal_year=2020 then fsm.product_code end) as product_count_2020,
count(distinct case when fsm.fiscal_year=2021 then fsm.product_code end) as product_count_2021
from fact_sales_monthly fsm
join dim_product prd
on prd.product_code = fsm.product_code
group by segment
)
select segment, product_count_2020, product_count_2021,
(product_count_2021-product_count_2020)as difference 
from upc_20_21
order by difference desc;

/*----------------------------------*/

select * from fact_manufacturing_cost;

/* Request Query -5 */

select 
fmc.product_code,
prd.product, 
concat('$',round(fmc.manufacturing_cost,2)) as manufacturing_cost
from fact_manufacturing_cost fmc 
join dim_product prd
on prd.product_code = fmc.product_code
where 
fmc.manufacturing_cost = (select min(manufacturing_cost)from fact_manufacturing_cost)
or
fmc.manufacturing_cost = (select max(manufacturing_cost)from fact_manufacturing_cost)
order by fmc.manufacturing_cost desc;

/*----------------------------------*/

select * from fact_pre_invoice_deductions;
select * from dim_customer;

/* Request Query -6 */

select 
inv_dis.customer_code,
cus.customer as customer,
concat(round((avg(pre_invoice_discount_pct)*100),2),'%') as average_discount_percentage
from fact_pre_invoice_deductions inv_dis
join dim_customer cus
on cus.customer_code = inv_dis.customer_code
where
inv_dis.fiscal_year = 2021
and
cus.market = 'India'
group by inv_dis.customer_code, cus.customer
order by avg(pre_invoice_discount_pct) desc
limit 5;

/*----------------------------------*/

select * from fact_gross_price;
select * from fact_sales_monthly;
select * from dim_customer;
/* Request Query -7 */

select 
monthname(sm.date) as month_,
year(sm.date) as year_,
concat('$',round(sum((sm.sold_quantity*gp.gross_price)/1000000),2)) as Gross_sales_Amount
from fact_sales_monthly sm
join 
dim_customer cus on cus.customer_code = sm.customer_code
join 
fact_gross_price gp on gp.product_code = sm.product_code
where cus.customer = 'Atliq Exclusive'
group by month_, year_
order by year_, month_ ;

/*----------------------------------*/

select * from fact_sales_monthly;

/* Request Query -8 */

select 
case 
	when month(date) in (9,10,11) then 'Q1'
    when month(date) in (12,1,2) then 'Q2'
    when month(date) in (3,4,5) then 'Q3'
    else 
		'Q4'
end as Quarter_,
sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly sm
where fiscal_year = 2020
group by Quarter_
order by total_sold_quantity desc;

/*----------------------------------*/

select * from fact_gross_price;
select * from fact_sales_monthly;
select * from dim_customer;

/* Request Query - 9 */

with gross_sales as(
select cus.channel as channel,
round(((sum(gp.gross_price*sm.sold_quantity))/1000000),2) as gross_sales_mln
from dim_customer cus
join fact_sales_monthly sm
on sm.customer_code = cus.customer_code
join fact_gross_price gp
on gp.product_code = sm.product_code
where sm.fiscal_year = 2021
group by cus.channel)
select channel,
concat('$',gross_sales_mln) as gross_sales_mln,
concat(round((gross_sales_mln/sum(gross_sales_mln)over())*100,2),'%') as percentage
from gross_sales
group by channel
order by gross_sales_mln ;

/*----------------------------------*/

select * from fact_sales_monthly;
select * from dim_product;

/* Request Query -10 */

with rank_ as(
select 
prd.division as division,
sm.product_code as product_code,
prd.product as product,
sum(sold_quantity) as total_sold_quantity,
dense_rank() over(partition by prd.division order by sum(sold_quantity) desc) as rank_order
from fact_sales_monthly sm
join dim_product prd
on prd.product_code = sm.product_code
where sm.fiscal_year = 2021
group by division, product_code, product
)
select division, product_code, product, total_sold_quantity, rank_order
from rank_
where rank_order <= 3;


/*----------------------------------*/
 
