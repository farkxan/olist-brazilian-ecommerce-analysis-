-- Case 1: Monthly Item Sales from Delivered Orders

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

-- Case 2: Top 10 Product Categories by Delivered Item Sales

WITH category_sales AS (

    SELECT
        COALESCE(
            p.product_category_name,
            'Unknown'
        ) AS category_name,

        ROUND(
            SUM(oi.price)::numeric,
            2
        ) AS delivered_item_sales

    FROM products p

    JOIN order_items oi
        ON p.product_id = oi.product_id

    JOIN orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        COALESCE(
            p.product_category_name,
            'Unknown'
        )
)

SELECT
    category_name,
    delivered_item_sales,

    RANK() OVER (
        ORDER BY delivered_item_sales DESC
    ) AS sales_rank

FROM category_sales

ORDER BY
    delivered_item_sales DESC,
    category_name

LIMIT 10;

-- Case 3: Top 10 Products by Delivered Item Sales

WITH product_sales AS (

    SELECT
        p.product_id,

        COALESCE(
            p.product_category_name,
            'Unknown'
        ) AS category,

        ROUND(
            SUM(oi.price)::numeric,
            2
        ) AS delivered_item_sales

    FROM products p

    JOIN order_items oi
        ON p.product_id = oi.product_id

    JOIN orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        p.product_id,
        p.product_category_name
)

SELECT
    product_id,
    category,
    delivered_item_sales,

    RANK() OVER (
        ORDER BY delivered_item_sales DESC
    ) AS sales_rank

FROM product_sales

ORDER BY
    delivered_item_sales DESC,
    product_id

LIMIT 10;

-- Case 4: Top 10 Sellers by Delivered Item Sales

WITH seller_sales AS (

    SELECT
        s.seller_id,

        ROUND(
            SUM(oi.price)::numeric,
            2
        ) AS delivered_item_sales

    FROM sellers s

    JOIN order_items oi
        ON s.seller_id = oi.seller_id

    JOIN orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY s.seller_id
)

SELECT
    seller_id,
    delivered_item_sales,

    RANK() OVER (
        ORDER BY delivered_item_sales DESC
    ) AS sales_rank

FROM seller_sales

ORDER BY
    delivered_item_sales DESC,
    seller_id

LIMIT 10;

-- Case 5: Top 10 Customers by Delivered Item Spending

WITH customer_spending AS (

    SELECT
        c.customer_unique_id,

        ROUND(
            SUM(oi.price)::numeric,
            2
        ) AS delivered_item_spending

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
)

SELECT
    customer_unique_id,
    delivered_item_spending,

    RANK() OVER (
        ORDER BY delivered_item_spending DESC
    ) AS spending_rank

FROM customer_spending

ORDER BY
    delivered_item_spending DESC,
    customer_unique_id

LIMIT 10;

-- Case 6: Product Category Contribution to Delivered Item Sales

WITH category_sales AS (

    SELECT
        COALESCE(
            p.product_category_name,
            'Unknown'
        ) AS category_name,

        SUM(oi.price)::numeric AS item_sales

    FROM products p

    JOIN order_items oi
        ON p.product_id = oi.product_id

    JOIN orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        COALESCE(
            p.product_category_name,
            'Unknown'
        )
)

SELECT
    category_name,

    ROUND(item_sales, 2) AS delivered_item_sales,

    ROUND(
        SUM(item_sales) OVER(),
        2
    ) AS total_delivered_item_sales,

    ROUND(
        100.0 * item_sales
        / NULLIF(SUM(item_sales) OVER(), 0),
        2
    ) AS sales_contribution_pct

FROM category_sales

ORDER BY
    item_sales DESC,
    category_name;

-- Case 7: Seller Contribution to Delivered Item Sales

WITH seller_sales AS (

    SELECT
        s.seller_id,
        SUM(oi.price)::numeric AS item_sales

    FROM sellers s

    JOIN order_items oi
        ON s.seller_id = oi.seller_id

    JOIN orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY s.seller_id
)

