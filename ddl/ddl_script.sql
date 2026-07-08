-- ============================================
-- Final DDL Script — OLX-Style Marketplace
-- ============================================

CREATE TABLE "User" (
    user_id BIGINT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    reg_date DATE DEFAULT CURRENT_DATE,
    img_url TEXT,
    password VARCHAR(255) NOT NULL
);

CREATE TABLE Buyer (
    buyer_id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES "User"(user_id) ON DELETE CASCADE
);

CREATE TABLE Seller (
    seller_id BIGINT PRIMARY KEY,
    seller_rating DECIMAL(3, 2),
    user_id BIGINT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES "User"(user_id) ON DELETE CASCADE
);

CREATE TABLE Admin (
    admin_id BIGINT PRIMARY KEY,
    role VARCHAR(50) NOT NULL,
    user_id BIGINT UNIQUE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES "User"(user_id) ON DELETE CASCADE
);

CREATE TABLE Phone_no (
    user_id BIGINT,
    phone VARCHAR(20),
    PRIMARY KEY (user_id, phone),
    FOREIGN KEY (user_id) REFERENCES "User"(user_id) ON DELETE CASCADE
);

CREATE TABLE pincode_location (
    pin INT PRIMARY KEY,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL
);

CREATE TABLE coordinate_pincode (
    longitude DECIMAL(10, 7),
    latitude DECIMAL(10, 7),
    pin INT NOT NULL,
    PRIMARY KEY (longitude, latitude),
    FOREIGN KEY (pin) REFERENCES pincode_location(pin) ON DELETE CASCADE
);

CREATE TABLE address (
    address_id BIGINT PRIMARY KEY,
    address_line TEXT NOT NULL,
    label VARCHAR(50),
    is_primary BOOLEAN DEFAULT FALSE,
    longitude DECIMAL(10, 7) NOT NULL,
    latitude DECIMAL(10, 7) NOT NULL,
    user_id BIGINT NOT NULL,
    FOREIGN KEY (longitude, latitude) REFERENCES coordinate_pincode(longitude, latitude) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES "User"(user_id) ON DELETE CASCADE
);

CREATE TABLE Categories (
    category_id BIGINT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    parent_id BIGINT,
    FOREIGN KEY (parent_id) REFERENCES Categories(category_id)
);

CREATE TABLE Products (
    product_id BIGINT PRIMARY KEY,
    pname VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    brand VARCHAR(100),
    model VARCHAR(100),
    condition VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,
    date_of_listing DATE DEFAULT CURRENT_DATE,
    address_id BIGINT NOT NULL,
    seller_id BIGINT NOT NULL,
    categorie_id BIGINT NOT NULL,
    FOREIGN KEY (address_id) REFERENCES address(address_id),
    FOREIGN KEY (seller_id) REFERENCES Seller(seller_id) ON DELETE CASCADE,
    FOREIGN KEY (categorie_id) REFERENCES Categories(category_id)
);

CREATE TABLE Wishlist (
    wishlist_id BIGINT PRIMARY KEY,
    wishlist_name VARCHAR(100) NOT NULL,
    created_date DATE DEFAULT CURRENT_DATE,
    user_id BIGINT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES "User"(user_id) ON DELETE CASCADE
);

CREATE TABLE WishlistItems (
    product_id BIGINT,
    wishlist_id BIGINT,
    PRIMARY KEY (product_id, wishlist_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (wishlist_id) REFERENCES Wishlist(wishlist_id) ON DELETE CASCADE
);

CREATE TABLE Product_Image (
    image_url TEXT,
    product_id BIGINT,
    is_primary BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (image_url, product_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id) ON DELETE CASCADE
);

-- Review: ternary relationship (Buyer, Seller, Product)
-- Composite PK enforces one review per buyer-seller-product combination
CREATE TABLE Review (
    buyer_id BIGINT,
    seller_id BIGINT,
    product_id BIGINT,
    review_comment TEXT,
    review_type VARCHAR(50) NOT NULL,
    review_date DATE DEFAULT CURRENT_DATE,
    rating DECIMAL(2, 1) CHECK (rating >= 1.0 AND rating <= 5.0),
    PRIMARY KEY (buyer_id, seller_id, product_id),
    FOREIGN KEY (buyer_id) REFERENCES Buyer(buyer_id) ON DELETE CASCADE,
    FOREIGN KEY (seller_id) REFERENCES Seller(seller_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(product_id) ON DELETE CASCADE
);

CREATE TABLE Notifications (
    notification_id BIGINT PRIMARY KEY,
    type VARCHAR(50),
    message TEXT NOT NULL,
    notification_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL,
    user_id BIGINT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES "User"(user_id) ON DELETE CASCADE
);

CREATE TABLE Conversations (
    conversation_id BIGINT PRIMARY KEY,
    start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status BOOL,
    seller_id BIGINT NOT NULL,
    buyer_id BIGINT NOT NULL,
    FOREIGN KEY (seller_id) REFERENCES Seller(seller_id) ON DELETE CASCADE,
    FOREIGN KEY (buyer_id) REFERENCES Buyer(buyer_id) ON DELETE CASCADE
);

CREATE TABLE Message (
    message_id BIGINT PRIMARY KEY,
    message_content TEXT NOT NULL,
    sent_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    conversation_id BIGINT NOT NULL,
    FOREIGN KEY (conversation_id) REFERENCES Conversations(conversation_id) ON DELETE CASCADE
);