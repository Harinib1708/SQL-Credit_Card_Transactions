select * from credit_card_transactions
--DATA SET DETAILS ---
select min(transaction_date),max(transaction_date) from credit_card_transactions 
/*
min(transaction_date) = 10 April 2014 
max(transaction_date) = 9 September 2014
*/
select distinct card_type from credit_card_transactions
/*
card_type
Silver
Signature
Gold
Platinum
*/
select distinct exp_type  from credit_card_transactions

/*Entertainment
Food
Bills
Fuel
Travel
Grocery
*/
select distinct city from credit_card_transactions


--1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
with cte as (
select city,sum(amount) as total_spend
from credit_card_transactions
group by city ) 
,cte1 as (select sum(cast(amount as bigint)) as total_amount from credit_card_transactions)

--total amount,rank 5

select top 5 cte.* ,round(total_spend*1.0/total_amount * 100,2) as percentage_contribution 
from cte 
inner join cte1
on 1=1 
order by total_spend desc

--2- write a query to print highest spend month and amount spent in that month for each card type

with cte as (
select card_type,DATEPART(year,transaction_date) as yr , DATEPART(month,transaction_date) as mn ,sum(amount) as total_amount
from credit_card_transactions
group by DATEPART(year,transaction_date)  , DATEPART(month,transaction_date)  , card_type
)
, b as (
select *,
ROW_NUMBER() over (partition by  card_type order by total_amount desc ) rn
from  cte
)
select *
from b
where rn = 1

--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

with cte as (
select * ,
sum(amount) over(partition by card_type order by transaction_date,transaction_id) as running_sum
from credit_card_transactions
)
, b as (
select * ,
rank() over(partition by card_type order by running_sum) as rn 
from cte
where running_sum >= 1000000 ) 

select *
from b
where rn=1


--4- write a query to find city which had lowest percentage spend for gold card type
--city,card,sum(amount),sum(gold amount )
with cte as (
select city,card_type,sum(amount) as total_amount
,sum(case when card_type='Gold' then amount end ) as gold_amount
from credit_card_transactions
group by city,card_type )

select top 1 city, sum(gold_amount)*1.0 /sum( total_amount ) as gold_ratio
from cte
group by city
having sum(gold_amount) is not null
order by gold_ratio asc;

--5--write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

with cte as (
select city,exp_type, sum(amount) as expense
from credit_card_transactions
group by city,exp_type 
)
, b as (
select *,
rank() over(partition by city order by expense desc ) rn_desc ,
rank() over(partition by city order by expense asc ) rn_asc

from cte
)

select city,
min(case when rn_asc =1 then exp_type end ) as lowest_expense_type ,
max(case when rn_desc=1 then exp_type end ) as  highest_expense_type
from b
group by city

--6- write a query to find percentage contribution of spends by females for each expense type
--group by exptype,gender,amount


select exp_type,
round(sum(case when gender ='F' then amount else 0 end) *1.0 / sum(amount) *100,2) as female_perct
from credit_card_transactions
group by exp_type
order by female_perct desc

--7- which card and expense type combination saw highest month over month growth in Jan-2014

with cte as (
select card_type,exp_type,sum(amount) as total_amount,DATEPART(month,transaction_date) as mn , DATEPART(year,transaction_date) as yr
from credit_card_transactions
group by card_type,exp_type,DATEPART(month,transaction_date),DATEPART(year,transaction_date)
)
, b as (
select *,
lag(total_amount,1) over(partition by card_type,exp_type order by yr,mn asc ) as prev_mn
from cte 
)

select  top 1 *,( total_amount - prev_mn)as  mom_growth
from b
where prev_mn is not null and yr = 2014 and mn =1
order by mom_growth desc


--9- during weekends which city has highest total spend to total no of transcations ratio 

/*
select city,DATEname(WEEKDAY,transaction_date),DATEpart(WEEKDAY,transaction_date) 
from credit_card_transactions
where DATEpart(WEEKDAY,transaction_date) in (1,7)
*/

select top 1 city,sum(amount)/count(*) as ratio
from credit_card_transactions
where DATEname(WEEKDAY,transaction_date) in ('saturday','sunday') --DATEPART(WEEKDAY,transaction_date) in (1,7)
group by city
order by ratio desc

--DATEname(WEEKDAY,transaction_date) in ('saturday','sunday')

--10--10- which city took least number of days to reach its 500th transaction after the first transaction in that city

WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY city ORDER BY transaction_date, transaction_id) AS rn
    FROM credit_card_transactions
)
SELECT top 1  city,
       DATEDIFF(day, MIN(transaction_date), MAX(transaction_date)) AS datediff1
FROM cte
WHERE rn = 1 OR rn = 500
GROUP BY city
HAVING COUNT(1) = 2 and DATEDIFF(day, MIN(transaction_date), MAX(transaction_date)) > 0
ORDER BY datediff1;