SELECT
    seller_id,

    ROUND(item_sales, 2) AS delivered_item_sales,

    ROUND(
        SUM(item_sales) OVER(),
        2
    ) AS total_delivered_item_sales,

    ROUND(
        100.0 * item_sales
        / NULLIF(SUM(item_sales) OVER(), 0),
        2
    ) AS sales_contribution_pct

FROM seller_sales

ORDER BY
    item_sales DESC,
    seller_id;

-- Case 8: Month-over-Month Delivered Item Sales Growth

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

calendar AS (

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

monthly_series AS (

    SELECT
        c.month,

        COALESCE(
            ms.delivered_item_sales,
            0::numeric
        ) AS delivered_item_sales

    FROM calendar c

    LEFT JOIN monthly_sales ms
        ON c.month = ms.month
),

revenue_growth AS (

    SELECT
        month,
        delivered_item_sales,

        LAG(delivered_item_sales) OVER (
            ORDER BY month
        ) AS previous_month_sales

    FROM monthly_series
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
        100.0 * (
            delivered_item_sales - previous_month_sales
        ) / NULLIF(previous_month_sales, 0),
        2
    ) AS mom_growth_pct,

    CASE
        WHEN previous_month_sales IS NULL
            THEN 'No previous month'

        WHEN delivered_item_sales > previous_month_sales
            THEN 'Up'

        WHEN delivered_item_sales < previous_month_sales
            THEN 'Down'

        ELSE 'Flat'
    END AS sales_movement

FROM revenue_growth

ORDER BY month;

-- Case 9: Sellers Above Average Delivered Item Sales

WITH delivered_sales AS (

    SELECT
        oi.seller_id,
        SUM(oi.price)::numeric AS delivered_item_sales

    FROM order_items oi

    JOIN orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY oi.seller_id
),

seller_sales AS (

    SELECT
        s.seller_id,

        COALESCE(
            ds.delivered_item_sales,
            0::numeric
        ) AS delivered_item_sales

    FROM sellers s

    LEFT JOIN delivered_sales ds
        ON s.seller_id = ds.seller_id
),

seller_benchmark AS (

    SELECT
        seller_id,
        delivered_item_sales,

        AVG(delivered_item_sales) OVER()
            AS avg_seller_sales

    FROM seller_sales
)

SELECT
    seller_id,

    ROUND(
        delivered_item_sales,
        2
    ) AS delivered_item_sales,

    ROUND(
        avg_seller_sales,
        2
    ) AS avg_seller_sales,

    CASE
        WHEN delivered_item_sales > avg_seller_sales
            THEN 'Above Average'

        WHEN delivered_item_sales < avg_seller_sales
            THEN 'Below Average'

        ELSE 'At Average'
    END AS sales_status

FROM seller_benchmark

ORDER BY
    delivered_item_sales DESC,
    seller_id;

-- Case 10: Top Seller in Each State by Delivered Item Sales

WITH seller_sales AS (

    SELECT
        s.seller_id,
        s.seller_city AS city,
        s.seller_state AS state,

        SUM(oi.price)::numeric AS delivered_item_sales

    FROM sellers s

    JOIN order_items oi
        ON s.seller_id = oi.seller_id

    JOIN orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        s.seller_id,
        s.seller_city,
        s.seller_state
),

seller_rank_by_state AS (

    SELECT
        *,

        RANK() OVER (
            PARTITION BY state
            ORDER BY delivered_item_sales DESC
        ) AS seller_rank

    FROM seller_sales
)

SELECT
    seller_id,
    city,
    state,

    ROUND(
        delivered_item_sales,
        2
    ) AS delivered_item_sales,

    seller_rank

FROM seller_rank_by_state

WHERE seller_rank = 1

ORDER BY
    state,
    seller_id;

-- Case 11: Cumulative Delivered Item Sales by Month

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


-- Case 12: Customer Segmentation Using RFM

WITH params AS (
    SELECT DATE '2018-09-01' AS snapshot_date
),

-- Satu baris per order agar frequency tidak menghitung item
order_revenue AS (
    SELECT
        order_id,
        SUM(price)::numeric AS order_revenue
    FROM order_items
    GROUP BY order_id
),

customer_rfm AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp)::date AS last_order,
        COUNT(*) AS frequency,
        SUM(orr.order_revenue) AS monetary

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    JOIN order_revenue orr
        ON o.order_id = orr.order_id

    CROSS JOIN params p

    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp < p.snapshot_date
        AND o.order_delivered_customer_date < p.snapshot_date

    GROUP BY c.customer_unique_id
),

