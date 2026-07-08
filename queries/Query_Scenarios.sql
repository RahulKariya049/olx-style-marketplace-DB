-- ============================================================
-- Query Scenarios
-- ============================================================

-- ============================================================
-- Scenario 1: Geographical Analysis & Logistics
-- ============================================================

-- 1. Count of available products listed per city
SELECT pl.city, COUNT(p.product_id) AS listing_count
FROM Products p
JOIN address a ON p.address_id = a.address_id
JOIN coordinate_pincode cp ON a.longitude = cp.longitude AND a.latitude = cp.latitude
JOIN pincode_location pl ON cp.pin = pl.pin
WHERE p.status = 'Available'
GROUP BY pl.city;


-- 2. Cities with high seller density (>= 3 unique sellers)
SELECT pl.city, COUNT(DISTINCT s.seller_id) AS seller_count
FROM pincode_location pl
JOIN coordinate_pincode cp ON pl.pin = cp.pin
JOIN address a ON cp.longitude = a.longitude AND cp.latitude = a.latitude
JOIN Seller s ON a.user_id = s.user_id
WHERE a.is_primary = TRUE
GROUP BY pl.city
HAVING COUNT(DISTINCT s.seller_id) >= 3;


-- 3. Rank cities by total revenue from sold products
SELECT pl.city, SUM(p.price) AS total_revenue,
       RANK() OVER (ORDER BY SUM(p.price) DESC) AS revenue_rank
FROM Products p
JOIN address a ON p.address_id = a.address_id
JOIN coordinate_pincode cp ON a.longitude = cp.longitude AND a.latitude = cp.latitude
JOIN pincode_location pl ON cp.pin = pl.pin
WHERE p.status = 'Sold'
GROUP BY pl.city
ORDER BY revenue_rank;


-- 4. City with the most buyers
SELECT pl.city, COUNT(b.buyer_id) AS buyer_count
FROM pincode_location pl
JOIN coordinate_pincode cp ON pl.pin = cp.pin
JOIN address a ON cp.longitude = a.longitude AND cp.latitude = a.latitude
JOIN Buyer b ON a.user_id = b.user_id
WHERE a.is_primary = TRUE
GROUP BY pl.city
ORDER BY buyer_count DESC
LIMIT 1;


-- ============================================================
-- Scenario 2: Sales, Inventory & Market Trends
-- ============================================================

-- 5. Optimal listing price guidance for a seller (category + city + condition)
SELECT
    c.category_name,
    loc.city,
    p.condition,
    ROUND(AVG(p.price), 2) AS estimated_avg_price,
    MIN(p.price) AS lowest_market_price,
    MAX(p.price) AS highest_market_price,
    COUNT(p.product_id) AS total_similar_products
FROM Products p
JOIN Categories c ON p.categorie_id = c.category_id
JOIN address a ON p.address_id = a.address_id
JOIN coordinate_pincode cp ON a.longitude = cp.longitude AND a.latitude = cp.latitude
JOIN pincode_location loc ON cp.pin = loc.pin
WHERE c.category_name = 'Mobiles'
  AND loc.city = 'Ahmedabad'
  AND p.condition = 'Good'
  AND p.status IN ('Available', 'Sold')
GROUP BY c.category_name, loc.city, p.condition;


-- 6. Top 3 cheapest 'Available' products per category
SELECT pname, price, category_name
FROM (
    SELECT p.pname, p.price, c.category_name,
           ROW_NUMBER() OVER (PARTITION BY c.category_id ORDER BY p.price ASC) AS rn
    FROM Products p
    JOIN Categories c ON p.categorie_id = c.category_id
    WHERE p.status = 'Available'
) ranked
WHERE rn <= 3;


-- 7. Market Health dashboard per category
SELECT
    c.category_name,
    COUNT(p.product_id) AS total_listings,
    COUNT(CASE WHEN p.status = 'Sold' THEN 1 END) AS sold,
    COUNT(CASE WHEN p.status = 'Available' THEN 1 END) AS available,
    ROUND(AVG(p.price), 2) AS avg_price,
    ROUND(AVG(CASE WHEN p.status = 'Sold' THEN p.price END), 2) AS avg_sold_price,
    ROUND(AVG(CASE WHEN p.status = 'Available' THEN p.price END), 2) AS avg_available_price
FROM Categories c
LEFT JOIN Products p ON c.category_id = p.categorie_id
GROUP BY c.category_name
ORDER BY total_listings DESC;


