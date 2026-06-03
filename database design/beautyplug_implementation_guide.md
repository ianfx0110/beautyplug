# BeautyPlug Database - Entity Relationship Diagram & Implementation Guide

## ASCII Entity Relationship Diagram

```
╔════════════════════════════════════════════════════════════════════════════════════════════════╗
║                          BEAUTYPLUG DATABASE ARCHITECTURE                                      ║
╚════════════════════════════════════════════════════════════════════════════════════════════════╝

┌──────────────────────┐
│      USERS           │
├──────────────────────┤
│ PK: id               │
│    email (UNIQUE)    │
│    phone (UNIQUE)    │
│    first_name        │
│    last_name         │
│    password_hash     │
│    user_type         │
│    created_at        │
│    updated_at        │
└──────────┬───────────┘
           │
    ┌──────┴──────┬─────────────────┬──────────────────┐
    │             │                 │                  │
    │(1)          │(1)              │(1)               │(*)
    ▼             ▼                 ▼                  ▼
┌──────────────────────┐  ┌──────────────┐   ┌────────────────────┐
│ SERVICE_PROVIDERS    │  │   CLIENTS    │   │  AUDIT_LOGS        │
├──────────────────────┤  ├──────────────┤   ├────────────────────┤
│ PK: id               │  │ PK: id       │   │ PK: id             │
│ FK: user_id          │  │ FK: user_id  │   │ FK: admin_id       │
│    business_name     │  │    profile_  │   │    action_type     │
│    bio               │  │    picture_  │   │    target_entity_  │
│    primary_category  │  │    url       │   │    type            │
│    home_location_*   │  │    bio       │   │    description     │
│    approval_status   │  └──────────────┘   │    old_values      │
│    approval_notes    │                     │    new_values      │
│    approved_by (FK)  │                     │    ip_address      │
│    approved_at       │                     │    created_at      │
│    is_deleted        │                     └────────────────────┘
│    profile_completion│
│    _percentage       │
└──────────┬──────────┘
           │
    ┌──────┴──────┬──────────────────┬──────────────────┬──────────────┐
    │             │                  │                  │              │
    │(1)          │(1)               │(1)               │(1)           │(*)
    ▼             ▼                  ▼                  ▼              ▼
┌──────────────┐ ┌─────────────┐ ┌──────────────────┐ ┌──────────────────┐ ┌───────────────┐
│   SERVICES   │ │   PROVIDER_ │ │  PROVIDER_RATING │ │ PROVIDER_        │ │ CLIENT_       │
├──────────────┤ │   DOCUMENTS │ │  _SUMMARY        │ │ AVAILABILITY_    │ │ FAVORITES     │
│ PK: id       │ ├─────────────┤ ├──────────────────┤ │ SLOTS            │ ├───────────────┤
│ FK: provider │ │ PK: id      │ │ PK: id           │ ├──────────────────┤ │ PK: id        │
│    _id       │ │ FK: provider│ │ FK: provider_id  │ │ PK: id           │ │ FK: client_id │
│    service_  │ │    _id      │ │    total_ratings │ │ FK: provider_id  │ │ FK: provider_ │
│    name      │ │    document │ │    average_rating│ │    available_    │ │    _id        │
│    service_  │ │    _type    │ │    avg_clean-    │ │    date          │ │ UNIQUE(client │
│    description│ │    document │ │    liness        │ │    start_time    │ │ _id,provider_ │
│    price     │ │    _url     │ │    avg_prof-     │ │    end_time      │ │ _id)          │
│    duration_ │ │    is_verified││    essional      │ │    is_available  │ │ created_at    │
│    minutes   │ │    verified_│ │    avg_punct-    │ │ created_at       │ └───────────────┘
│    is_active │ │    by       │ │    uality        │ └──────────────────┘
│ created_at   │ │    verified │ │    avg_quality   │
│ updated_at   │ │    _at      │ │    rating_*_     │
└──────────────┘ │    created_ │ │    stars         │
                 │    at       │ │    last_updated  │
                 │    updated_ │ └──────────────────┘
                 │    at       │
                 └─────────────┘
                        │
                        │(*)
                        ▼
    ┌───────────────────────────────────────┐
    │            BOOKINGS (CORE)            │
    ├───────────────────────────────────────┤
    │ PK: id                                │
    │ FK: client_id ────────────────────┐   │
    │ FK: service_id                    │   │
    │ FK: provider_id                   │   │
    │    service_date                   │   │
    │    start_time                     │   │
    │    end_time                       │   │
    │    service_location_address       │   │
    │    service_location_lat/long      │   │
    │    is_at_provider_location        │   │
    │    booking_status                 │   │
    │    cancelled_by                   │   │
    │    cancellation_reason            │   │
    │    service_price                  │   │
    │    platform_commission            │   │
    │    provider_earnings              │   │
    │    client_notes                   │   │
    │    provider_notes                 │   │
    │    created_at                     │   │
    │    updated_at                     │   │
    └──────────┬────────────────────────┘   │
               │                             │
        ┌──────┴───────┬─────────────────┐   │
        │              │                 │   │
        │(1)           │(1)              │(1)│
        ▼              ▼                 ▼   │
    ┌─────────────┐ ┌─────────────┐  ┌────────────────┐
    │TRANSACTIONS │ │   RATINGS   │  │   DISPUTES     │
    ├─────────────┤ ├─────────────┤  ├────────────────┤
    │ PK: id      │ │ PK: id      │  │ PK: id         │
    │ FK: booking │ │ FK: booking │  │ FK: booking_id │
    │    _id      │ │    _id      │  │ FK: reported_by│
    │    amount   │ │ FK: client_ │  │    dispute_type│
    │    platform │ │    id       │  │    description │
    │    _commission│ │ FK: provider│  │    evidence_url│
    │    provider │ │    _id      │  │    status      │
    │    _payout  │ │    rating_  │  │    resolution_ │
    │    payment_ │ │    stars    │  │    notes       │
    │    method   │ │    review_  │  │    resolved_by │
    │    payment_ │ │    text     │  │    resolved_at │
    │    status   │ │    cleanli- │  │ created_at     │
    │    payment_ │ │    ness_    │  │ updated_at     │
    │    type     │ │    rating   │  └────────────────┘
    │    transaction│ │    professional│
    │    _reference│ │    _rating  │
    │    refund_  │ │    punctuality│
    │    amount   │ │    _rating  │
    │    refund_  │ │    quality_ │
    │    reason   │ │    rating   │
    │    refund_  │ │    photo_url│
    │    status   │ │    provider │
    │    refund_  │ │    _response│
    │    requested│ │    provider │
    │    _at      │ │    _responded│
    │    refund_  │ │    _at      │
    │    completed│ │ created_at  │
    │    _at      │ │ updated_at  │
    │ created_at  │ └─────────────┘
    │ updated_at  │
    └─────────────┘

                         ┌──────────────────────┐
                         │  NOTIFICATIONS       │
                         ├──────────────────────┤
                         │ PK: id               │
                         │ FK: user_id          │
                         │    notification_type │
                         │    title             │
                         │    message           │
                         │    related_entity_id │
                         │    is_read           │
                         │    read_at           │
                         │    created_at        │
                         └──────────────────────┘

                         ┌──────────────────────┐
                         │  ADMIN_SETTINGS      │
                         ├──────────────────────┤
                         │ PK: id               │
                         │    setting_key (UQ)  │
                         │    setting_value     │
                         │    setting_type      │
                         │    description       │
                         │    updated_at        │
                         └──────────────────────┘

FK = Foreign Key (references another table)
PK = Primary Key (unique identifier)
UQ = Unique constraint
(*) = One-to-Many relationship
(1) = One-to-One relationship
```

