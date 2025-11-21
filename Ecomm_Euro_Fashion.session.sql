
DROP TABLE IF EXISTS store;
CREATE TABLE store (
    channel VARCHAR(50) PRIMARY KEY,
    description TEXT NOT NULL
);

DROP TABLE IF EXISTS campaigns;
CREATE TABLE campaigns (
    campaign_id INT PRIMARY KEY,
    campaign_name VARCHAR(300) SECONDARY KEY,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    channel VARCHAR(50) NOT NULL,
    discount_type VARCHAR(50) NOT NULL,
    discount_value DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (channel) REFERENCES store(channel) ON DELETE CASCADE
    );

DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    country VARCHAR(100) SECONDARY KEY NOT NULL,
    age_range VARCHAR(50) NOT NULL,
    signup_date DATE NOT NULL
);

DROP TABLE IF EXISTS products;
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(300) NOT NUll,
    category VARCHAR(100) NOT NULL,
    brand VARCHAR(100) NOT NULL,
    color VARCHAR(50) NOT NULL,
    size VARCHAR(50),
    catalog_price DECIMAL(10,2),
    cost_price DECIMAL(10,2),
    gender VARCHAR(50)
);

DROP TABLE IF EXISTS sales;
CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    channel VARCHAR(50) NOT NULL,
    discounted INT NOT NULL,
    total_amount DECIMAL(10,2),
    sale_date DATE,
    customer_id INT NOT NULL,
    country VARCHAR(100) NOT NULL,
    FOREIGN KEY (channel) REFERENCES store(channel) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

DROP TABLE IF EXISTS sales_items;
CREATE TABLE sales_items (
    item_id INT PRIMARY KEY,
    sale_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    original_price DECIMAL(10,2),
    unit_price DECIMAL(10,2),
    discount_applied DECIMAL(10,2),
    discount_percentage DECIMAL(5,2),
    discounted INT,
    item_total DECIMAL(10,2),
    FOREIGN KEY (sale_id) REFERENCES sales(sale_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

DROP TABLE IF EXISTS stock;
CREATE TABLE stock (
    country VARCHAR(100) NOT NULL,
    product_id INT NOT NULL,
    stock_quantity INT NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

DELIMITER $$

CREATE PROCEDURE populate_stock()
BEGIN
    DECLARE i INT DEFAULT 1;

    WHILE i < 501 DO
        INSERT INTO ecomm_euro_fashion.stock (country, product_id, stock_quantity)
        VALUES
        ('Germany', i, FLOOR(RAND() * 100) + 1),
        ('Italy', i, FLOOR(RAND() * 100) + 1),
        ('Portugal', i, FLOOR(RAND() * 100) + 1),
        ('Spain', i, FLOOR(RAND() * 100) + 1),
        ('Netherlands', i, FLOOR(RAND() * 100) + 1);
        
        SET i = i + 1;
    END WHILE;

END$$

DELIMITER ;

CALL populate_stock();

UPDATE sales 
SET country = TRIM(REPLACE(country, '\r', ''))
WHERE country LIKE '%\r%';