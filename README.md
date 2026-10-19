# Brazilian E-Commerce Data Analysis

## Project Overview

This project explores the Brazilian e-commerce business using the Olist dataset. The analysis focuses on sales performance, product categories, customer purchasing behavior, seller performance, and payment methods.

The goal is to turn raw e-commerce data into useful business insights through SQL analysis, Python data preparation, and an interactive Power BI dashboard.

## Tools & Technologies

- **SQL** — Data analysis, aggregations, and business queries
- **Python** — Data preparation and dataset integration
- **Power BI** — Interactive dashboard and data visualization

## Project Structure

```text
olist-brazilian-ecommerce-analysis/
├── notebooks/
│   └── olist.ipynb
├── sql/
│   ├── 01_revenue_analysis.sql
│   ├── 02_products_analysis.sql
│   ├── 03_customers&seller_analysis.sql
│   └── full_analysis.sql
├── powerbi/
│   └── Olist_Brazilian_Ecommerce_Dashboard.pbix
└── README.md
```

## Analysis Highlights

### 1. Revenue Analysis
- Monthly delivered item sales trends
- Sales distribution by Brazilian state
- Payment value by payment method

### 2. Product Analysis
- Top-performing product categories by sales
- Product categories by units sold and delivered orders
- Revenue contribution by product category
- Top 10 products by delivered item sales

### 3. Customer & Seller Analysis
- Top customers by delivered item sales
- Top sellers by sales and delivered orders
- Average item sales per order by seller
- Repeat customer metrics

## Power BI Dashboard

The Power BI report contains three pages:

1. **Executive Overview** — Key performance indicators, monthly sales trends, state-level sales, product categories, and payment methods.
2. **Product Performance** — Product-level sales and category performance.
3. **Customer & Seller Performance** — Customer sales, seller sales, order volume, and average sales per order.

To explore the dashboard, download the `.pbix` file from the `powerbi/` folder and open it using Microsoft Power BI Desktop.

## Repository Contents

- `notebooks/` contains the Python notebook.
- `sql/` contains the SQL analysis scripts organized by topic and a consolidated analysis script.
- `powerbi/` contains the Power BI dashboard.

## Dataset

The project uses the Olist Brazilian E-Commerce Public Dataset.

Source: [Brazilian E-Commerce Public Dataset by Olist — Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

## Notes

This is a portfolio project for practicing SQL, Python, data analysis, and business intelligence using real-world e-commerce data.