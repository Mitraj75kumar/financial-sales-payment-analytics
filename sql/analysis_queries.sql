CREATE TABLE product_lines (
    product_line VARCHAR(100) PRIMARY KEY,
    text_description TEXT
);


--- Office
CREATE TABLE offices (
    office_code VARCHAR(10) PRIMARY KEY,
    city VARCHAR(100),
    phone VARCHAR(50),
    address_line1 VARCHAR(100),
    address_line2 VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    territory VARCHAR(100)
);

---Employees
CREATE TABLE employees (
    employee_number INT PRIMARY KEY,
    last_name VARCHAR(100),
    first_name VARCHAR(100),
    extension VARCHAR(20),
    email VARCHAR(150),
    office_code VARCHAR(10),
    reports_to INT,
    job_title VARCHAR(100),

    FOREIGN KEY (office_code)
        REFERENCES offices(office_code),

    FOREIGN KEY (reports_to)
        REFERENCES employees(employee_number)
);

--- Customers
CREATE TABLE customers (
    customer_number INT PRIMARY KEY,
    customer_name VARCHAR(150),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    sales_rep_employee_number INT,
    credit_limit NUMERIC(15,2),

    FOREIGN KEY (sales_rep_employee_number)
        REFERENCES employees(employee_number)
);

--- Products
CREATE TABLE products (
    product_code VARCHAR(20) PRIMARY KEY,
    product_name VARCHAR(200),
    product_line VARCHAR(100),
    product_vendor VARCHAR(150),
    product_description TEXT,
    quantity_in_stock INT,
    buy_price NUMERIC(10,2),
    msrp NUMERIC(10,2),

    FOREIGN KEY (product_line)
        REFERENCES product_lines(product_line)
);

--- Orders
CREATE TABLE orders (
    order_number INT PRIMARY KEY,
    order_date DATE,
    required_date DATE,
    shipped_date DATE,
    status VARCHAR(50),
    customer_number INT,
    shipped_day INT,

    FOREIGN KEY (customer_number)
        REFERENCES customers(customer_number)
);

---- Order Details
CREATE TABLE order_details (
    order_number INT,
    product_code VARCHAR(20),
    quantity_ordered INT,
    price_each NUMERIC(10,2),
    buy_price NUMERIC(10,2),
    sales NUMERIC(15,2),
    profit NUMERIC(15,2),

    PRIMARY KEY (order_number, product_code),

    FOREIGN KEY (order_number)
        REFERENCES orders(order_number),

    FOREIGN KEY (product_code)
        REFERENCES products(product_code)
);

---- Payments
CREATE TABLE payments (
    customer_number INT,
    check_number VARCHAR(50),
    payment_date DATE,
    amount NUMERIC(15,2),

    PRIMARY KEY (customer_number, check_number),

    FOREIGN KEY (customer_number)
        REFERENCES customers(customer_number)
);


--- 1. Overall KPIs
SELECT
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(
        SUM(profit) / NULLIF(SUM(sales), 0) * 100,
        2
    ) AS profit_margin,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(quantity_ordered) AS total_quantity
FROM order_details;

---Analysis 2 — Sales by Product Category
SELECT
    p.product_line,
    ROUND(SUM(od.sales), 2) AS total_sales,
    ROUND(SUM(od.profit), 2) AS total_profit,
    SUM(od.quantity_ordered) AS quantity_sold
FROM order_details od
JOIN products p
    ON od.product_code = p.product_code
GROUP BY p.product_line
ORDER BY total_sales DESC;


---Analysis 3 — Top 10 Products
SELECT
    p.product_code,
    p.product_name,
    p.product_line,
    ROUND(SUM(od.sales), 2) AS total_sales,
    ROUND(SUM(od.profit), 2) AS total_profit,
    SUM(od.quantity_ordered) AS quantity_sold
FROM order_details od
JOIN products p
    ON od.product_code = p.product_code
GROUP BY
    p.product_code,
    p.product_name,
    p.product_line
ORDER BY total_sales DESC
LIMIT 10;

--- Analysis 4 — Sales & Profit by Year
SELECT
    EXTRACT(YEAR FROM o.order_date)::INT AS year,
    ROUND(SUM(od.sales), 2) AS total_sales,
    ROUND(SUM(od.profit), 2) AS total_profit,
    SUM(od.quantity_ordered) AS quantity_sold,
    COUNT(DISTINCT o.order_number) AS total_orders
FROM orders o
JOIN order_details od
    ON o.order_number = od.order_number
GROUP BY year
ORDER BY year;


---- Analysis 5 — Monthly Sales Trend
SELECT
    EXTRACT(YEAR FROM o.order_date)::INT AS year,
    EXTRACT(MONTH FROM o.order_date)::INT AS month,
    ROUND(SUM(od.sales), 2) AS total_sales,
    ROUND(SUM(od.profit), 2) AS total_profit
FROM orders o
JOIN order_details od
    ON o.order_number = od.order_number
GROUP BY year, month
ORDER BY year, month;