---

## Relationship Summary

| From Table | To Table | Type | Meaning |
|---|---|---|---|
| users | service_providers | 1:1 | Each provider is one user |
| users | clients | 1:1 | Each client is one user |
| users | audit_logs | 1:N | One admin performs many actions |
| service_providers | services | 1:N | One provider offers many services |
| service_providers | provider_documents | 1:N | One provider uploads many documents |
| service_providers | provider_rating_summary | 1:1 | Each provider has one rating summary |
| service_providers | provider_availability_slots | 1:N | One provider creates many availability slots |
| service_providers | bookings | 1:N | One provider receives many bookings |
| service_providers | client_favorites | 1:N | One provider can be favorited by many clients |
| clients | bookings | 1:N | One client makes many bookings |
| clients | client_favorites | 1:N | One client can favorite many providers |
| services | bookings | 1:N | One service can be booked many times |
| bookings | transactions | 1:1 | Each booking has one transaction |
| bookings | ratings | 1:1 | Each booking has one rating (after completion) |
| bookings | disputes | 1:N | One booking can have multiple disputes (rare) |

---

## Column Data Types Reference

### Numeric Types
```
TINYINT       -128 to 127 (1 byte) - use for BOOLEAN flags
SMALLINT      -32,768 to 32,767 (2 bytes)
INT           -2.1B to 2.1B (4 bytes) - use for IDs
BIGINT        -9.2E18 to 9.2E18 (8 bytes) - for very large numbers
DECIMAL(10,2) Fixed-point, 10 digits total, 2 after decimal - USE FOR MONEY
FLOAT         Floating-point (4 bytes) - avoid for money
DOUBLE        Floating-point (8 bytes) - avoid for money
```