-- 8. Top rated seller per city
SELECT pl.city, u.name, s.seller_rating
FROM Seller s
JOIN "User" u ON s.user_id = u.user_id
JOIN address a ON u.user_id = a.user_id AND a.is_primary = TRUE
JOIN coordinate_pincode cp ON a.longitude = cp.longitude AND a.latitude = cp.latitude
JOIN pincode_location pl ON cp.pin = pl.pin
WHERE s.seller_rating = (
    SELECT MAX(s2.seller_rating)
    FROM Seller s2
    JOIN address a2 ON s2.user_id = a2.user_id AND a2.is_primary = TRUE
    JOIN coordinate_pincode cp2 ON a2.longitude = cp2.longitude AND a2.latitude = cp2.latitude
    JOIN pincode_location pl2 ON cp2.pin = pl2.pin
    WHERE pl2.city = pl.city
);


-- ============================================================
-- Scenario 3: User Interaction & Wishlist Strategy
-- ============================================================

-- 9. Most popular products by wishlist additions
SELECT p.product_id, p.pname, p.price, COUNT(wi.wishlist_id) AS total_wishlist_adds
FROM Products p
JOIN WishlistItems wi ON p.product_id = wi.product_id
GROUP BY p.product_id, p.pname, p.price
ORDER BY total_wishlist_adds DESC
LIMIT 10;


-- 10. Highly desired sellers (products in more than 5 wishlists)
SELECT u.name AS seller_name, s.seller_rating, COUNT(wi.wishlist_id) AS total_wishlist_adds
FROM Seller s
JOIN "User" u ON s.user_id = u.user_id
JOIN Products p ON s.seller_id = p.seller_id
JOIN WishlistItems wi ON p.product_id = wi.product_id
GROUP BY u.name, s.seller_rating
HAVING COUNT(wi.wishlist_id) > 5
ORDER BY total_wishlist_adds DESC;


-- 11. High-intent buyers: wishlisted a product AND messaged that product's seller
SELECT DISTINCT u.name AS high_intent_buyer, p.pname
FROM "User" u
JOIN Wishlist w ON u.user_id = w.user_id
JOIN WishlistItems wi ON w.wishlist_id = wi.wishlist_id
JOIN Products p ON wi.product_id = p.product_id
JOIN Buyer b ON u.user_id = b.user_id
JOIN Conversations conv ON b.buyer_id = conv.buyer_id AND conv.seller_id = p.seller_id;


-- 12. Collaborative-filtering style recommendations for user 5
SELECT DISTINCT p.pname, p.brand, p.price
FROM Products p
JOIN WishlistItems wi ON p.product_id = wi.product_id
JOIN Wishlist w ON wi.wishlist_id = w.wishlist_id
WHERE w.user_id IN (
    -- users who share at least 2 wishlisted products with user 5
    SELECT w2.user_id
    FROM Wishlist w2
    JOIN WishlistItems wi2 ON w2.wishlist_id = wi2.wishlist_id
    WHERE wi2.product_id IN (
        SELECT wi3.product_id
        FROM Wishlist w3
        JOIN WishlistItems wi3 ON w3.wishlist_id = wi3.wishlist_id
        WHERE w3.user_id = 5
    )
    AND w2.user_id <> 5
    GROUP BY w2.user_id
    HAVING COUNT(DISTINCT wi2.product_id) >= 2
)
AND p.product_id NOT IN (
    -- exclude products already in user 5's own wishlist
    SELECT wi4.product_id
    FROM Wishlist w4
    JOIN WishlistItems wi4 ON w4.wishlist_id = wi4.wishlist_id
    WHERE w4.user_id = 5
)
AND p.status = 'Available';


-- ============================================================
-- Scenario 4: Buyer/Seller Communication & Reviews
-- ============================================================

-- 13. Sellers rated below their city's average
SELECT u.name, s.seller_rating, pl.city
FROM Seller s
JOIN "User" u ON s.user_id = u.user_id
JOIN address a ON u.user_id = a.user_id AND a.is_primary = TRUE
JOIN coordinate_pincode cp ON a.longitude = cp.longitude AND a.latitude = cp.latitude
JOIN pincode_location pl ON cp.pin = pl.pin
WHERE s.seller_rating < (
    SELECT AVG(s2.seller_rating)
    FROM Seller s2
    JOIN address a2 ON s2.user_id = a2.user_id AND a2.is_primary = TRUE
    JOIN coordinate_pincode cp2 ON a2.longitude = cp2.longitude AND a2.latitude = cp2.latitude
    JOIN pincode_location pl2 ON cp2.pin = pl2.pin
    WHERE pl2.city = pl.city
);


-- 14. Nearby product listings for a buyer's feed (based on user 5's primary address)
-- NOTE: distance is plain Euclidean on lat/long degrees, not true ground
-- distance. Fine for rough sorting; use PostGIS/earthdistance for real km.
SELECT p.product_id, p.pname, p.price, p.date_of_listing, pi.image_url, pl.city,
       SQRT(POWER(a.longitude - buyer_loc.lon, 2) + POWER(a.latitude - buyer_loc.lat, 2)) AS distance
