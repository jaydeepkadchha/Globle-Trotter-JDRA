-- ============================================================
-- GlobeTrotter Database
-- Version: 1.0
-- Platform: MySQL / MariaDB (XAMPP compatible)
-- Database: globetrotter
-- ============================================================
--
-- This schema is based on the current GlobeTrotter frontend,
-- project brief and existing PHP authentication backend.
--
-- Main flow:
-- USER -> TRIP -> STOPS -> DAYS -> ITINERARY ITEMS
--                         \-> EXPENSES
-- USER -> SAVED CITIES / ACTIVITIES
-- USER -> COMMUNITY POSTS
-- USER -> CALENDAR EVENTS
--
-- IMPORTANT:
-- This file is intended as the main project schema. If an older
-- 'globetrotter' database already exists, back it up before using
-- this schema as a replacement.
-- ============================================================

CREATE DATABASE IF NOT EXISTS globetrotter
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE globetrotter;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ------------------------------------------------------------
-- 1. USERS
-- Compatible with the current login.php / register.php backend.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS community_comments;
DROP TABLE IF EXISTS community_likes;
DROP TABLE IF EXISTS community_posts;
DROP TABLE IF EXISTS calendar_events;
DROP TABLE IF EXISTS saved_activities;
DROP TABLE IF EXISTS saved_cities;
DROP TABLE IF EXISTS trip_collaborators;
DROP TABLE IF EXISTS itinerary_items;
DROP TABLE IF EXISTS itinerary_days;
DROP TABLE IF EXISTS expenses;
DROP TABLE IF EXISTS trip_stops;
DROP TABLE IF EXISTS trips;
DROP TABLE IF EXISTS activities;
DROP TABLE IF EXISTS interests;
DROP TABLE IF EXISTS cities;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(20) DEFAULT NULL,
    city VARCHAR(100) DEFAULT NULL,
    country VARCHAR(100) DEFAULT NULL,
    additional_info TEXT DEFAULT NULL,
    photo VARCHAR(255) DEFAULT NULL,
    travel_style VARCHAR(50) DEFAULT NULL,
    language_code VARCHAR(10) NOT NULL DEFAULT 'en',
    role ENUM('user','admin') NOT NULL DEFAULT 'user',
    status ENUM('active','inactive','suspended') NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_users_country (country),
    INDEX idx_users_city (city),
    INDEX idx_users_role_status (role, status)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2. CITIES / DESTINATIONS