**BeautyPlug Usage**:
- `INT` for all IDs (id, user_id, provider_id, etc.)
- `DECIMAL(10, 2)` for prices, commissions, payouts, transaction amounts
- `INT` for profile_completion_percentage (0-100)
- `INT` for duration_minutes (30, 45, 60, etc.)

### String Types
```
CHAR(n)       Fixed-length string, padded - avoid
VARCHAR(n)    Variable-length string - use for most text
TEXT          Large text, up to 64KB - use for bio, notes, descriptions
LONGTEXT      Very large text, up to 4GB - avoid (rarely needed)
ENUM('a','b') Predefined list of values - use for status fields
```

**BeautyPlug Usage**:
- `VARCHAR(255)` for emails, names, business names, URLs
- `VARCHAR(500)` for longer URLs and addresses
- `TEXT` for bio, review text, notes, descriptions
- `ENUM` for approval_status, booking_status, user_type, etc.
- `VARCHAR(20)` for phone numbers (international format)
- `VARCHAR(45)` for IPv4 (15 chars) and IPv6 (39 chars) addresses

### DateTime Types
```
DATE          YYYY-MM-DD (3 bytes) - dates only
TIME          HH:MM:SS (3 bytes) - times only
DATETIME      YYYY-MM-DD HH:MM:SS (8 bytes)
TIMESTAMP     YYYY-MM-DD HH:MM:SS (4 bytes) + timezone aware
YEAR          YYYY (1 byte) - rarely used
```

**BeautyPlug Usage**:
- `DATE` for service_date, available_date (just the date, no time)
- `TIME` for start_time, end_time (just the time, no date)
- `TIMESTAMP DEFAULT CURRENT_TIMESTAMP` for created_at
- `TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` for updated_at
- `TIMESTAMP NULL` for conditional timestamps (approved_at, rejected_at, verified_at)

### Geographic Types
```
DECIMAL(10,8)  Latitude (-90 to 90) - store as -87.1234567
DECIMAL(11,8)  Longitude (-180 to 180) - store as -122.1234567

Alternative (MySQL 5.7+):
POINT()        ST_GeomFromText('POINT(lat lng)')
GEOMETRY       For complex geographic queries
```

**BeautyPlug Usage**:
```sql
-- Store coordinates
home_location_latitude DECIMAL(10, 8)    -- e.g., 37.7749
home_location_longitude DECIMAL(11, 8)   -- e.g., -122.4194

-- Query nearby providers (within 5km)
SELECT * FROM service_providers
WHERE ST_Distance_Sphere(
  POINT(home_location_longitude, home_location_latitude),
  POINT(-122.4194, 37.7749)  -- client's location
) <= 5000;  -- meters
```

### JSON Type
```
JSON           Store JSON objects - useful for flexible data
```

**BeautyPlug Usage**:
```sql
-- Audit log changes
old_values JSON   -- e.g., {"approval_status":"pending"}
new_values JSON   -- e.g., {"approval_status":"approved"}

-- Admin settings
admin_settings.setting_value = '["card", "wallet", "bank_transfer"]'
admin_settings.setting_type = 'json'
```

---

## Recommended Column Specifications by Purpose