rfm_feature AS (
    SELECT
        cr.*,
        p.snapshot_date,
        p.snapshot_date - cr.last_order AS recency_days

    FROM customer_rfm cr
    CROSS JOIN params p
),

rfm_score AS (
    SELECT
        *,

        CASE
            WHEN recency_days <= 30 THEN 5
            WHEN recency_days <= 90 THEN 4
            WHEN recency_days <= 180 THEN 3
            WHEN recency_days <= 365 THEN 2
            ELSE 1
        END AS r_score,

        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            WHEN frequency = 3 THEN 3
            WHEN frequency = 4 THEN 4
            ELSE 5
        END AS f_score,

        CEIL(
            CUME_DIST() OVER (
                ORDER BY monetary ASC
            ) * 5
        )::integer AS m_score

    FROM rfm_feature
),

rfm_total_score AS (
    SELECT
        *,
        r_score + f_score + m_score AS total_score_rfm
    FROM rfm_score
),

rfm_segment AS (
    SELECT
        *,

        CASE
            WHEN r_score >= 4
                AND f_score >= 4
                AND m_score >= 4
            THEN 'Champions'

            WHEN r_score <= 2
                AND f_score >= 4
                AND m_score >= 4
            THEN 'At Risk'

            WHEN r_score >= 4
                AND f_score <= 2
            THEN 'New Customer'

            WHEN r_score <= 2
                AND f_score <= 2
                AND m_score <= 2
            THEN 'Lost Customer'

            ELSE 'Regular'
        END AS customer_segment

    FROM rfm_total_score
)

SELECT
    customer_unique_id,
    snapshot_date,
    last_order,
    recency_days,
    frequency,
    ROUND(monetary, 2) AS monetary,
    r_score,
    f_score,
    m_score,
    total_score_rfm,
    customer_segment

FROM rfm_segment

ORDER BY
    total_score_rfm DESC,
    monetary DESC,
    customer_unique_id;

-- Case 13: Customer Count by RFM Segment

SELECT
    customer_segment,
    COUNT(*) AS total_customers

FROM rfm_segment

GROUP BY customer_segment

ORDER BY
    total_customers DESC,
    customer_segment;

-- Case 14 :  berapa total revenue masing-masing segment?

segment_summary AS (

    SELECT
        customer_segment,
        COUNT(*) AS total_customers,
        SUM(monetary) AS segment_monetary

    FROM rfm_segment

    GROUP BY customer_segment
)

SELECT
    customer_segment,
    total_customers,

    ROUND(
        segment_monetary,
        2
    ) AS segment_monetary,

    ROUND(
        100.0 * segment_monetary
        / NULLIF(SUM(segment_monetary) OVER(), 0),
        2
    ) AS monetary_contribution_pct

FROM segment_summary

ORDER BY
    segment_monetary DESC,
    customer_segment;


-- Top 10 Customers by Delivered Item Spending
-- Minimum 3 Delivered Orders

WITH order_spending AS (
    SELECT
        order_id,
        SUM(price::numeric) AS order_spending
    FROM order_items
    GROUP BY order_id
),

customer_behavior AS (
    SELECT
        c.customer_unique_id,
        COUNT(*) AS frequency,
        SUM(os.order_spending) AS delivered_item_spending

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    JOIN order_spending os
        ON o.order_id = os.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id

    HAVING COUNT(*) >= 3
),

