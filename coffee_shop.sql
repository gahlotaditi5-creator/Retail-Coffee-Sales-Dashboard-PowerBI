-- database creation 
create database Coffee_shop_DB;

-- viewing the table
select * from coffee_shop_sales;

-- viewing the table structure
desc coffee_shop_sales;

/**************************************DATA CLEANING**********************************************/

-- changing the column name of ï»¿transaction_id to transaction_id i.e. removing special characters

alter table coffee_shop_sales
rename column ï»¿transaction_id to transaction_id;

/*****************************CHANGING TRANSACTION DATE FROM TEXT TO DATE************************/

update coffee_shop_sales
set transaction_date=str_to_date(transaction_date,'%d-%m-%Y') ;

alter table coffee_shop_sales
modify column transaction_date date;

/*****************************CHANGING TRANSACTION TIME FROM TEXT TO TIME************************/

alter table coffee_shop_sales
modify column transaction_time time;

/*********************************Problem analysis***********************************************/

                                      -- KPI’S REQUIREMENTS

/*********************************1. Total Sales Analysis:*****************************************/

-- 1.1. Calculate the total sales for each respective month.

select date_format(transaction_date,'%Y-%m') as transaction_month,
round(sum(transaction_qty*unit_price),2) as total_sales  
from coffee_shop_sales
-- where transaction_date between '2023-05-01' and '2023-05-31' -- for specific month
group by date_format(transaction_date,'%Y-%m');
/**************************************************************************************************/
-- 1.2 Determine the month-on-month increase or decrease in sales.

with monthly_sales as(
select date_format(transaction_date,'%Y-%m') as transaction_month,
round(sum(transaction_qty*unit_price),2) as total_sales,
round(lag(sum(transaction_qty*unit_price)) 
              over(order by date_format(transaction_date,'%Y-%m')),2) as previous_month_sales  
from coffee_shop_sales
-- where transaction_date between '2023-04-01' and '2023-05-31' -- for specific month
group by date_format(transaction_date,'%Y-%m'))
select transaction_month,
total_sales , previous_month_sales,
round((((total_sales-previous_month_sales)/previous_month_sales)*100),2) as MoM_sales
from monthly_sales
 ;
/**************************************************************************************************/
-- 1.3 Calculate the difference in sales between the selected month and the previous month.

with monthly_sales as(
select date_format(transaction_date,'%Y-%m') as transaction_month,
round(sum(transaction_qty*unit_price),2) as total_sales,
round(lag(sum(transaction_qty*unit_price)) 
              over(order by date_format(transaction_date,'%Y-%m')),2) as previous_month_sales  
from coffee_shop_sales
-- where transaction_date between '2023-04-01' and '2023-05-31' -- for specific month
group by date_format(transaction_date,'%Y-%m'))
select transaction_month,
total_sales , previous_month_sales,
round((total_sales-previous_month_sales),2) as MoM_sales
from monthly_sales
;
/**************************************************************************************************/
-- 2 Total Orders Analysis:
-- 2.1 Calculate the total number of orders for each respective month.

select date_format(transaction_date,'%Y-%m') as transaction_month,
count(*)as total_orders
from coffee_shop_sales
-- where transaction_date between '2023-05-01' and '2023-05-31' -- for specific month
group by date_format(transaction_date,'%Y-%m')
;
/**************************************************************************************************/
-- 2.2 Determine the month-on-month increase or decrease in the number of orders.

select date_format(transaction_date,'%Y-%m') as transaction_month,
count(*)as total_orders,
lag(count(*)) over(order by date_format(transaction_date,'%Y-%m')) as previous_month_total_orders,
round(
       (((count(*) - lag(count(*)) over(order by date_format(transaction_date,'%Y-%m')))/
	         lag(count(*)) over(order by date_format(transaction_date,'%Y-%m')))
						*100),2) as MoM_order_count
from coffee_shop_sales
-- where transaction_date between '2023-04-01' and '2023-05-31' -- for specific month
group by date_format(transaction_date,'%Y-%m')
;
/**************************************************************************************************/
-- 2.3 Calculate the difference in the number of orders between the selected month and the 
-- previous month.

select date_format(transaction_date,'%Y-%m') as transaction_month,
count(*)as total_orders,
lag(count(*)) over(order by date_format(transaction_date,'%Y-%m'))as previous_month_total_orders,
(count(*) - 
	lag(count(*)) over(order by date_format(transaction_date,'%Y-%m'))) as MoM_order_difference