FROM Products p
JOIN address a ON p.address_id = a.address_id
JOIN coordinate_pincode cp ON a.longitude = cp.longitude AND a.latitude = cp.latitude
JOIN pincode_location pl ON cp.pin = pl.pin
JOIN Product_Image pi ON p.product_id = pi.product_id AND pi.is_primary = TRUE
CROSS JOIN (
    SELECT longitude AS lon, latitude AS lat
    FROM address
    WHERE user_id = 5 AND is_primary = TRUE
) AS buyer_loc
WHERE p.status = 'Available'
ORDER BY distance ASC, p.date_of_listing DESC;


-- 15. Price vs. distance trade-off (for user 2, Samsung listings)
SELECT p.pname, p.price,
       (p.price / 1000) + (SQRT(POWER(a.longitude - bl.longitude, 2)
                                + POWER(a.latitude - bl.latitude, 2)) * 10) AS value_rank
FROM Products p
JOIN address a ON p.address_id = a.address_id
CROSS JOIN (
    SELECT longitude, latitude
    FROM address
    WHERE user_id = 2 AND is_primary = TRUE
) bl
WHERE p.brand = 'Samsung'
  AND p.status = 'Available'
ORDER BY value_rank ASC;


-- 16. Seller "trust score" — weighted rating, review count, items sold
SELECT
    u.name AS seller_name,
    s.seller_rating,
    COALESCE(rev_stats.review_count, 0) AS review_count,
    COALESCE(sold_stats.items_sold, 0) AS items_sold,
    ROUND(
        (s.seller_rating * 0.4) +
        (LEAST(COALESCE(rev_stats.review_count, 0), 20) * 0.3 / 4) +
        (LEAST(COALESCE(sold_stats.items_sold, 0), 50) * 0.3 / 10), 2
    ) AS trust_score
FROM Seller s
JOIN "User" u ON s.user_id = u.user_id
LEFT JOIN (
    SELECT seller_id, COUNT(*) AS review_count
    FROM Review
    GROUP BY seller_id
) rev_stats ON s.seller_id = rev_stats.seller_id
LEFT JOIN (
    SELECT seller_id, COUNT(*) AS items_sold
    FROM Products
    WHERE status = 'Sold'
    GROUP BY seller_id
) sold_stats ON s.seller_id = sold_stats.seller_id
ORDER BY trust_score DESC;


-- ============================================================
-- Scenario 5: Account Security & Platform Administration
-- ============================================================

-- 17. Sellers who have never listed a product (inactive profiles)
SELECT seller_id
FROM Seller
WHERE seller_id NOT IN (SELECT DISTINCT seller_id FROM Products);


-- 18. Sellers with listings but zero successful sales
SELECT s.seller_id, u.name, u.email
FROM Seller s
JOIN "User" u ON s.user_id = u.user_id
WHERE EXISTS (SELECT 1 FROM Products p1 WHERE p1.seller_id = s.seller_id)
  AND s.seller_id NOT IN (
      SELECT DISTINCT p2.seller_id FROM Products p2 WHERE p2.status = 'Sold'
  );


-- 19. Scam detection — products priced suspiciously low, from newer accounts
-- (accounts registered in the last 90 days; adjust the interval as needed)
SELECT
    p.pname,
    p.brand,
    p.price AS suspicious_price,
    ROUND(brand_avg.avg_price, 2) AS market_avg,
    u.name AS seller_name,
    u.reg_date AS account_created,
    ROUND((p.price / brand_avg.avg_price) * 100, 2) AS price_percentage
FROM Products p
JOIN Seller s ON p.seller_id = s.seller_id
JOIN "User" u ON s.user_id = u.user_id
JOIN (
    SELECT brand, AVG(price) AS avg_price
    FROM Products
    GROUP BY brand
) AS brand_avg ON p.brand = brand_avg.brand
WHERE p.status = 'Available'
  AND p.price < (brand_avg.avg_price * 0.5)
  AND u.reg_date >= CURRENT_DATE - INTERVAL '90 days'
ORDER BY price_percentage ASC;


-- 20. New accounts (last 7 days) with more than 5 listings — rapid-listing flag
SELECT u.name, u.email, u.reg_date, COUNT(p.product_id) AS listing_count
FROM "User" u
JOIN Seller s ON u.user_id = s.user_id
JOIN Products p ON s.seller_id = p.seller_id
WHERE u.reg_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY u.name, u.email, u.reg_date
HAVING COUNT(p.product_id) > 5
ORDER BY listing_count DESC;