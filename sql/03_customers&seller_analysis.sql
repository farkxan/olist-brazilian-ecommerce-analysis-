-- Top 10 Sellers by Delivered Item Sales

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

-- Sellers Above Average Delivered Item Sales

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


-- Top Seller in Each State by Delivered Item Sales

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

--  Seller Contribution to Delivered Item Sales

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


-- Top 10 Sellers by Delivered Orders

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
                total_orders DESC,
                seller_id
        ) AS orders_rank

    FROM sellers_performance
)

SELECT
    seller_id,

    total_orders AS delivered_orders,

    ROUND(
        delivered_item_sales,
        2
    ) AS delivered_item_sales,

    ROUND(
        avg_sales_per_order,
        2
    ) AS avg_sales_per_order,

    orders_rank

FROM ranked_sellers

WHERE orders_rank <= 10

ORDER BY orders_rank;


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