---- Analysis 6 — Sales by Country
SELECT
    c.country,
    ROUND(SUM(od.sales), 2) AS total_sales,
    ROUND(SUM(od.profit), 2) AS total_profit,
    COUNT(DISTINCT o.order_number) AS total_orders
FROM orders o
JOIN customers c
    ON o.customer_number = c.customer_number
JOIN order_details od
    ON o.order_number = od.order_number
GROUP BY c.country
ORDER BY total_sales DESC;


--- Analysis 7 — Top 10 Customers by Sales
SELECT
    c.customer_number,
    c.customer_name,
    c.country,
    ROUND(SUM(od.sales), 2) AS total_sales,
    ROUND(SUM(od.profit), 2) AS total_profit,
    COUNT(DISTINCT o.order_number) AS total_orders,
    SUM(od.quantity_ordered) AS quantity_sold
FROM customers c
JOIN orders o
    ON c.customer_number = o.customer_number
JOIN order_details od
    ON o.order_number = od.order_number
GROUP BY
    c.customer_number,
    c.customer_name,
    c.country
ORDER BY total_sales DESC
LIMIT 10;


--- Analysis 8 — Top Customers by Profit
SELECT
    c.customer_name,
    c.country,
    ROUND(SUM(od.profit), 2) AS total_profit,
    ROUND(SUM(od.sales), 2) AS total_sales,
    ROUND(
        SUM(od.profit) / NULLIF(SUM(od.sales), 0) * 100,
        2
    ) AS profit_margin
FROM customers c
JOIN orders o
    ON c.customer_number = o.customer_number
JOIN order_details od
    ON o.order_number = od.order_number
GROUP BY
    c.customer_name,
    c.country
ORDER BY total_profit DESC
LIMIT 10;

--- Analysis 9 — Payment Analysis
SELECT
    COUNT(*) AS total_payments,
    COUNT(DISTINCT customer_number) AS paying_customers,
    ROUND(SUM(amount), 2) AS total_payment,
    ROUND(AVG(amount), 2) AS average_payment,
    ROUND(MIN(amount), 2) AS minimum_payment,
    ROUND(MAX(amount), 2) AS maximum_payment
FROM payments;

--- Analysis 10 — Order Status
SELECT
    status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS order_percentage
FROM orders
GROUP BY status
ORDER BY total_orders DESC;

----Analysis 11 — Average Shipping Time
SELECT
    COUNT(*) AS shipped_orders,
    ROUND(AVG(shipped_day), 2) AS avg_shipping_days,
    MIN(shipped_day) AS min_shipping_days,
    MAX(shipped_day) AS max_shipping_days
FROM orders
WHERE shipped_date IS NOT NULL;

--- Analysis 12 — Late Shipments

SELECT
    COUNT(*) AS late_shipments
FROM orders
WHERE shipped_date IS NOT NULL
  AND shipped_date > required_date;

  ---late shipment rate:
  SELECT
    COUNT(*) FILTER (
        WHERE shipped_date IS NOT NULL
          AND shipped_date > required_date
    ) AS late_shipments,
    COUNT(*) FILTER (
        WHERE shipped_date IS NOT NULL
    ) AS shipped_orders,
    ROUND(
        COUNT(*) FILTER (
            WHERE shipped_date IS NOT NULL
              AND shipped_date > required_date
        ) * 100.0
        / NULLIF(
            COUNT(*) FILTER (
                WHERE shipped_date IS NOT NULL
            ), 0
        ),
        2
    ) AS late_shipment_rate
FROM orders;

---- Analysis 13 — Average Delivery Time by Status
SELECT
    status,
    COUNT(*) AS total_orders,
    ROUND(AVG(shipped_day), 2) AS avg_shipping_days
FROM orders
WHERE shipped_date IS NOT NULL
GROUP BY status
ORDER BY avg_shipping_days DESC;

--- Analysis 14 — Product Performance
SELECT
    p.product_code,
    p.product_name,
    p.product_line,
    p.quantity_in_stock,
    SUM(od.quantity_ordered) AS quantity_sold,
    ROUND(SUM(od.sales), 2) AS total_sales,
    ROUND(SUM(od.profit), 2) AS total_profit,
    ROUND(
        SUM(od.profit) / NULLIF(SUM(od.sales), 0) * 100,
        2
    ) AS profit_margin
FROM products p
JOIN order_details od
    ON p.product_code = od.product_code
GROUP BY
    p.product_code,
    p.product_name,
    p.product_line,
    p.quantity_in_stock
ORDER BY total_sales DESC;


--- Analysis 15 — Top 10 Products by Profit
SELECT
    p.product_name,
    p.product_line,
    ROUND(SUM(od.profit), 2) AS total_profit,
    ROUND(SUM(od.sales), 2) AS total_sales,
    SUM(od.quantity_ordered) AS quantity_sold
FROM products p
JOIN order_details od
    ON p.product_code = od.product_code
GROUP BY
    p.product_name,
    p.product_line
ORDER BY total_profit DESC
LIMIT 10;


--- Analysis 16 — Low Stock Products
SELECT
    product_code,
    product_name,
    product_line,
    quantity_in_stock,
    buy_price,
    msrp
FROM products
ORDER BY quantity_in_stock ASC
LIMIT 10;


