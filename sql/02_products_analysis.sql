-- Top 10 Product Categories by Delivered Item Sales 

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

-- for making sure how many categories are there:

SELECT

	COUNT(DISTINCT (COALESCE(product_category_name, 'Unknown'))) AS category
	
FROM products;


-- Top 10 Products ID by Delivered Item Sales 

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

-- Product Category Contribution to Delivered Item Sales 

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


-- Top 10 Categories by Products Sold

WITH category_products AS (

    SELECT
        COALESCE(
            p.product_category_name,
            'Unknown'
        ) AS category_name,

        COUNT(DISTINCT oi.product_id) AS products_sold

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
    products_sold,

    RANK() OVER (
        ORDER BY products_sold DESC
    ) AS products_rank

FROM category_products

ORDER BY
    products_sold DESC,
    category_name

LIMIT 10;


-- Top 10 Categories by Delivered Orders

WITH category_orders AS (

    SELECT
        COALESCE(
            p.product_category_name,
            'Unknown'
        ) AS category_name,

        COUNT(DISTINCT o.order_id) AS delivered_orders

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
    delivered_orders,

    RANK() OVER (
        ORDER BY delivered_orders DESC
    ) AS order_rank

FROM category_orders

ORDER BY
    delivered_orders DESC,
    category_name

LIMIT 10;
