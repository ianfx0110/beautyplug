-- =====================================================
-- BEAUTYPLUG DATABASE SCHEMA
-- MySQL Database Design for Beauty Service Marketplace
-- =====================================================

-- Drop existing database (if exists) and create fresh
DROP DATABASE IF EXISTS beautyplug;
CREATE DATABASE beautyplug CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE beautyplug;

-- =====================================================
-- 1. USERS & AUTHENTICATION
-- =====================================================


CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    user_type ENUM('client', 'provider', 'admin') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_email (email),
    INDEX idx_user_type (user_type)
);

-- =====================================================
-- 2. SERVICE PROVIDERS
-- =====================================================

CREATE TABLE service_providers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL UNIQUE,
    
    -- Basic Info
    business_name VARCHAR(255) NOT NULL,
    bio TEXT,
    profile_picture_url VARCHAR(500),
    
    -- Service Category (what they do)
    primary_category ENUM(
        'barber', 'hairstylist', 'manicure', 'pedicure', 
        'massage', 'skincare', 'makeup', 'waxing', 'nail_art', 'other'
    ) NOT NULL,
    
    -- Location
    home_location_address VARCHAR(500),
    home_location_latitude DECIMAL(10, 8),
    home_location_longitude DECIMAL(11, 8),
    
    -- Vetting Status
    approval_status ENUM('pending', 'under_review', 'approved', 'rejected', 'suspended') DEFAULT 'pending',
    approval_notes TEXT,
    approved_by INT,  -- Admin user ID
    approved_at TIMESTAMP NULL,
    rejected_at TIMESTAMP NULL,
    rejection_reason TEXT,
    
    -- Profile Completion
    profile_completion_percentage INT DEFAULT 0,  -- 0-100
    
    -- Soft Delete
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP NULL,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_approval_status (approval_status),
    INDEX idx_primary_category (primary_category),
    INDEX idx_is_deleted (is_deleted),
    INDEX idx_location (home_location_latitude, home_location_longitude)
);

-- =====================================================
-- 3. PROVIDER DOCUMENTS & VERIFICATION
-- =====================================================

CREATE TABLE provider_documents (
    id INT PRIMARY KEY AUTO_INCREMENT,
    provider_id INT NOT NULL,
    
    document_type ENUM('id_verification', 'certification', 'portfolio', 'license') NOT NULL,
    document_url VARCHAR(500) NOT NULL,
    document_name VARCHAR(255),
    
    -- Verification
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by INT,  -- Admin user ID
    verified_at TIMESTAMP NULL,
    verification_notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (provider_id) REFERENCES service_providers(id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_provider_id (provider_id),
    INDEX idx_document_type (document_type)
);

-- =====================================================
-- 4. SERVICES OFFERED
-- =====================================================

CREATE TABLE services (
    id INT PRIMARY KEY AUTO_INCREMENT,
    provider_id INT NOT NULL,
    
    service_name VARCHAR(255) NOT NULL,
    service_description TEXT,
    
    -- Pricing & Duration
    price DECIMAL(10, 2) NOT NULL,
    duration_minutes INT NOT NULL,  -- How long the service takes
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (provider_id) REFERENCES service_providers(id) ON DELETE CASCADE,
    
    INDEX idx_provider_id (provider_id),
    INDEX idx_is_active (is_active)
);

-- =====================================================
-- 5. CLIENTS
-- =====================================================

CREATE TABLE clients (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL UNIQUE,
    
    profile_picture_url VARCHAR(500),
    bio TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    
    INDEX idx_user_id (user_id)
);

-- =====================================================
-- 6. BOOKINGS & APPOINTMENTS
-- =====================================================

CREATE TABLE bookings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    client_id INT NOT NULL,
    service_id INT NOT NULL,
    provider_id INT NOT NULL,
    
    -- Service Delivery Details
    service_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,  -- Calculated based on service duration
    
    -- Location for this booking
    service_location_address VARCHAR(500) NOT NULL,
    service_location_latitude DECIMAL(10, 8),
    service_location_longitude DECIMAL(11, 8),
    
    -- Is it at provider's shop or client location?
    is_at_provider_location BOOLEAN DEFAULT FALSE,
    
    -- Booking Status
    booking_status ENUM(
        'requested',      -- Client requested, awaiting provider confirmation
        'confirmed',      -- Provider confirmed
        'completed',      -- Service was completed
        'cancelled',      -- Booking was cancelled
        'no_show'         -- Client didn't show up
    ) DEFAULT 'requested',
    
    -- Cancellation Info
    cancelled_by ENUM('client', 'provider', 'admin') NULL,
    cancellation_reason TEXT,
    cancelled_at TIMESTAMP NULL,
    
    -- Pricing & Payment
    service_price DECIMAL(10, 2) NOT NULL,  -- Price at time of booking
    platform_commission DECIMAL(10, 2),      -- 15% of service_price
    provider_earnings DECIMAL(10, 2),        -- service_price - platform_commission
    
    -- Notes
    client_notes TEXT,
    provider_notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE RESTRICT,
    FOREIGN KEY (provider_id) REFERENCES service_providers(id) ON DELETE RESTRICT,
    
    INDEX idx_client_id (client_id),
    INDEX idx_provider_id (provider_id),
    INDEX idx_service_date (service_date),
    INDEX idx_booking_status (booking_status),
    INDEX idx_composite (provider_id, service_date, booking_status)
);