ranked_customer AS (
    SELECT
        customer_unique_id,
        frequency,
        delivered_item_spending,

        ROW_NUMBER() OVER (
            ORDER BY
                delivered_item_spending DESC,
                customer_unique_id
        ) AS spending_rank

    FROM customer_behavior
)

SELECT
    customer_unique_id,
    frequency,
    ROUND(delivered_item_spending, 2)
        AS delivered_item_spending,
    spending_rank

FROM ranked_customer

WHERE spending_rank <= 10

ORDER BY spending_rank;


-- Case 17: Top Product Category by RFM Segment

WITH params AS (
    SELECT DATE '2018-09-01' AS snapshot_date
),

order_revenue AS (
    SELECT
        order_id,
        SUM(price::numeric) AS order_revenue
    FROM order_items
    GROUP BY order_id
),

customer_rfm AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp)::date AS last_order,
        COUNT(*) AS frequency,
        SUM(orr.order_revenue) AS monetary

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    JOIN order_revenue orr
        ON o.order_id = orr.order_id

    CROSS JOIN params p

    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp < p.snapshot_date
        AND o.order_delivered_customer_date < p.snapshot_date

    GROUP BY c.customer_unique_id
),

rfm_feature AS (
    SELECT
        cr.*,
        p.snapshot_date,
        p.snapshot_date - cr.last_order AS recency_days

    FROM customer_rfm cr
    CROSS JOIN params p
),

rfm_score AS (
    SELECT
        *,

        CASE
            WHEN recency_days <= 30 THEN 5
            WHEN recency_days <= 90 THEN 4
            WHEN recency_days <= 180 THEN 3
            WHEN recency_days <= 365 THEN 2
            ELSE 1
        END AS r_score,

        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            WHEN frequency = 3 THEN 3
            WHEN frequency = 4 THEN 4
            ELSE 5
        END AS f_score,

        CEIL(
            CUME_DIST() OVER (
                ORDER BY monetary ASC
            ) * 5
        )::integer AS m_score

    FROM rfm_feature
),

rfm_total_score AS (
    SELECT
        *,
        r_score + f_score + m_score AS total_score_rfm
    FROM rfm_score
),

rfm_segment AS (
    SELECT
        *,

        CASE
            WHEN r_score >= 4
                AND f_score >= 4
                AND m_score >= 4
                THEN 'Champions'

            WHEN r_score <= 2
                AND f_score >= 4
                AND m_score >= 4
                THEN 'At Risk'

            WHEN r_score >= 4
                AND f_score <= 2
                THEN 'New Customer'

            WHEN r_score <= 2
                AND f_score <= 2
                AND m_score <= 2
                THEN 'Lost Customer'

            ELSE 'Regular'
        END AS customer_segment

    FROM rfm_total_score
),

segment_category_sales AS (
    SELECT
        rs.customer_segment,

        COALESCE(
            p.product_category_name,
            'Unknown'
        ) AS category,

        SUM(oi.price::numeric) AS item_sales

    FROM rfm_segment rs

    JOIN customers c
        ON rs.customer_unique_id = c.customer_unique_id

    JOIN orders o
        ON c.customer_id = o.customer_id

    JOIN order_items oi
        ON o.order_id = oi.order_id

    JOIN products p
        ON oi.product_id = p.product_id

    CROSS JOIN params pa

    WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp < pa.snapshot_date
        AND o.order_delivered_customer_date < pa.snapshot_date

    GROUP BY
        rs.customer_segment,
        COALESCE(
            p.product_category_name,
            'Unknown'
        )
),

ranked_category AS (
    SELECT
        *,

        RANK() OVER (
            PARTITION BY customer_segment
            ORDER BY item_sales DESC
        ) AS category_rank,

        SUM(item_sales) OVER (
            PARTITION BY customer_segment
        ) AS segment_total_sales

    FROM segment_category_sales
)