### IDs (Primary & Foreign Keys)
```sql
id INT PRIMARY KEY AUTO_INCREMENT
user_id INT NOT NULL
provider_id INT
approved_by INT  -- Can be NULL if deleted
```

### Emails & Usernames
```sql
email VARCHAR(255) NOT NULL UNIQUE
phone VARCHAR(20) NOT NULL UNIQUE
```

### Names & Titles
```sql
first_name VARCHAR(100) NOT NULL
last_name VARCHAR(100) NOT NULL
business_name VARCHAR(255) NOT NULL
service_name VARCHAR(255) NOT NULL
```

### Long Text (Bio, Reviews, Notes)
```sql
bio TEXT
review_text TEXT
description TEXT
client_notes TEXT
provider_notes TEXT
cancellation_reason TEXT
resolution_notes TEXT
```

### Money (Prices, Commissions, Payouts)
```sql
price DECIMAL(10, 2) NOT NULL          -- $9,999.99 max
service_price DECIMAL(10, 2) NOT NULL
platform_commission DECIMAL(10, 2)
provider_earnings DECIMAL(10, 2)
refund_amount DECIMAL(10, 2) DEFAULT 0
```

### URLs & File Paths
```sql
profile_picture_url VARCHAR(500)
document_url VARCHAR(500)
photo_url VARCHAR(500)
evidence_url VARCHAR(500)
```

### Addresses
```sql
home_location_address VARCHAR(500)
service_location_address VARCHAR(500)
```

### Percentages
```sql
profile_completion_percentage INT DEFAULT 0  -- 0-100
```

### Status/State (Use ENUM)
```sql
user_type ENUM('client', 'provider', 'admin')
approval_status ENUM('pending', 'under_review', 'approved', 'rejected', 'suspended')
booking_status ENUM('requested', 'confirmed', 'completed', 'cancelled', 'no_show')
payment_status ENUM('pending', 'paid', 'refunded', 'failed')
```

### Boolean Flags (Use TINYINT or BOOLEAN)
```sql
is_active BOOLEAN DEFAULT TRUE
is_deleted BOOLEAN DEFAULT FALSE
is_verified BOOLEAN DEFAULT FALSE
is_at_provider_location BOOLEAN DEFAULT FALSE
is_read BOOLEAN DEFAULT FALSE
```

### Ratings (1-5 Stars)
```sql
rating_stars INT NOT NULL CHECK (rating_stars >= 1 AND rating_stars <= 5)
cleanliness_rating INT CHECK (cleanliness_rating IS NULL OR (cleanliness_rating >= 1 AND cleanliness_rating <= 5))
```

### Timestamps
```sql
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
approved_at TIMESTAMP NULL  -- Optional
deleted_at TIMESTAMP NULL   -- For soft deletes
read_at TIMESTAMP NULL      -- For when something was read
```

---

## Index Strategy

### Indexes on Foreign Keys
Always index FKs for JOIN performance:
```sql
ALTER TABLE bookings ADD INDEX idx_client_id (client_id);
ALTER TABLE bookings ADD INDEX idx_service_id (service_id);
ALTER TABLE bookings ADD INDEX idx_provider_id (provider_id);
```

### Indexes on Frequently Searched Columns
```sql
ALTER TABLE users ADD INDEX idx_email (email);
ALTER TABLE service_providers ADD INDEX idx_approval_status (approval_status);
ALTER TABLE provider_rating_summary ADD INDEX idx_average_rating (average_rating DESC);
```

### Composite Indexes for Complex Queries
```sql
-- Query: "Show all confirmed bookings for provider X on date Y"
ALTER TABLE bookings ADD INDEX idx_provider_date_status 
  (provider_id, service_date, booking_status);

-- Query: "Show available slots for provider X on date Y"
ALTER TABLE provider_availability_slots 
  ADD INDEX idx_provider_date (provider_id, available_date);
```

### Partial Indexes (MySQL 5.7+)
```sql
-- Only index active services to save space
ALTER TABLE services ADD INDEX idx_active_services (is_active) 
  WHERE is_active = TRUE;
```

### Full-Text Indexes for Search
```sql
-- Search services by name/description
ALTER TABLE services ADD FULLTEXT INDEX ft_search (service_name, service_description);

-- Query: Find haircut services
SELECT * FROM services 
WHERE MATCH(service_name, service_description) AGAINST('haircut' IN BOOLEAN MODE);
```