-- =====================================================
-- 7. PAYMENTS & TRANSACTIONS
-- =====================================================

CREATE TABLE transactions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    booking_id INT NOT NULL UNIQUE,
    
    -- Payment Details
    amount DECIMAL(10, 2) NOT NULL,
    platform_commission DECIMAL(10, 2) NOT NULL,
    provider_payout DECIMAL(10, 2) NOT NULL,
    
    -- Payment Method & Status
    payment_method ENUM('card', 'wallet', 'bank_transfer') NOT NULL,
    payment_status ENUM('pending', 'paid', 'refunded', 'failed') DEFAULT 'pending',
    
    -- Payment Timing
    payment_type ENUM('upfront', 'on_demand') NOT NULL,  -- User's choice at booking
    
    -- Transaction IDs
    transaction_reference VARCHAR(255),  -- Payment gateway reference
    
    -- Refund Info
    refund_amount DECIMAL(10, 2) DEFAULT 0,
    refund_reason TEXT,
    refund_status ENUM('none', 'requested', 'approved', 'completed') DEFAULT 'none',
    refund_requested_at TIMESTAMP NULL,
    refund_completed_at TIMESTAMP NULL,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    
    INDEX idx_booking_id (booking_id),
    INDEX idx_payment_status (payment_status),
    INDEX idx_refund_status (refund_status)
);

-- =====================================================
-- 8. RATINGS & REVIEWS
-- =====================================================

CREATE TABLE ratings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    booking_id INT NOT NULL UNIQUE,
    client_id INT NOT NULL,
    provider_id INT NOT NULL,
    
    -- Rating (1-5 stars)
    rating_stars INT NOT NULL CHECK (rating_stars >= 1 AND rating_stars <= 5),
    review_text TEXT,
    
    -- Review Categories
    cleanliness_rating INT CHECK (cleanliness_rating IS NULL OR (cleanliness_rating >= 1 AND cleanliness_rating <= 5)),
    professionalism_rating INT CHECK (professionalism_rating IS NULL OR (professionalism_rating >= 1 AND professionalism_rating <= 5)),
    punctuality_rating INT CHECK (punctuality_rating IS NULL OR (punctuality_rating >= 1 AND punctuality_rating <= 5)),
    quality_rating INT CHECK (quality_rating IS NULL OR (quality_rating >= 1 AND quality_rating <= 5)),
    
    -- Photo Evidence (optional)
    photo_url VARCHAR(500),
    
    -- Response from Provider
    provider_response TEXT,
    provider_responded_at TIMESTAMP NULL,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
    FOREIGN KEY (provider_id) REFERENCES service_providers(id) ON DELETE CASCADE,
    
    INDEX idx_provider_id (provider_id),
    INDEX idx_client_id (client_id),
    INDEX idx_rating_stars (rating_stars)
);

-- =====================================================
-- 9. PROVIDER AVAILABILITY / SLOTS
-- =====================================================

CREATE TABLE provider_availability_slots (
    id INT PRIMARY KEY AUTO_INCREMENT,
    provider_id INT NOT NULL,
    
    -- Date & Time
    available_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    
    -- Status (can be booked, or marked as unavailable)
    is_available BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (provider_id) REFERENCES service_providers(id) ON DELETE CASCADE,
    
    INDEX idx_provider_date (provider_id, available_date),
    INDEX idx_is_available (is_available)
);