SELECT
    customer_segment,
    category,

    ROUND(item_sales, 2) AS delivered_item_sales,

    ROUND(segment_total_sales, 2)
        AS segment_total_sales,

    ROUND(
        100.0 * item_sales
        / NULLIF(segment_total_sales, 0),
        2
    ) AS category_contribution_pct,

    category_rank

FROM ranked_category

WHERE category_rank = 1

ORDER BY
    customer_segment,
    item_sales DESC;


-- Case 18: Sellers Above Average Delivered Item Sales

WITH delivered_sales AS (

    SELECT
        oi.seller_id,
        SUM(oi.price::numeric) AS seller_sales

    FROM order_items oi

    JOIN orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY oi.seller_id
),

sellers_revenue AS (

    SELECT
        s.seller_id,

        COALESCE(
            ds.seller_sales,
            0::numeric
        ) AS seller_revenue

    FROM sellers s

    LEFT JOIN delivered_sales ds
        ON s.seller_id = ds.seller_id
)

SELECT
    seller_id,

    ROUND(
        seller_revenue,
        2
    ) AS delivered_item_sales

FROM sellers_revenue

WHERE seller_revenue > (
    SELECT AVG(seller_revenue)
    FROM sellers_revenue
)

ORDER BY
    seller_revenue DESC,
    seller_id;



-- Case 19: One-Time vs. Repeat Customers

WITH customer_frequency AS (

    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id) AS delivered_order_count

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id
),

customer_type AS (

    SELECT
        customer_unique_id,
        delivered_order_count,

        CASE
            WHEN delivered_order_count = 1
                THEN 'One-Time Customer'
            ELSE 'Repeat Customer'
        END AS customer_segment

    FROM customer_frequency
),

customer_summary AS (

    SELECT
        customer_segment,
        COUNT(*) AS total_customers

    FROM customer_type

    GROUP BY customer_segment
)

SELECT
    customer_segment,
    total_customers,

    ROUND(
        100.0 * total_customers
        / NULLIF(SUM(total_customers) OVER(), 0),
        2
    ) AS customer_share_pct

FROM customer_summary

ORDER BY total_customers DESC;



-- Case 20: Monthly Delivered Item Sales
-- with a 3-Month Moving Average

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