-- Used by Home, Explore, Create Trip and City Search.
-- ------------------------------------------------------------
CREATE TABLE cities (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    country_code CHAR(2) DEFAULT NULL,
    region VARCHAR(100) DEFAULT NULL,
    description TEXT DEFAULT NULL,
    image_url VARCHAR(500) DEFAULT NULL,
    rating DECIMAL(2,1) DEFAULT NULL,
    cost_index TINYINT UNSIGNED DEFAULT NULL,
    popularity_score DECIMAL(8,2) NOT NULL DEFAULT 0,
    latitude DECIMAL(10,7) DEFAULT NULL,
    longitude DECIMAL(10,7) DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_city_country (name, country),
    INDEX idx_cities_country (country),
    INDEX idx_cities_region (region),
    INDEX idx_cities_popularity (popularity_score)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 3. INTERESTS
-- Used by Create Trip and personalization.
-- ------------------------------------------------------------
CREATE TABLE interests (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    icon VARCHAR(20) DEFAULT NULL,
    description VARCHAR(255) DEFAULT NULL
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 4. ACTIVITIES
-- Activities that can be searched and added to itineraries.
-- ------------------------------------------------------------
CREATE TABLE activities (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    city_id INT UNSIGNED DEFAULT NULL,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    description TEXT DEFAULT NULL,
    image_url VARCHAR(500) DEFAULT NULL,
    duration_minutes SMALLINT UNSIGNED DEFAULT NULL,
    estimated_cost DECIMAL(12,2) NOT NULL DEFAULT 0,
    currency CHAR(3) NOT NULL DEFAULT 'INR',
    rating DECIMAL(2,1) DEFAULT NULL,
    popularity_score DECIMAL(8,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_activities_city
        FOREIGN KEY (city_id) REFERENCES cities(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_activities_city (city_id),
    INDEX idx_activities_category (category),
    INDEX idx_activities_popularity (popularity_score),
    FULLTEXT KEY ft_activities_search (name, description)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 5. TRIPS
-- One user can own many trips.
-- ------------------------------------------------------------
CREATE TABLE trips (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT DEFAULT NULL,
    cover_photo VARCHAR(500) DEFAULT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    travelers_count SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    budget_amount DECIMAL(12,2) DEFAULT NULL,
    budget_currency CHAR(3) NOT NULL DEFAULT 'INR',
    budget_range VARCHAR(50) DEFAULT NULL,
    travel_style VARCHAR(50) DEFAULT NULL,
    status ENUM('draft','planned','ongoing','completed','cancelled') NOT NULL DEFAULT 'draft',
    is_public BOOLEAN NOT NULL DEFAULT FALSE,
    public_slug VARCHAR(180) DEFAULT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_trips_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_trips_user_dates (user_id, start_date, end_date),
    INDEX idx_trips_status (status),
    INDEX idx_trips_public (is_public)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 6. TRIP STOPS / ITINERARY SECTIONS
-- A trip can contain multiple cities/stops.
-- ------------------------------------------------------------
CREATE TABLE trip_stops (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    trip_id INT UNSIGNED NOT NULL,
    city_id INT UNSIGNED NOT NULL,
    stop_order SMALLINT UNSIGNED NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    budget_amount DECIMAL(12,2) DEFAULT NULL,
    notes TEXT DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_trip_stops_trip
        FOREIGN KEY (trip_id) REFERENCES trips(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_trip_stops_city
        FOREIGN KEY (city_id) REFERENCES cities(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE KEY uq_trip_stop_order (trip_id, stop_order),
    INDEX idx_trip_stops_trip_dates (trip_id, start_date, end_date),
    INDEX idx_trip_stops_city (city_id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 7. ITINERARY DAYS
-- Supports day-wise itinerary/calendar rendering.
-- ------------------------------------------------------------
CREATE TABLE itinerary_days (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    trip_id INT UNSIGNED NOT NULL,
    stop_id INT UNSIGNED DEFAULT NULL,
    day_number SMALLINT UNSIGNED NOT NULL,
    day_date DATE NOT NULL,
    title VARCHAR(150) DEFAULT NULL,
    description TEXT DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_itinerary_days_trip
        FOREIGN KEY (trip_id) REFERENCES trips(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_itinerary_days_stop
        FOREIGN KEY (stop_id) REFERENCES trip_stops(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    UNIQUE KEY uq_trip_day_number (trip_id, day_number),
    UNIQUE KEY uq_trip_day_date (trip_id, day_date),
    INDEX idx_itinerary_days_date (day_date)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 8. ITINERARY ITEMS
-- Individual activities, meals, transport, check-ins, etc.
-- ------------------------------------------------------------
CREATE TABLE itinerary_items (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    day_id INT UNSIGNED NOT NULL,
    activity_id INT UNSIGNED DEFAULT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT DEFAULT NULL,
    item_type ENUM('activity','transport','meal','stay','personal','other') NOT NULL DEFAULT 'activity',
    location_name VARCHAR(200) DEFAULT NULL,
    start_time TIME DEFAULT NULL,
    end_time TIME DEFAULT NULL,
    sort_order SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    estimated_cost DECIMAL(12,2) DEFAULT NULL,
    actual_cost DECIMAL(12,2) DEFAULT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'INR',
    status ENUM('planned','completed','skipped') NOT NULL DEFAULT 'planned',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_itinerary_items_day
        FOREIGN KEY (day_id) REFERENCES itinerary_days(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_itinerary_items_activity
        FOREIGN KEY (activity_id) REFERENCES activities(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_itinerary_items_day_order (day_id, sort_order),
    INDEX idx_itinerary_items_time (start_time, end_time),
    INDEX idx_itinerary_items_type (item_type)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 9. EXPENSES / BUDGET ITEMS
-- Supports budget breakdown, daily spending and over-budget alerts.
-- ------------------------------------------------------------
CREATE TABLE expenses (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    trip_id INT UNSIGNED NOT NULL,
    day_id INT UNSIGNED DEFAULT NULL,
    stop_id INT UNSIGNED DEFAULT NULL,
    itinerary_item_id INT UNSIGNED DEFAULT NULL,
    category ENUM('transport','stay','activities','meals','shopping','other') NOT NULL,
    description VARCHAR(255) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'INR',
    expense_date DATE NOT NULL,
    is_estimated BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_expenses_trip
        FOREIGN KEY (trip_id) REFERENCES trips(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_expenses_day
        FOREIGN KEY (day_id) REFERENCES itinerary_days(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_expenses_stop
        FOREIGN KEY (stop_id) REFERENCES trip_stops(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_expenses_item
        FOREIGN KEY (itinerary_item_id) REFERENCES itinerary_items(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_expenses_trip_date (trip_id, expense_date),
    INDEX idx_expenses_category (category)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 10. TRIP COLLABORATORS
-- Allows a trip to be shared with friends/users later.
-- ------------------------------------------------------------
CREATE TABLE trip_collaborators (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    trip_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED NOT NULL,
    access_level ENUM('viewer','editor') NOT NULL DEFAULT 'viewer',
    status ENUM('pending','accepted','declined') NOT NULL DEFAULT 'pending',
    invited_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT fk_trip_collaborators_trip
        FOREIGN KEY (trip_id) REFERENCES trips(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_trip_collaborators_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY uq_trip_collaborator (trip_id, user_id),
    INDEX idx_trip_collaborators_user (user_id, status)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 11. USER INTERESTS
-- User's selected interests from personalization.
-- ------------------------------------------------------------
CREATE TABLE user_interests (
    user_id INT UNSIGNED NOT NULL,
    interest_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (user_id, interest_id),
    CONSTRAINT fk_user_interests_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_user_interests_interest
        FOREIGN KEY (interest_id) REFERENCES interests(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 12. TRIP INTERESTS
-- Interests selected for a particular trip.
-- ------------------------------------------------------------
CREATE TABLE trip_interests (
    trip_id INT UNSIGNED NOT NULL,
    interest_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (trip_id, interest_id),
    CONSTRAINT fk_trip_interests_trip
        FOREIGN KEY (trip_id) REFERENCES trips(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_trip_interests_interest
        FOREIGN KEY (interest_id) REFERENCES interests(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 13. SAVED CITIES
-- Used by Explore/Profile saved places.
-- ------------------------------------------------------------
CREATE TABLE saved_cities (
    user_id INT UNSIGNED NOT NULL,
    city_id INT UNSIGNED NOT NULL,
    saved_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, city_id),
    CONSTRAINT fk_saved_cities_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_saved_cities_city
        FOREIGN KEY (city_id) REFERENCES cities(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 14. SAVED ACTIVITIES
-- Optional but useful for Activity Search / Explore.
-- ------------------------------------------------------------
CREATE TABLE saved_activities (
    user_id INT UNSIGNED NOT NULL,
    activity_id INT UNSIGNED NOT NULL,
    saved_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, activity_id),
    CONSTRAINT fk_saved_activities_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_saved_activities_activity
        FOREIGN KEY (activity_id) REFERENCES activities(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 15. CALENDAR EVENTS
-- Manual calendar events + personal events not tied to an itinerary.
-- ------------------------------------------------------------
CREATE TABLE calendar_events (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    trip_id INT UNSIGNED DEFAULT NULL,
    itinerary_item_id INT UNSIGNED DEFAULT NULL,
    title VARCHAR(150) NOT NULL,
    event_type ENUM('trip','activity','personal','completed') NOT NULL DEFAULT 'personal',
    event_date DATE NOT NULL,
    start_time TIME DEFAULT NULL,
    end_time TIME DEFAULT NULL,
    notes TEXT DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_calendar_events_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_calendar_events_trip
        FOREIGN KEY (trip_id) REFERENCES trips(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_calendar_events_item
        FOREIGN KEY (itinerary_item_id) REFERENCES itinerary_items(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_calendar_user_date (user_id, event_date),
    INDEX idx_calendar_trip_date (trip_id, event_date)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 16. COMMUNITY POSTS
-- Experience sharing / public travel content.
-- ------------------------------------------------------------
CREATE TABLE community_posts (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    trip_id INT UNSIGNED DEFAULT NULL,
    city_id INT UNSIGNED DEFAULT NULL,
    activity_id INT UNSIGNED DEFAULT NULL,
    title VARCHAR(180) NOT NULL,
    content TEXT NOT NULL,
    image_url VARCHAR(500) DEFAULT NULL,
    visibility ENUM('public','private') NOT NULL DEFAULT 'public',
    status ENUM('published','draft','hidden') NOT NULL DEFAULT 'published',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_community_posts_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_community_posts_trip
        FOREIGN KEY (trip_id) REFERENCES trips(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_community_posts_city
        FOREIGN KEY (city_id) REFERENCES cities(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_community_posts_activity
        FOREIGN KEY (activity_id) REFERENCES activities(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_community_posts_feed (visibility, status, created_at),
    FULLTEXT KEY ft_community_posts_search (title, content)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 17. COMMUNITY LIKES
-- Included so the community can be extended without redesigning DB.
-- ------------------------------------------------------------
CREATE TABLE community_likes (
    post_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (post_id, user_id),
    CONSTRAINT fk_community_likes_post
        FOREIGN KEY (post_id) REFERENCES community_posts(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_community_likes_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 18. COMMUNITY COMMENTS
-- Included for future community interaction.
-- ------------------------------------------------------------
CREATE TABLE community_comments (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    post_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED NOT NULL,
    parent_comment_id INT UNSIGNED DEFAULT NULL,
    content TEXT NOT NULL,
    status ENUM('visible','hidden') NOT NULL DEFAULT 'visible',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_community_comments_post
        FOREIGN KEY (post_id) REFERENCES community_posts(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_community_comments_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_community_comments_parent
        FOREIGN KEY (parent_comment_id) REFERENCES community_comments(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_community_comments_post (post_id, created_at)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 19. NOTIFICATIONS
-- Supports the notification icon already present in the frontend.
-- ------------------------------------------------------------
CREATE TABLE notifications (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(150) NOT NULL,
    message VARCHAR(500) DEFAULT NULL,
    reference_type VARCHAR(50) DEFAULT NULL,
    reference_id INT UNSIGNED DEFAULT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notifications_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_notifications_user_read (user_id, is_read, created_at)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- SEED DATA: INTERESTS
-- ------------------------------------------------------------
INSERT INTO interests (name, icon, description) VALUES
('Food', '🍜', 'Local food, cafés, restaurants and food experiences'),
('History', '🏛️', 'Historical places, monuments and heritage'),
('Nature', '🌿', 'Nature, parks, forests and wildlife'),
('Shopping', '🛍️', 'Markets, malls and local shopping'),
('Nightlife', '🌃', 'Night markets, nightlife and evening experiences'),
('Photography', '📸', 'Scenic places and photography spots'),
('Beaches', '🏖️', 'Beaches, islands and coastal activities'),
('Art', '🎨', 'Museums, galleries and art experiences'),
('Adventure', '🧗', 'Outdoor and adventure activities'),
('Culture', '🎭', 'Local culture, traditions and experiences')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- ------------------------------------------------------------
-- SEED DATA: CITIES / DESTINATIONS
-- ------------------------------------------------------------
INSERT INTO cities
(name, country, country_code, region, description, image_url, rating, cost_index, popularity_score)
VALUES
('Tokyo', 'Japan', 'JP', 'Kanto', 'Modern city life, food, technology, anime and traditional culture.', 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=900&q=80', 4.9, 4, 98.00),
('Paris', 'France', 'FR', 'Ile-de-France', 'Art, history, architecture, food and classic Parisian experiences.', NULL, 4.8, 4, 96.00),
('Rome', 'Italy', 'IT', 'Lazio', 'Ancient history, architecture, food and iconic landmarks.', NULL, 4.8, 3, 94.00),
('Dubai', 'United Arab Emirates', 'AE', 'Dubai', 'Modern architecture, luxury, shopping and desert experiences.', NULL, 4.7, 5, 91.00),
('New York', 'United States', 'US', 'New York', 'City landmarks, food, culture, shopping and entertainment.', NULL, 4.7, 5, 92.00),
('Goa', 'India', 'IN', 'West India', 'Beaches, water sports, nightlife and relaxed coastal travel.', NULL, 4.7, 2, 89.00),
('Bali', 'Indonesia', 'ID', 'Bali', 'Beaches, temples, nature, cafés and island experiences.', 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&w=900&q=80', 4.9, 2, 93.00),
('Santorini', 'Greece', 'GR', 'South Aegean', 'Scenic island views, beaches, food and sunsets.', 'https://images.unsplash.com/photo-1518005020951-eccb494ad742?auto=format&fit=crop&w=900&q=80', 4.8, 4, 88.00),
('Kyoto', 'Japan', 'JP', 'Kansai', 'Temples, traditional streets, gardens and Japanese culture.', NULL, 4.8, 3, 90.00),
('Osaka', 'Japan', 'JP', 'Kansai', 'Food, nightlife, shopping and entertainment.', NULL, 4.7, 3, 86.00)
ON DUPLICATE KEY UPDATE
    description = VALUES(description),
    image_url = VALUES(image_url),
    rating = VALUES(rating),
    cost_index = VALUES(cost_index),
    popularity_score = VALUES(popularity_score);

-- ------------------------------------------------------------
-- SEED DATA: ACTIVITIES
-- ------------------------------------------------------------
INSERT INTO activities
(city_id, name, category, description, duration_minutes, estimated_cost, currency, rating, popularity_score)
SELECT c.id, a.name, a.category, a.description, a.duration_minutes, a.estimated_cost, 'INR', a.rating, a.popularity_score
FROM (
    SELECT 'Tokyo' city_name, 'Tokyo Tower' name, 'Sightseeing' category, 'Panoramic city views from one of Tokyo\'s most recognizable landmarks.' description, 120 duration_minutes, 2200.00 estimated_cost, 4.8 rating, 95.00 popularity_score
    UNION ALL SELECT 'Tokyo', 'Tsukiji Outer Market', 'Food', 'Explore Tokyo\'s famous food market and try local seafood.', 120, 1800.00, 4.7, 92.00
    UNION ALL SELECT 'Tokyo', 'Shibuya Crossing', 'Sightseeing', 'Experience one of Tokyo\'s busiest and most famous crossings.', 90, 0.00, 4.8, 94.00
    UNION ALL SELECT 'Tokyo', 'Fushimi Inari Shrine', 'Culture', 'Walk through the iconic torii gates and explore the shrine grounds.', 150, 0.00, 4.9, 96.00
    UNION ALL SELECT 'Tokyo', 'Gion Evening Walk', 'Culture', 'Explore traditional streets, shops and evening atmosphere.', 120, 500.00, 4.7, 88.00
    UNION ALL SELECT 'Paris', 'Louvre Museum', 'Art', 'Explore one of the world\'s most famous art museums.', 240, 2500.00, 4.9, 96.00
    UNION ALL SELECT 'Paris', 'Eiffel Tower', 'Sightseeing', 'Enjoy views of Paris from the city\'s most famous landmark.', 150, 3200.00, 4.8, 97.00
    UNION ALL SELECT 'Paris', 'Seine River Walk', 'Nature', 'Relax with a scenic walk along the Seine.', 90, 0.00, 4.7, 89.00
    UNION ALL SELECT 'Rome', 'Colosseum', 'History', 'Visit the iconic ancient Roman amphitheatre.', 180, 3000.00, 4.9, 97.00
    UNION ALL SELECT 'Rome', 'Vatican Museums', 'Art', 'Explore Vatican art collections and historic spaces.', 210, 3500.00, 4.8, 94.00
    UNION ALL SELECT 'Rome', 'Trevi Fountain', 'Sightseeing', 'Visit the famous fountain in Rome\'s historic centre.', 60, 0.00, 4.8, 92.00
    UNION ALL SELECT 'Goa', 'Baga Beach', 'Beaches', 'Relax on the beach and explore nearby cafés and activities.', 180, 0.00, 4.6, 90.00
    UNION ALL SELECT 'Goa', 'Water Sports', 'Adventure', 'Try popular water activities on the Goan coast.', 180, 2500.00, 4.5, 84.00
    UNION ALL SELECT 'Bali', 'Uluwatu Temple', 'Culture', 'Visit a cliffside temple with dramatic ocean views.', 150, 1000.00, 4.8, 92.00
    UNION ALL SELECT 'Bali', 'Tegallalang Rice Terraces', 'Nature', 'Explore Bali\'s famous rice terraces and surrounding scenery.', 150, 800.00, 4.7, 87.00
    UNION ALL SELECT 'Santorini', 'Oia Sunset', 'Sightseeing', 'Watch the sunset over the Aegean Sea from Oia.', 120, 0.00, 4.9, 95.00
    UNION ALL SELECT 'Kyoto', 'Kinkaku-ji', 'Culture', 'Visit Kyoto\'s famous Golden Pavilion.', 120, 1000.00, 4.8, 90.00
    UNION ALL SELECT 'Osaka', 'Dotonbori Food Walk', 'Food', 'Explore Osaka\'s famous food and entertainment district.', 150, 1800.00, 4.8, 91.00
) a
JOIN cities c ON c.name = a.city_name
WHERE NOT EXISTS (
    SELECT 1 FROM activities existing
    WHERE existing.city_id = c.id AND existing.name = a.name
);

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- Useful read-only views for frontend/backend queries
-- ============================================================

CREATE OR REPLACE VIEW v_trip_budget_summary AS
SELECT
    t.id AS trip_id,
    t.user_id,
    t.title,
    t.budget_amount,
    t.budget_currency,
    COALESCE(SUM(e.amount), 0) AS total_expenses,
    (t.budget_amount - COALESCE(SUM(e.amount), 0)) AS remaining_budget
FROM trips t
LEFT JOIN expenses e ON e.trip_id = t.id
GROUP BY t.id, t.user_id, t.title, t.budget_amount, t.budget_currency;

CREATE OR REPLACE VIEW v_city_popularity AS
SELECT
    c.id,
    c.name,
    c.country,
    c.rating,
    c.popularity_score,
    COUNT(DISTINCT ts.trip_id) AS trip_usage_count,
    COUNT(DISTINCT sc.user_id) AS saved_count
FROM cities c
LEFT JOIN trip_stops ts ON ts.city_id = c.id
LEFT JOIN saved_cities sc ON sc.city_id = c.id
GROUP BY c.id, c.name, c.country, c.rating, c.popularity_score;

CREATE OR REPLACE VIEW v_activity_popularity AS
SELECT
    a.id,
    a.name,
    a.category,
    c.name AS city_name,
    a.rating,
    a.popularity_score,
    COUNT(DISTINCT ii.id) AS itinerary_usage_count,
    COUNT(DISTINCT sa.user_id) AS saved_count
FROM activities a
LEFT JOIN cities c ON c.id = a.city_id
LEFT JOIN itinerary_items ii ON ii.activity_id = a.id
LEFT JOIN saved_activities sa ON sa.activity_id = a.id
GROUP BY a.id, a.name, a.category, c.name, a.rating, a.popularity_score;

-- ============================================================
-- End of GlobeTrotter database schema
-- ============================================================