-- =====================================================
-- 10. PROVIDER RATINGS SUMMARY
-- =====================================================

CREATE TABLE provider_rating_summary (
    id INT PRIMARY KEY AUTO_INCREMENT,
    provider_id INT NOT NULL UNIQUE,
    
    -- Aggregate Ratings
    total_ratings INT DEFAULT 0,
    average_rating DECIMAL(3, 2) DEFAULT 0,
    
    -- Category Averages
    avg_cleanliness DECIMAL(3, 2),
    avg_professionalism DECIMAL(3, 2),
    avg_punctuality DECIMAL(3, 2),
    avg_quality DECIMAL(3, 2),
    
    -- Rating Distribution
    rating_5_stars INT DEFAULT 0,
    rating_4_stars INT DEFAULT 0,
    rating_3_stars INT DEFAULT 0,
    rating_2_stars INT DEFAULT 0,
    rating_1_star INT DEFAULT 0,
    
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (provider_id) REFERENCES service_providers(id) ON DELETE CASCADE,
    
    INDEX idx_average_rating (average_rating)
);

-- =====================================================
-- 11. FAVORITES / WISHLIST
-- =====================================================

CREATE TABLE client_favorites (
    id INT PRIMARY KEY AUTO_INCREMENT,
    client_id INT NOT NULL,
    provider_id INT NOT NULL,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE,
    FOREIGN KEY (provider_id) REFERENCES service_providers(id) ON DELETE CASCADE,
    
    UNIQUE KEY unique_favorite (client_id, provider_id),
    INDEX idx_client_id (client_id)
);

-- =====================================================
-- 12. AUDIT LOG (Admin Actions)
-- =====================================================

CREATE TABLE audit_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    admin_id INT,
    
    action_type ENUM(
        'provider_approved',
        'provider_rejected',
        'provider_suspended',
        'document_verified',
        'dispute_resolved',
        'system_update'
    ) NOT NULL,
    
    target_entity_type ENUM('provider', 'booking', 'document', 'user', 'rating') NOT NULL,
    target_entity_id INT,
    
    description TEXT NOT NULL,
    old_values JSON,  -- JSON of what changed
    new_values JSON,
    
    ip_address VARCHAR(45),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_admin_id (admin_id),
    INDEX idx_action_type (action_type),
    INDEX idx_created_at (created_at)
);

-- =====================================================
-- 13. DISPUTES & COMPLAINTS
-- =====================================================

CREATE TABLE disputes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    booking_id INT NOT NULL,
    reported_by INT NOT NULL,  -- user_id (client or provider)
    
    dispute_type ENUM(
        'service_not_rendered',
        'quality_issue',
        'no_show_client',
        'no_show_provider',
        'price_dispute',
        'other'
    ) NOT NULL,
    
    description TEXT NOT NULL,
    evidence_url VARCHAR(500),  -- Photo/document
    
    -- Resolution
    status ENUM('open', 'under_review', 'resolved', 'closed') DEFAULT 'open',
    resolution_notes TEXT,
    resolved_by INT,  -- Admin user_id
    resolved_at TIMESTAMP NULL,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    FOREIGN KEY (reported_by) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (resolved_by) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_booking_id (booking_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);

-- =====================================================
-- 14. NOTIFICATIONS
-- =====================================================

CREATE TABLE notifications (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    
    notification_type ENUM(
        'booking_request',
        'booking_confirmed',
        'booking_completed',
        'booking_cancelled',
        'rating_received',
        'provider_approved',
        'payment_received',
        'dispute_opened'
    ) NOT NULL,
    
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    related_entity_id INT,  -- booking_id, provider_id, etc
    
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP NULL,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    
    INDEX idx_user_id (user_id),
    INDEX idx_is_read (is_read),
    INDEX idx_created_at (created_at)
);

-- =====================================================
-- 15. ADMIN SETTINGS
-- =====================================================

CREATE TABLE admin_settings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    
    setting_key VARCHAR(255) NOT NULL UNIQUE,
    setting_value VARCHAR(500),
    setting_type ENUM('string', 'number', 'boolean', 'json') DEFAULT 'string',
    
    description TEXT,
    
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_setting_key (setting_key)
);