calendar AS (

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

monthly_series AS (

    SELECT
        c.month,

        COALESCE(
            ms.delivered_item_sales,
            0::numeric
        ) AS delivered_item_sales

    FROM calendar c

    LEFT JOIN monthly_sales ms
        ON c.month = ms.month
),

revenue_trend AS (

    SELECT
        month,
        delivered_item_sales,

        CASE
            WHEN COUNT(*) OVER (
                ORDER BY month
                ROWS BETWEEN 2 PRECEDING
                         AND CURRENT ROW
            ) = 3

            THEN AVG(delivered_item_sales) OVER (
                ORDER BY month
                ROWS BETWEEN 2 PRECEDING
                         AND CURRENT ROW
            )

            ELSE NULL
        END AS moving_avg_3m

    FROM monthly_series
)

SELECT
    month,

    ROUND(
        delivered_item_sales,
        2
    ) AS delivered_item_sales,

    ROUND(
        moving_avg_3m,
        2
    ) AS moving_avg_3m

FROM revenue_trend

ORDER BY month;


-- Case: Actual Sales vs. 3-Month Moving Average

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

calendar AS (

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

monthly_series AS (

    SELECT
        c.month,

        COALESCE(
            ms.delivered_item_sales,
            0::numeric
        ) AS delivered_item_sales

    FROM calendar c

    LEFT JOIN monthly_sales ms
        ON c.month = ms.month
),

revenue_trend AS (

    SELECT
        month,
        delivered_item_sales,

        CASE
            WHEN COUNT(*) OVER (
                ORDER BY month
                ROWS BETWEEN 2 PRECEDING
                         AND CURRENT ROW
            ) = 3

            THEN AVG(delivered_item_sales) OVER (
                ORDER BY month
                ROWS BETWEEN 2 PRECEDING
                         AND CURRENT ROW
            )

            ELSE NULL
        END AS moving_avg_3m

    FROM monthly_series
)

SELECT
    month,

    ROUND(
        delivered_item_sales,
        2
    ) AS delivered_item_sales,

    ROUND(
        moving_avg_3m,
        2
    ) AS moving_avg_3m,

    CASE
        WHEN moving_avg_3m IS NULL
            THEN 'Insufficient data'

        WHEN delivered_item_sales > moving_avg_3m
            THEN 'Above average'

        WHEN delivered_item_sales < moving_avg_3m
            THEN 'Below average'

        ELSE 'Equal to average'
    END AS sales_status

FROM revenue_trend

ORDER BY month;


-- Month-over-Month Delivered Item Sales Growth (versi better)

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


-- Case 24: Next-Month Customer Retention

WITH customer_month AS (

    -- One row per customer per month
    SELECT DISTINCT
        c.customer_unique_id,

        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::date AS month

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'
),

data_bounds AS (

    -- Last observed purchase month in the dataset
    SELECT
        DATE_TRUNC(
            'month',
            MAX(order_purchase_timestamp)
        )::date AS max_observed_month

    FROM orders
),

monthly_retention AS (

    SELECT
        cm.month,

        COUNT(*) AS active_customers,

        COUNT(*) FILTER (
            WHERE EXISTS (
                SELECT 1

                FROM customer_month next_month

                WHERE next_month.customer_unique_id
                    = cm.customer_unique_id

                  AND next_month.month
                    = (cm.month + INTERVAL '1 month')::date
            )
        ) AS retained_customers

    FROM customer_month cm

    GROUP BY cm.month
),

retention_output AS (

    SELECT
        mr.month,
        mr.active_customers,

        CASE
            WHEN mr.month >= db.max_observed_month
                THEN NULL
            ELSE mr.retained_customers
        END AS retained_customers

    FROM monthly_retention mr

    CROSS JOIN data_bounds db
)

SELECT
    month,
    active_customers,
    retained_customers,

    ROUND(
        (
            retained_customers * 100.0
            / NULLIF(active_customers, 0)
        )::numeric,
        2
    ) AS retention_rate_pct

FROM retention_output

ORDER BY month;



-- Case 25: Next-Month Cohort Repeat Purchase Rate

WITH customers_delivered_month AS (

    SELECT DISTINCT
        c.customer_unique_id,

        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::date AS month

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'
),

customers_cohort AS (

    SELECT
        customer_unique_id,
        MIN(month) AS cohort_month

    FROM customers_delivered_month

    GROUP BY customer_unique_id
),

observation_bounds AS (

    -- Treat the latest calendar month as incomplete
    SELECT
        (
            DATE_TRUNC(
                'month',
                MAX(order_purchase_timestamp)
            ) - INTERVAL '1 month'
        )::date AS last_complete_month

    FROM orders
),

repeat_customers AS (

    SELECT
        cc.customer_unique_id,
        cc.cohort_month,

        CASE
            WHEN (
                cc.cohort_month + INTERVAL '1 month'
            )::date <= ob.last_complete_month

            THEN
                CASE
                    WHEN EXISTS (
                        SELECT 1

                        FROM customers_delivered_month cdm

                        WHERE cdm.customer_unique_id
                            = cc.customer_unique_id

                          AND cdm.month = (
                              cc.cohort_month
                              + INTERVAL '1 month'
                          )::date
                    )
                    THEN 1
                    ELSE 0
                END

            ELSE NULL
        END AS repeat_flag

    FROM customers_cohort cc

    CROSS JOIN observation_bounds ob
),

cohort_summary AS (

    SELECT
        cohort_month,

        COUNT(*) AS acquired_customers,

        SUM(repeat_flag) AS repeat_customers

    FROM repeat_customers

    GROUP BY cohort_month
)

SELECT
    cohort_month,
    acquired_customers,
    repeat_customers,

    ROUND(
        (
            repeat_customers * 100.0
            / NULLIF(acquired_customers, 0)
        )::numeric,
        2
    ) AS repeat_rate_pct

FROM cohort_summary

ORDER BY cohort_month;



-- Case 26: Top 10 Sellers by Delivered Item Sales

WITH sellers_performance AS (

    SELECT
        s.seller_id,

        SUM(
            oi.price::numeric
        ) AS delivered_item_sales,

        COUNT(
            DISTINCT o.order_id
        ) AS total_orders

    FROM sellers s

    JOIN order_items oi
        ON s.seller_id = oi.seller_id

    JOIN orders o
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY s.seller_id
),

ranked_sellers AS (

    SELECT
        seller_id,
        delivered_item_sales,
        total_orders,

        delivered_item_sales
            / NULLIF(total_orders, 0)
            AS avg_sales_per_order,

        ROW_NUMBER() OVER (
            ORDER BY
                delivered_item_sales DESC,
                seller_id
        ) AS sales_rank

    FROM sellers_performance
)

SELECT
    seller_id,

    ROUND(
        delivered_item_sales,
        2
    ) AS delivered_item_sales,

    total_orders,

    ROUND(
        avg_sales_per_order,
        2
    ) AS avg_sales_per_order,

    sales_rank

FROM ranked_sellers

WHERE sales_rank <= 10

ORDER BY sales_rank;


-- Case: Product Category Sales Contribution

WITH category_revenue AS (

    SELECT
        COALESCE(
            p.product_category_name,
            'Unknown'
        ) AS category,

        SUM(
            oi.price::numeric
        ) AS delivered_item_sales

    FROM products p

    JOIN order_items oi
        ON p.product_id = oi.product_id

    JOIN orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        COALESCE(
            p.product_category_name,
            'Unknown'
        )
)

SELECT
    category,

    ROUND(
        delivered_item_sales,
        2
    ) AS delivered_item_sales,

    ROUND(
        (
            delivered_item_sales * 100.0
            / NULLIF(SUM(delivered_item_sales) OVER (), 0)
        )::numeric,
        2
    ) AS sales_contribution_pct,

    RANK() OVER (
        ORDER BY delivered_item_sales DESC
    ) AS category_rank

FROM category_revenue

ORDER BY
    delivered_item_sales DESC,
    category;



-- Case 28: Product Category Performance Among Repeat Customers

WITH repeat_customers AS (

    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS delivered_orders

    FROM customers c

    JOIN orders o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY c.customer_unique_id

    HAVING COUNT(DISTINCT o.order_id) >= 2
),

category_sales AS (

    SELECT
        COALESCE(
            p.product_category_name,
            'Unknown'
        ) AS category,

        COUNT(DISTINCT rc.customer_unique_id)
            AS repeat_customers_buying_category,

        COUNT(DISTINCT o.order_id)
            AS orders_containing_category,

        SUM(oi.price::numeric)
            AS delivered_item_sales

    FROM repeat_customers rc

    JOIN customers c
        ON rc.customer_unique_id = c.customer_unique_id

    JOIN orders o
        ON c.customer_id = o.customer_id

    JOIN order_items oi
        ON o.order_id = oi.order_id

    JOIN products p
        ON oi.product_id = p.product_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        COALESCE(
            p.product_category_name,
            'Unknown'
        )
)

SELECT
    category,

    repeat_customers_buying_category,

    orders_containing_category,

    ROUND(
        delivered_item_sales,
        2
    ) AS delivered_item_sales,

    ROUND(
        delivered_item_sales
        / NULLIF(orders_containing_category, 0),
        2
    ) AS avg_sales_per_category_order,

    ROUND(
        (
            delivered_item_sales * 100.0
            / NULLIF(SUM(delivered_item_sales) OVER(), 0)
        )::numeric,
        2
    ) AS sales_contribution_pct,

    RANK() OVER (
        ORDER BY delivered_item_sales DESC
    ) AS category_rank

FROM category_sales

ORDER BY
    delivered_item_sales DESC,
    category;