---

## Sample Data Insertion Scripts

### 1. Create Admin User
```sql
INSERT INTO users (email, phone, first_name, last_name, password_hash, user_type)
VALUES (
  'admin@beautyplug.com',
  '+1234567890',
  'Admin',
  'User',
  SHA2('secure_password', 256),
  'admin'
);
```

### 2. Create Provider
```sql
-- Create user account
INSERT INTO users (email, phone, first_name, last_name, password_hash, user_type)
VALUES (
  'john@barber.com',
  '+1555555555',
  'John',
  'Doe',
  SHA2('provider_password', 256),
  'provider'
);

-- Create provider profile
INSERT INTO service_providers (
  user_id, business_name, bio, primary_category, 
  home_location_address, home_location_latitude, 
  home_location_longitude, approval_status
)
VALUES (
  LAST_INSERT_ID(),
  'John\'s Barbershop',
  'Professional barber with 10 years experience',
  'barber',
  '123 Main Street, San Francisco, CA 94102',
  37.7749,
  -122.4194,
  'pending'
);
```

### 3. Create Service
```sql
INSERT INTO services (provider_id, service_name, service_description, price, duration_minutes)
SELECT 
  id as provider_id,
  'Classic Haircut',
  'Professional haircut with beard trim',
  25.00,
  30
FROM service_providers 
WHERE business_name = 'John\'s Barbershop'
LIMIT 1;
```

### 4. Create Booking
```sql
INSERT INTO bookings (
  client_id, service_id, provider_id, service_date, 
  start_time, end_time, service_location_address, 
  is_at_provider_location, booking_status, service_price, 
  platform_commission, provider_earnings
)
SELECT 
  c.id as client_id,
  s.id as service_id,
  s.provider_id,
  '2025-04-25' as service_date,
  '14:00:00' as start_time,
  '14:30:00' as end_time,
  '456 Market St, San Francisco, CA' as service_location_address,
  FALSE as is_at_provider_location,
  'requested' as booking_status,
  s.price as service_price,
  ROUND(s.price * 0.15, 2) as platform_commission,
  ROUND(s.price * 0.85, 2) as provider_earnings
FROM clients c, services s
WHERE c.user_id = (SELECT id FROM users WHERE email = 'alice@example.com')
  AND s.provider_id = (SELECT id FROM service_providers WHERE business_name = 'John\'s Barbershop')
LIMIT 1;
```

### 5. Process Payment
```sql
INSERT INTO transactions (
  booking_id, amount, platform_commission, provider_payout, 
  payment_method, payment_status, payment_type, transaction_reference
)
SELECT 
  b.id as booking_id,
  b.service_price as amount,
  b.platform_commission,
  b.provider_earnings as provider_payout,
  'card' as payment_method,
  'paid' as payment_status,
  'upfront' as payment_type,
  CONCAT('TXN_', UUID()) as transaction_reference
FROM bookings b
WHERE b.id = (SELECT MAX(id) FROM bookings)
LIMIT 1;
```

### 6. Leave Rating
```sql
INSERT INTO ratings (
  booking_id, client_id, provider_id, rating_stars, 
  review_text, cleanliness_rating, professionalism_rating, 
  punctuality_rating, quality_rating
)
SELECT 
  b.id as booking_id,
  b.client_id,
  b.provider_id,
  5 as rating_stars,
  'Excellent service! John was professional and friendly.' as review_text,
  5 as cleanliness_rating,
  5 as professionalism_rating,
  5 as punctuality_rating,
  5 as quality_rating
FROM bookings b
WHERE b.booking_status = 'completed'
ORDER BY b.updated_at DESC
LIMIT 1;
```

---

## Performance Tuning Tips

### 1. Analyze Query Performance
```sql
EXPLAIN SELECT * FROM bookings WHERE provider_id = 1 AND service_date = '2025-04-25';

-- Look at "rows" column - should be low (<100)
-- Look at "key" column - should use an index, not NULL
```

### 2. Enable Query Profiling
```sql
SET profiling = 1;

SELECT * FROM bookings WHERE provider_id = 1;

SHOW PROFILES;
SHOW PROFILE FOR QUERY 1;
```

