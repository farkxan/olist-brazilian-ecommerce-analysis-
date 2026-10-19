-- Monthly Item Sales from Delivered Orders

SELECT
    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )::date AS month,

    ROUND(
        SUM(oi.price)::numeric,
        2
    ) AS delivered_item_sales

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'delivered'

GROUP BY 1
ORDER BY 1;

-- Month-over-Month Delivered Item Sales Growth
WITH monthly_sales AS (

    SELECT
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::date AS month,

        SUM(oi.price::numeric) AS delivered_item_sales

    FROM orders o

    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY 1
),

calendar_months AS (

    SELECT
        GENERATE_SERIES(
            DATE_TRUNC(
                'month',
                (SELECT MIN(order_purchase_timestamp)
                 FROM orders)
            )::date,

            DATE_TRUNC(
                'month',
                (SELECT MAX(order_purchase_timestamp)
                 FROM orders)
            )::date,

            INTERVAL '1 month'
        )::date AS month
),

complete_monthly_sales AS (

    SELECT
        cm.month,

        COALESCE(
            ms.delivered_item_sales,
            0::numeric
        ) AS delivered_item_sales

    FROM calendar_months cm

    LEFT JOIN monthly_sales ms
        ON cm.month = ms.month
),

previous_sales AS (

    SELECT
        month,
        delivered_item_sales,

        LAG(delivered_item_sales) OVER (
            ORDER BY month
        ) AS previous_month_sales

    FROM complete_monthly_sales
)

SELECT
    month,

    ROUND(
        delivered_item_sales,
        2
    ) AS delivered_item_sales,

    ROUND(
        previous_month_sales,
        2
    ) AS previous_month_sales,

    ROUND(
        (
            (delivered_item_sales - previous_month_sales)
            * 100.0
            / NULLIF(previous_month_sales, 0)
        )::numeric,
        2
    ) AS mom_growth_pct,

    CASE
        WHEN previous_month_sales IS NULL
            THEN 'No previous month'

        WHEN previous_month_sales = 0
            THEN 'Undefined: previous sales are zero'

        WHEN delivered_item_sales > previous_month_sales
            THEN 'Growth'

        WHEN delivered_item_sales < previous_month_sales
            THEN 'Decline'

        ELSE 'No change'
    END AS sales_movement

FROM previous_sales

ORDER BY month;


-- Cumulative Delivered Item Sales by Month

WITH monthly_sales AS (

    SELECT
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::date AS month,

        SUM(oi.price)::numeric AS delivered_item_sales

    FROM orders o

    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY 1
),

cumulative_sales AS (

    SELECT
        month,
        delivered_item_sales,

        SUM(delivered_item_sales) OVER (
            ORDER BY month
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND CURRENT ROW
        ) AS cumulative_sales

    FROM monthly_sales
)

SELECT
    month,

    ROUND(
        delivered_item_sales,
        2
    ) AS delivered_item_sales,

    ROUND(
        cumulative_sales,
        2
    ) AS cumulative_sales

FROM cumulative_sales

ORDER BY month;

