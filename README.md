# User-to-User Trading System

## Overview

This project presents the database design for a user-to-user online marketplace where individuals can buy and sell products. The primary objective is to design a relational database that manages users, product listings, wishlists, reviews, conversations, and administrative operations while maintaining data consistency and supporting common marketplace workflows. :contentReference[oaicite:0]{index=0}

## Objectives

- Design a normalized relational database for an online marketplace.
- Model buyer, seller, and administrator interactions.
- Support product listing and management.
- Store wishlist, review, and rating information.
- Maintain buyer-seller conversations.
- Enable analytical queries for buyers, sellers, and administrators. :contentReference[oaicite:1]{index=1}

## System Users

- Unregistered Users
- Buyers
- Sellers
- Administrators :contentReference[oaicite:2]{index=2}

## Functional Requirements

### Unregistered Users

- Search products
- View product details
- Compare prices
- View seller ratings and reviews

### Buyers

- Register and manage profile
- Search products
- Create and manage wishlists
- Rate sellers and products
- Write reviews
- Communicate with sellers

### Sellers

- Register and manage profile
- Add products
- Update product information
- Remove product listings

### Administrators

- Manage users
- Monitor product listings
- View ratings and feedback
- Generate reports :contentReference[oaicite:3]{index=3}

## Database Modules

- User Management
- Product Management
- Product Categories
- Product Images
- Wishlist Management
- Reviews and Ratings
- Buyer-Seller Messaging
- Administration :contentReference[oaicite:4]{index=4}

## Main Database Tables

- Users
- Buyers
- Sellers
- Admin
- Categories
- Products
- ProductImages
- Wishlist
- WishlistItems
- Reviews
- Conversations
- Messages :contentReference[oaicite:5]{index=5}

## Database Features

- Hierarchical product categories
- Multiple images per product
- Multiple wishlists per buyer
- Buyer-seller conversation history
- Product and seller reviews
- Marketplace reporting queries :contentReference[oaicite:6]{index=6}

## Reports

The database design supports queries such as:

- Product search using multiple filters
- Product price comparison
- Seller ratings
- Buyer orders and wishlists
- Seller product listings
- Seller ranking
- Product popularity
- Customer feedback
- Customer purchase history :contentReference[oaicite:7]{index=7}


## License

This repository is intended for academic and educational purposes.