-- =====================================================
-- SAMPLE DATA FOR TESTING
-- =====================================================

-- Insert admin user
INSERT INTO users (email, phone, first_name, last_name, password_hash, user_type) 
VALUES ('admin@beautyplug.com', '+1234567890', 'Admin', 'User', 'hashed_password_here', 'admin');

-- Insert sample clients
INSERT INTO users (email, phone, first_name, last_name, password_hash, user_type) VALUES
('alice@example.com', '+1111111111', 'Alice', 'Johnson', 'hashed_pwd_1', 'client'),
('bob@example.com', '+1111111112', 'Bob', 'Smith', 'hashed_pwd_2', 'client');

INSERT INTO clients (user_id) VALUES
((SELECT id FROM users WHERE email = 'alice@example.com')),
((SELECT id FROM users WHERE email = 'bob@example.com'));

-- Insert sample provider
INSERT INTO users (email, phone, first_name, last_name, password_hash, user_type) VALUES
('barber@example.com', '+1222222222', 'John', 'Doe', 'hashed_pwd_3', 'provider');

INSERT INTO service_providers (
    user_id, business_name, bio, primary_category, 
    home_location_address, approval_status, profile_completion_percentage
) VALUES (
    (SELECT id FROM users WHERE email = 'barber@example.com'),
    'Johns Barbershop',
    'Professional barber with 10 years of experience',
    'barber',
    '123 Main Street, Downtown',
    'approved',
    100
);

-- Insert sample services
INSERT INTO services (provider_id, service_name, service_description, price, duration_minutes) VALUES
((SELECT id FROM service_providers LIMIT 1), 'Basic Haircut', 'Professional haircut', 25.00, 30),
((SELECT id FROM service_providers LIMIT 1), 'Beard Trim', 'Professional beard trim', 15.00, 20),
((SELECT id FROM service_providers LIMIT 1), 'Full Grooming', 'Haircut + Beard trim + Line up', 45.00, 60);

-- =====================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================

-- View: Active Approved Providers
CREATE VIEW active_approved_providers AS
SELECT 
    sp.id,
    sp.business_name,
    u.first_name,
    u.last_name,
    u.email,
    sp.primary_category,
    prs.average_rating,
    prs.total_ratings,
    sp.home_location_address
FROM service_providers sp
JOIN users u ON sp.user_id = u.id
LEFT JOIN provider_rating_summary prs ON sp.id = prs.provider_id
WHERE sp.approval_status = 'approved' AND sp.is_deleted = FALSE;

-- View: Pending Approvals
CREATE VIEW pending_approvals AS
SELECT 
    sp.id,
    u.first_name,
    u.last_name,
    u.email,
    sp.business_name,
    sp.primary_category,
    sp.profile_completion_percentage,
    sp.created_at,
    COUNT(pd.id) as document_count
FROM service_providers sp
JOIN users u ON sp.user_id = u.id
LEFT JOIN provider_documents pd ON sp.id = pd.provider_id
WHERE sp.approval_status = 'pending'
GROUP BY sp.id;

-- View: Booking Status Overview
CREATE VIEW booking_overview AS
SELECT 
    b.id as booking_id,
    c.user_id as client_id,
    sp.business_name,
    s.service_name,
    b.service_date,
    b.start_time,
    b.booking_status,
    b.service_price,
    b.platform_commission,
    b.provider_earnings
FROM bookings b
JOIN clients c ON b.client_id = c.id
JOIN service_providers sp ON b.provider_id = sp.id
JOIN services s ON b.service_id = s.id;

-- View: Provider Revenue Summary
CREATE VIEW provider_revenue_summary AS
SELECT 
    sp.id,
    sp.business_name,
    COUNT(b.id) as total_bookings,
    SUM(CASE WHEN b.booking_status = 'completed' THEN 1 ELSE 0 END) as completed_bookings,
    SUM(CASE WHEN b.booking_status = 'completed' THEN b.provider_earnings ELSE 0 END) as total_earnings
FROM service_providers sp
LEFT JOIN bookings b ON sp.id = b.provider_id
GROUP BY sp.id;

-- =====================================================
-- END OF SCHEMA
-- =====================================================
