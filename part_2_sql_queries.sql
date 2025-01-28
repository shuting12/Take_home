# here are the sql queries, for all results, please check the python file

# Question 1: What are the top 5 brands by receipts scanned among users 21 and over?

    with base as(
    select a.*
        , b.BRAND
        , c.age
    from transaction_clean a
    left join product_clean b ON a.BARCODE = b.BARCODE
    left join user c on a.USER_ID = c.ID
    where c.age >=21 and a.BARCODE is not null and b.BRAND <> 'None'
    )
    select BRAND
        , sum(FINAL_QUANTITY) as quantity
        , sum(FINAL_SALE) as sales 
        , count(distinct RECEIPT_ID) as num_receipts
    from base
    group by 1
    order by 4 desc , 3 desc
    ;



# Question 2: What are the top 5 brands by sales among users that have had their account for at least six months?
# in pandasql, I have to use JULIANDAY function to get the date type converted , if in normal database, we can use datediff or direct substract should work.


    with base as (
    select a.*
        , b.BRAND
        , c.CREATED_DATE
        , (JULIANDAY(DATE(a.PURCHASE_DATE)) - JULIANDAY(DATE(c.CREATED_DATE))) as user_days
    from transaction_clean a
    left join product_clean b ON a.BARCODE = b.BARCODE
    left join user c on a.USER_ID = c.ID
    where a.BARCODE is not null and b.BRAND <> 'None'
    )
    select BRAND
        , sum(FINAL_QUANTITY) as quantity
        , sum(FINAL_SALE) as sales 
        , count(distinct USER_ID) as num_users
    from base
    where user_days >= 180 
    group by 1
    order by 3 desc 
    ;



# open ended question 1:
# Question 3: Who are Fetch’s power users?
# here I have some analysis in python, used quantile analysis to get the filter conditions

    with base as(
    select a.*
        , b.BRAND
        , b.CATEGORY_1
        , c.age
    from transaction_clean a
    left join product_clean b ON a.BARCODE = b.BARCODE
    left join user c on a.USER_ID = c.ID
    )
    select  USER_ID
    , sum(FINAL_QUANTITY) as quantity
    , sum(FINAL_SALE) as sales
    , count(distinct RECEIPT_ID) as num_receipts
    , count(distinct STORE_NAME) as num_stores
    , count(distinct CATEGORY_1) as num_category
    , count(distinct BRAND) as num_brand
    , avg(days_waited_scan_receipt) as days_waited_scan_receipt
    from base 
    group by 1
    having sum(FINAL_QUANTITY) >4
    and sum(FINAL_SALE)>15.7
    and count(distinct RECEIPT_ID) > 1
    and count(distinct STORE_NAME) >2
    and count(distinct CATEGORY_1) >1
    and count(distinct BRAND) >1
    and avg(days_waited_scan_receipt) < 2
    order by 3 desc
    ;



# Question 4: At what percent has Fetch grown year over year?
# since our transation data only have 88 days from 2024, we can use USER table to analyze this question
# user creating date end in Sep 2024, so we analyze all years from Jan - Aug 

with base as (
    select *,
           date(CREATED_DATE) as member_date
           , CAST(strftime('%Y', CREATED_DATE) as INTEGER) as member_year
           , CAST(strftime('%m', CREATED_DATE) as INTEGER) as member_month
    from user
    ),
    user_num AS (
        select member_year
               , count(distinct ID) as users
        from base
        where member_month <9
        group by member_year
    )
    select a.member_year
           , b.member_year as previous_year
           , a.users 
           , b.users as last_year_users
           , (a.users - b.users) user_diff
           , case when b.users = 0 then null
               when b.users is null then null 
               else ((a.users - b.users ) * 100.0) / b.users 
               end as yoy_user_growth
     from user_num a
     left join user_num b 
     where  a.member_year = b.member_year + 1