### 3. Optimize Large Tables
```sql
-- Rebuild table and optimize space
OPTIMIZE TABLE bookings;

-- Analyze table statistics for query planner
ANALYZE TABLE bookings;
```

### 4. Monitor Slow Queries
```sql
-- Enable slow query log
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;  -- Queries taking >2 seconds

-- View slow queries
TAIL /var/log/mysql/slow.log
```

### 5. Connection Pooling
```
Configure connection pool size:
- Min connections: 5
- Max connections: 20 (adjust based on load)
- Timeout: 30 minutes
```

---

## Backup & Recovery

### Backup Strategy
```bash
# Full backup daily
mysqldump -u root -p beautyplug > backup_$(date +%Y%m%d).sql

# Compressed backup
mysqldump -u root -p beautyplug | gzip > backup_$(date +%Y%m%d).sql.gz

# Incremental binary log backup
# (Enable binary logging in my.cnf: log_bin = mysql-bin)
```

### Point-in-Time Recovery
```sql
-- Restore from full backup
mysql -u root -p beautyplug < backup_20250420.sql

-- Replay binary logs up to specific time
mysqlbinlog --start-datetime="2025-04-20 10:00:00" \
            --stop-datetime="2025-04-20 11:00:00" \
            mysql-bin.000001 | mysql -u root -p beautyplug
```

### Testing Recovery
```bash
# Monthly: Restore backup to test database and verify integrity
mysql -u root -p test_beautyplug < backup_latest.sql

# Run data validation queries
mysql -u root -p test_beautyplug -e "SELECT COUNT(*) FROM bookings;"
```

---

## Database Monitoring Checklist

- [ ] Disk space usage (backup if >80% full)
- [ ] Table fragmentation (OPTIMIZE if needed)
- [ ] Slow query log (review regularly)
- [ ] Replication lag (if using master-slave)
- [ ] Connection pool status (avoid exhaustion)
- [ ] Index size vs. query performance (add/drop as needed)
- [ ] Data growth rate (capacity planning)
- [ ] Backup success/integrity (test restores)

---

## SQL Best Practices for BeautyPlug

### ✅ DO:
- Use prepared statements (prevent SQL injection)
- Index foreign keys and frequently searched columns
- Use transactions for multi-step operations (booking + payment)
- Keep transaction scopes small (short locks)
- Use ENUM for status fields (save space)
- Document complex queries with comments

### ❌ DON'T:
- SELECT * (specify needed columns)
- Join >5 tables without proper indexes
- Store images/files in database (use object storage)
- Use FLOAT/DOUBLE for money (use DECIMAL)
- Make columns nullable unnecessarily
- Trust user-supplied coordinates without validation
- Hard-code commission percentages (use admin_settings)

---

## Version Control for Schema Changes

### Using Migrations (Recommended)
```python
# migrations/001_initial_schema.sql
# migrations/002_add_disputes_table.sql
# migrations/003_add_provider_suspensions.sql

# Track which migrations have been applied
CREATE TABLE schema_migrations (
  id INT PRIMARY KEY AUTO_INCREMENT,
  migration_name VARCHAR(255) UNIQUE NOT NULL,
  applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Safe Schema Changes
```sql
-- Add column safely (add at end, with default)
ALTER TABLE providers ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;

-- Rename column (MySQL 8.0+)
ALTER TABLE providers RENAME COLUMN is_deleted TO soft_deleted;

-- Add index non-blocking (MySQL 5.7+)
ALTER TABLE bookings ADD INDEX idx_new (provider_id), ALGORITHM=INPLACE, LOCK=NONE;

-- Modify data type carefully
ALTER TABLE services MODIFY price DECIMAL(12, 2);  -- Larger range
```

---

## Conclusion

This comprehensive guide should help you:
1. ✅ Understand the schema architecture
2. ✅ Know which column types to use
3. ✅ Implement proper indexes
4. ✅ Write efficient queries
5. ✅ Handle backups & recovery
6. ✅ Monitor database health
7. ✅ Plan for growth

**Next Steps**:
- Set up database in your development environment
- Load sample data
- Build application layer on top
- Create API endpoints for all operations
- Implement proper error handling & validation