--- Analysis 17 — Products with High Sales but Low Stock
SELECT
    p.product_name,
    p.product_line,
    p.quantity_in_stock,
    SUM(od.quantity_ordered) AS quantity_sold,
    ROUND(SUM(od.sales), 2) AS total_sales
FROM products p
JOIN order_details od
    ON p.product_code = od.product_code
GROUP BY
    p.product_code,
    p.product_name,
    p.product_line,
    p.quantity_in_stock
HAVING SUM(od.quantity_ordered) > p.quantity_in_stock
ORDER BY total_sales DESC;

--- Analysis 18 — Sales by Sales Representative
SELECT
    e.employee_number,
    e.first_name || ' ' || e.last_name AS sales_rep,
    e.job_title,
    o.city AS office_city,
    o.country,
    COUNT(DISTINCT ord.order_number) AS total_orders,
    ROUND(SUM(od.sales), 2) AS total_sales,
    ROUND(SUM(od.profit), 2) AS total_profit
FROM employees e
JOIN customers c
    ON e.employee_number = c.sales_rep_employee_number
JOIN orders ord
    ON c.customer_number = ord.customer_number
JOIN order_details od
    ON ord.order_number = od.order_number
JOIN offices o
    ON e.office_code = o.office_code
GROUP BY
    e.employee_number,
    e.first_name,
    e.last_name,
    e.job_title,
    o.city,
    o.country
ORDER BY total_sales DESC;

---Analysis 19 — Top 5 Sales Representatives
SELECT
    e.first_name || ' ' || e.last_name AS sales_rep,
    COUNT(DISTINCT ord.order_number) AS total_orders,
    ROUND(SUM(od.sales), 2) AS total_sales,
    ROUND(SUM(od.profit), 2) AS total_profit,
    ROUND(
        SUM(od.profit) / NULLIF(SUM(od.sales), 0) * 100,
        2
    ) AS profit_margin
FROM employees e
JOIN customers c
    ON e.employee_number = c.sales_rep_employee_number
JOIN orders ord
    ON c.customer_number = ord.customer_number
JOIN order_details od
    ON ord.order_number = od.order_number
GROUP BY
    e.employee_number,
    e.first_name,
    e.last_name
ORDER BY total_sales DESC
LIMIT 5;


---- Analysis 20 — Sales by Office
SELECT
    o.city,
    o.country,
    COUNT(DISTINCT c.customer_number) AS customers,
    COUNT(DISTINCT ord.order_number) AS total_orders,
    ROUND(SUM(od.sales), 2) AS total_sales,
    ROUND(SUM(od.profit), 2) AS total_profit
FROM offices o
JOIN employees e
    ON o.office_code = e.office_code
JOIN customers c
    ON e.employee_number = c.sales_rep_employee_number
JOIN orders ord
    ON c.customer_number = ord.customer_number
JOIN order_details od
    ON ord.order_number = od.order_number
GROUP BY o.city, o.country
ORDER BY total_sales DESC;

--- Create the main Sales View
CREATE OR REPLACE VIEW vw_sales_analysis AS
SELECT
    o.order_number,
    o.order_date,
    o.required_date,
    o.shipped_date,
    o.shipped_day,
    o.status,

    c.customer_number,
    c.customer_name,
    c.country,

    p.product_code,
    p.product_name,
    p.product_line,

    od.quantity_ordered,
    od.price_each,
    od.buy_price,
    od.sales,
    od.profit,

    ROUND(
        od.profit / NULLIF(od.sales, 0) * 100,
        2
    ) AS profit_margin

FROM orders o
JOIN customers c
    ON o.customer_number = c.customer_number
JOIN order_details od
    ON o.order_number = od.order_number
JOIN products p
    ON od.product_code = p.product_code;

	---Check the View
	SELECT *
FROM vw_sales_analysis
LIMIT 10;


---- Create Payment View
CREATE OR REPLACE VIEW vw_payment_analysis AS
SELECT
    p.customer_number,
    c.customer_name,
    c.country,
    p.check_number,
    p.payment_date,
    p.amount
FROM payments p
JOIN customers c
    ON p.customer_number = c.customer_number;

-- check
SELECT *
FROM vw_payment_analysis
LIMIT 10;

--- Create Customer Performance View
CREATE OR REPLACE VIEW vw_customer_performance AS
SELECT
    c.customer_number,
    c.customer_name,
    c.country,
    COUNT(DISTINCT o.order_number) AS total_orders,
    SUM(od.quantity_ordered) AS quantity_sold,
    ROUND(SUM(od.sales), 2) AS total_sales,
    ROUND(SUM(od.profit), 2) AS total_profit,
    ROUND(
        SUM(od.profit) / NULLIF(SUM(od.sales), 0) * 100,
        2
    ) AS profit_margin
FROM customers c
JOIN orders o
    ON c.customer_number = o.customer_number
JOIN order_details od
    ON o.order_number = od.order_number
GROUP BY
    c.customer_number,
    c.customer_name,
    c.country;

-- check
SELECT *
FROM vw_customer_performance
ORDER BY total_sales DESC
LIMIT 10;

	