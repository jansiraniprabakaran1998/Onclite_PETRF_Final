/*
    Mart model: dim_question
    Grain: one row per question_id
*/

with question as (

    select * from {{ ref('stg_question') }}

),

product as (

    select product_key, product_id from {{ ref('dim_product') }}

),

final as (

    select
        {{ petrf_surrogate_key(['q.question_id']) }}  as question_key,
        q.question_id,
        q.question_text,
        q.question_type,
        q.question_category,
        p.product_key                                     as product_key_ref
    from question q
    left join product p on q.product_id = p.product_id

)

select * from final