from coffee_shop_sales
-- where transaction_date between '2023-04-01' and '2023-05-31' -- for specific month
group by date_format(transaction_date,'%Y-%m')
;
/**************************************************************************************************/
-- 3 Total Quantity Sold Analysis:
-- 3.1 Calculate the total quantity sold for each respective month.

select date_format(transaction_date,'%Y-%m') as transaction_month,
sum(transaction_qty) as total_quantity
from coffee_shop_sales
-- where transaction_date between '2023-05-01' and '2023-05-31' -- for specific month
group by date_format(transaction_date,'%Y-%m')
;
/**************************************************************************************************/
-- 3.2 Determine the month-on-month increase or decrease in the total quantity sold.

select date_format(transaction_date,'%Y-%m') as transaction_month,
sum(transaction_qty) as total_quantity,
lag(sum(transaction_qty)) 
     over(order by date_format(transaction_date,'%Y-%m')) as previous_month_qty,
round(((sum(transaction_qty)- lag(sum(transaction_qty)) over(order by date_format(transaction_date,'%Y-%m')))/
lag(sum(transaction_qty)) over(order by date_format(transaction_date,'%Y-%m')))*100,2) as MoM_QTY
from coffee_shop_sales
-- where transaction_date between '2023-04-01' and '2023-05-31' -- for specific month
group by date_format(transaction_date,'%Y-%m')
;
/**************************************************************************************************/
-- 3.3 Calculate the difference in the total quantity sold between the selected month and the 
-- previous month.

select date_format(transaction_date,'%Y-%m') as transaction_month,
sum(transaction_qty) as total_quantity,
lag(sum(transaction_qty)) 
     over(order by date_format(transaction_date,'%Y-%m')) as previous_month_qty,
(sum(transaction_qty)- lag(sum(transaction_qty)) over(order by date_format(transaction_date,'%Y-%m'))) 
as MoM_QTY_difference
from coffee_shop_sales
-- where transaction_date between '2023-04-01' and '2023-05-31' -- for specific month
group by date_format(transaction_date,'%Y-%m')
;

/*************************************************************************************************************/
                                         -- Chart Requirements
-- SALES BY WEEKDAY / WEEKEND to analyze customer visit:

select 
concat(round(sum(case when dayofweek(transaction_date) in (7,1) then (transaction_qty*unit_price) end)/1000,1)
, ' k')
as weekend_sales,
concat(round(
sum(case when dayofweek(transaction_date) not in (7,1) then (transaction_qty*unit_price) end)/1000,2),
' k')
as week_days_sales
from coffee_shop_sales
-- where transaction_date between '2023-04-01' and '2023-05-31' -- for specific month
;

/*************************************************************************************************************/

                            -- Sales Analysis by store Location

-- sales by store locations

select 
      store_location,
      concat(round(sum(transaction_qty*unit_price)/1000,2),' k') as total_sales
from coffee_shop_sales
-- where month(transaction_date) = 5 
group by store_location; 

/************************************************************************************************************/
                                 -- Daily sales with Average sales line                                 

with daily_sales as(
    select transaction_date,
		round(sum(transaction_qty*unit_price),2) as total_daily_sales
	from coffee_shop_sales
	where month(transaction_date) = 5
    group by transaction_date),
avg_sales as(
	select 
		avg(total_daily_sales) as avg_sales 
	from daily_sales)
select 
	d.transaction_date, 
    case when d.total_daily_sales> a.avg_sales then 'Above avgerage'
    else 'Below average'
    end as daily_Sales_sattus
from daily_sales d
cross join avg_sales a 
;

/*************************************************************************************************************/
                           -- Sales by product Category

select 
	product_category,
    round(sum(transaction_qty*unit_price),2) as total_sales
from coffee_shop_sales
where transaction_date between '2023-05-01' and '2023-05-31'
group by product_category
order by total_sales desc;

/*************************************************************************************************************/
                                     -- Top 10 products

select 
	product_type,
    round(sum(transaction_qty*unit_price),2) as total_sales
from coffee_shop_sales
where transaction_date between '2023-05-01' and '2023-05-31'
group by product_type
order by total_sales desc
limit 10
;
/*************************************************************************************************************/
                                      -- SALES BY DAY | HOUR

select 
	dayname(transaction_date) as transaction_day,
    round(sum(transaction_qty*unit_price),2) as total_sales
from coffee_shop_sales
where transaction_date between '2023-05-01' and '2023-05-31'
group by dayname(transaction_date)
;

select 
	hour(transaction_time) as transaction_hour,
    round(sum(transaction_qty*unit_price),2) as total_sales
from coffee_shop_sales
-- where transaction_date between '2023-05-01' and '2023-05-31'
group by hour(transaction_time)
order by transaction_hour
;



