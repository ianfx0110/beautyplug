# BeautyPlug Database Design Documentation

## Overview
BeautyPlug is a peer-to-peer beauty services marketplace connecting clients with vetted service providers (barbers, stylists, manicurists, etc.) for both remote (provider comes to client) and in-shop services.

---

## Database Architecture

### Core Principles
1. **Soft Deletes**: Providers who are rejected/suspended use soft deletes (marked with `is_deleted`) to maintain audit trails
2. **Commission Tracking**: All financial transactions track platform commission (15%) separately
3. **Flexible Payment**: Clients choose between upfront payment and on-demand (pay after service)
4. **Vetting Workflow**: Multi-stage approval process (pending → under_review → approved/rejected/suspended)
5. **Profile Completion**: Tracks percentage of profile completion to guide providers to complete profiles
6. **Availability Slots**: Per-booking availability model (providers confirm each slot)

---

## Tables Breakdown

### 1. **users**
Core user table for all roles (client, provider, admin)
```
Columns:
- id: Primary key
- email, phone: Unique contact info
- first_name, last_name: User name
- password_hash: Hashed password
- user_type: client | provider | admin
- created_at, updated_at: Timestamps
```

**Usage**: 
- Single source of truth for authentication
- Referenced by clients, service_providers, and admins

---

### 2. **service_providers**
Provider profiles with vetting status and location info

**Key Fields**:
- `business_name`: Provider's business/brand name
- `primary_category`: barber | hairstylist | manicure | pedicure | massage | skincare | makeup | waxing | nail_art | other
- `home_location_*`: Provider's base location (latitude/longitude for geographic queries)
- `approval_status`: Tracks vetting workflow
  - `pending`: Just signed up, awaiting vetting
  - `under_review`: Admin is reviewing documents
  - `approved`: Publicly visible, can receive bookings
  - `rejected`: Did not pass vetting
  - `suspended`: Previously approved but now inactive
- `profile_completion_percentage`: 0-100, helps guide provider to complete profile
- `is_deleted`: Soft delete flag (for rejected/suspended providers)

**Why These Fields**:
- Geographic coordinates enable "providers within X km" queries
- Approval workflow ensures quality control
- Profile completion % nudges providers toward 100% info for better bookings
- Soft delete preserves historical data for audits

---

### 3. **provider_documents**
Verification documents (ID, certifications, licenses, portfolio photos)

**Key Fields**:
- `document_type`: id_verification | certification | portfolio | license
- `is_verified`: Admin-verified flag
- `verified_by`: Which admin verified it
- `verified_at`: When verification happened

**Usage**:
- Multiple documents per provider
- Admin dashboard can bulk verify documents
- Portfolio photos help clients choose providers

---

### 4. **services**
Individual services a provider offers (each with own price & duration)

**Key Fields**:
- `provider_id`: Which provider offers this
- `service_name`: "Haircut", "Beard Trim", "Full Grooming", etc.
- `price`: Provider-set price
- `duration_minutes`: How long the service takes (used to calculate end_time in bookings)
- `is_active`: Can be deactivated without deleting

**Example**:
```
Provider: John's Barbershop
- Service 1: Haircut - $25 - 30 mins
- Service 2: Beard Trim - $15 - 20 mins  
- Service 3: Full Grooming - $45 - 60 mins
```

---

### 5. **clients**
Client profiles (extends users table)

**Key Fields**:
- `user_id`: FK to users
- `profile_picture_url`: Client avatar
- `bio`: Optional bio/preferences

**Usage**:
- Separate table for future client-specific features (payment methods, preferences, etc.)

---

### 6. **bookings**
Core transaction table - represents a service booking

**Key Fields**:

**Booking Status Workflow**:
```
requested → confirmed → completed
                     ↓
                  cancelled (by client or provider)
                  no_show (client didn't show)
```

**Location**:
- `service_location_address`: Where the service happens
- `is_at_provider_location`: TRUE = at provider's shop, FALSE = at client location
- Both parties know the exact location

**Financial**:
- `service_price`: Price at time of booking (locked in case provider changes prices later)
- `platform_commission`: Calculated as 15% of service_price
- `provider_earnings`: service_price - platform_commission

**Scheduling**:
- `service_date`: Date of appointment
- `start_time, end_time`: Time slot (end_time calculated from service duration)

**Notes**:
- Both client and provider can add notes for communication

---

### 7. **transactions**
Payment records - one per completed/paid booking

**Key Fields**:

**Payment Status**:
- `pending`: Awaiting payment
- `paid`: Payment received
- `refunded`: Full/partial refund issued
- `failed`: Payment declined

**Payment Type**:
- `upfront`: Client pays when booking
- `on_demand`: Client pays after service completes

**Refunds**:
- `refund_status`: none | requested | approved | completed
- Tracks reason and approval workflow

**Provider Payout**:
- `provider_payout`: Amount provider receives (after platform commission)
- Can be used to track money owed to providers

---

### 8. **ratings**
Reviews & ratings (one per completed booking)

**Key Fields**:
- `rating_stars`: 1-5 overall rating
- `review_text`: Written feedback
- `cleanliness_rating, professionalism_rating, punctuality_rating, quality_rating`: Detailed category ratings
- `photo_url`: Optional photo evidence
- `provider_response`: Provider can respond to review

**Constraint**: Only ONE rating per booking (enforced by UNIQUE on booking_id)

**Usage**:
- Filled ONLY after booking is completed
- Average rating updated in `provider_rating_summary`

---

### 9. **provider_availability_slots**
Per-booking availability (providers mark when they're available)

**Why Per-Booking?**
- More flexible than fixed "Mon-Fri 9AM-5PM" schedules
- Providers can mark specific time slots available
- Can handle holidays, irregular schedules, etc.

**Usage Flow**:
1. Provider adds availability slots in advance
2. Client books a slot
3. Provider confirms/rejects the booking
4. Slot becomes unavailable if booking confirmed

---

### 10. **provider_rating_summary**
Denormalized view for fast queries (aggregated ratings)

**Why Denormalize?**
- Dashboard needs average ratings instantly
- Provider listings sorted by rating need fast queries
- Recalculate via trigger or batch job when new rating added

**Fields**:
- `total_ratings`: Count of ratings
- `average_rating`: Overall average (1-5)
- Category averages: cleanliness, professionalism, punctuality, quality
- Distribution: count of 5-star, 4-star, etc. reviews

---

### 11. **client_favorites**
Wishlist / favorite providers

**Usage**:
- Clients can favorite providers
- Shows "Your Favorites" on dashboard
- Simple many-to-many relationship

---

### 12. **audit_logs**
Admin action audit trail

**Key Fields**:
- `admin_id`: Which admin took the action
- `action_type`: provider_approved | provider_rejected | etc.
- `old_values, new_values`: JSON of what changed
- `ip_address`: For security audits

**Examples**:
```
Action: provider_approved
Target: provider_id=42
Old: approval_status='pending'
New: approval_status='approved'

Action: document_verified
Target: document_id=123
New: is_verified=true, verified_by=1
```

---

### 13. **disputes**
Complaint/dispute resolution system

**Dispute Types**:
- `service_not_rendered`: Provider didn't show
- `quality_issue`: Service was poor quality
- `no_show_client`: Client didn't show
- `no_show_provider`: Provider didn't show
- `price_dispute`: Disagreement on price
- `other`: Custom dispute

**Resolution**:
- `status`: open | under_review | resolved | closed
- `resolved_by`: Which admin resolved it
- `resolution_notes`: How it was resolved

**Usage**:
- Escalation path when booking/rating issues occur
- Audit trail for all disputes

---

### 14. **notifications**
Real-time/push notifications

**Types**:
- `booking_request`: New booking awaiting confirmation
- `booking_confirmed`: Your booking was confirmed
- `booking_completed`: Service done, time to pay/rate
- `booking_cancelled`: Booking was cancelled
- `rating_received`: Someone rated you
- `provider_approved`: Your profile was approved
- `payment_received`: Payment processed
- `dispute_opened`: Dispute filed against you

**Usage**:
- `is_read` flag for UI (show unread count)
- `read_at` timestamp for audit

---

### 15. **admin_settings**
Key-value configuration table

**Examples**:
```
setting_key='platform_commission_percent'
setting_value='15'
setting_type='number'

setting_key='provider_approval_required'
setting_value='true'
setting_type='boolean'

setting_key='payment_methods_enabled'
setting_value='["card", "wallet", "bank_transfer"]'
setting_type='json'
```

---

## Relationships Diagram

```
users (1) ──── (1) service_providers
users (1) ──── (1) clients
users (1) ──── (*) audit_logs

service_providers (1) ──── (*) services
service_providers (1) ──── (*) provider_documents
service_providers (1) ──── (*) bookings
service_providers (1) ──── (1) provider_rating_summary
service_providers (1) ──── (*) provider_availability_slots
service_providers (*) ────── (*) clients [via client_favorites]

clients (1) ──── (*) bookings
clients (1) ──── (*) ratings

services (1) ──── (*) bookings

bookings (1) ──── (1) transactions
bookings (1) ──── (1) ratings
bookings (1) ──── (*) disputes

ratings (1) ──── many ratings per provider [aggregated in provider_rating_summary]
```

---

## Key Constraints & Validations

### Unique Constraints
- `users.email`: Must be unique across all users
- `users.phone`: Must be unique across all users
- `service_providers.user_id`: One profile per user
- `clients.user_id`: One profile per user
- `bookings.id`: Each booking is unique
- `transactions.booking_id`: One transaction per booking
- `ratings.booking_id`: One rating per booking
- `provider_rating_summary.provider_id`: One summary per provider
- `client_favorites(client_id, provider_id)`: Can't favorite same provider twice
- `admin_settings.setting_key`: One value per setting

### Check Constraints
- `ratings.rating_stars`: Must be 1-5
- `ratings.cleanliness_rating`: Must be 1-5 or NULL
- `ratings.professionalism_rating`: Must be 1-5 or NULL
- `ratings.punctuality_rating`: Must be 1-5 or NULL
- `ratings.quality_rating`: Must be 1-5 or NULL

### Foreign Keys
- All FKs have appropriate ON DELETE actions:
  - `CASCADE`: If parent deleted, delete children (e.g., delete provider → delete their services)
  - `SET NULL`: If parent deleted, set FK to NULL (e.g., delete admin → audit_log.approved_by becomes NULL)
  - `RESTRICT`: Prevent deletion if children exist (e.g., can't delete service while bookings exist)

---

## Indexes for Performance

### Critical Indexes
```sql
-- User lookups
INDEX idx_email (email)
INDEX idx_user_type (user_type)

-- Provider searches
INDEX idx_approval_status (approval_status)
INDEX idx_primary_category (primary_category)
INDEX idx_location (home_location_latitude, home_location_longitude)

-- Booking queries
INDEX idx_client_id (client_id)
INDEX idx_provider_id (provider_id)
INDEX idx_service_date (service_date)
INDEX idx_booking_status (booking_status)
INDEX idx_composite (provider_id, service_date, booking_status)
  └─ Composite index for: "Show me all confirmed bookings for provider X on date Y"

-- Availability
INDEX idx_provider_date (provider_id, available_date)

-- Ratings
INDEX idx_average_rating (average_rating DESC)
  └─ For sorting providers by rating

-- Notifications
INDEX idx_user_id (user_id)
INDEX idx_is_read (is_read)

-- Audit & Disputes
INDEX idx_created_at (created_at DESC)
```

---

## Data Flow Examples

### Example 1: Provider Signup → Approval → Service Booking

```
1. SIGNUP
   users.insert(email, phone, password_hash, user_type='provider')
   service_providers.insert(user_id, business_name, approval_status='pending', profile_completion_percentage=0)
   
2. PROFILE COMPLETION
   service_providers.update(id, bio, primary_category, home_location_*, 
                           profile_completion_percentage=100)
   provider_documents.insert(id, document_type='id_verification', document_url=...)
   provider_documents.insert(id, document_type='certification', document_url=...)
   services.insert(provider_id, service_name, price, duration_minutes)
   services.insert(provider_id, service_name, price, duration_minutes)
   
3. ADMIN VETTING
   provider_documents.update(id, is_verified=true, verified_by=admin_id)
   audit_logs.insert(admin_id, action_type='document_verified', target_entity_id=doc_id)
   
   service_providers.update(id, approval_status='approved', approved_by=admin_id, approved_at=NOW())
   audit_logs.insert(admin_id, action_type='provider_approved', target_entity_id=provider_id)
   
4. PROVIDER SETS AVAILABILITY
   provider_availability_slots.insert(provider_id, available_date='2025-04-22', 
                                     start_time='09:00', end_time='17:00')
   
5. CLIENT BOOKS
   bookings.insert(client_id, service_id, provider_id, service_date='2025-04-22',
                  start_time='10:00', end_time='10:30', booking_status='requested')
   notifications.insert(provider_id_user, 'booking_request')
   
6. PROVIDER CONFIRMS
   bookings.update(id, booking_status='confirmed')
   provider_availability_slots.update(id, is_available=false)  -- Slot taken
   notifications.insert(client_id_user, 'booking_confirmed')
   
7. SERVICE COMPLETED & PAYMENT
   bookings.update(id, booking_status='completed')
   transactions.insert(booking_id, amount, payment_status='pending', payment_type='on_demand')
   transactions.update(id, payment_status='paid')
   notifications.insert(provider_id_user, 'payment_received')
   
8. CLIENT RATES
   ratings.insert(booking_id, client_id, provider_id, rating_stars=5, review_text='...')
   provider_rating_summary.update(provider_id, total_ratings=..., average_rating=...)
   notifications.insert(provider_id_user, 'rating_received')
```

---

### Example 2: Booking Cancellation & Refund

```
1. CLIENT CANCELS
   bookings.update(id, booking_status='cancelled', cancelled_by='client', 
                  cancellation_reason='Emergency came up')
   provider_availability_slots.update(id, is_available=true)  -- Free up slot
   notifications.insert(provider_id_user, 'booking_cancelled')
   
2. PROCESS REFUND
   transactions.update(booking_id, refund_status='requested', refund_requested_at=NOW())
   audit_logs.insert(admin_id, action_type='...')
   
   transactions.update(booking_id, refund_status='approved', refund_amount=full_amount, 
                      resolved_at=NOW())
   transactions.update(booking_id, payment_status='refunded')
   notifications.insert(client_id_user, 'payment_refunded')
```

---

### Example 3: Dispute Resolution

```
1. OPEN DISPUTE
   disputes.insert(booking_id, reported_by=client_user_id, 
                  dispute_type='quality_issue',
                  description='Haircut was uneven')
   notifications.insert(provider_id_user, 'dispute_opened')
   
2. ADMIN REVIEWS
   audit_logs.insert(admin_id, action_type='dispute_opened', target_entity_id=dispute_id)
   
3. RESOLVE
   disputes.update(id, status='resolved', resolution_notes='Offered rework', 
                  resolved_by=admin_id, resolved_at=NOW())
   transactions.update(booking_id, refund_status='approved', refund_amount=partial_amount)
   notifications.insert(both_users, 'dispute_resolved')
```

---

## Queries You'll Need

### 1. Find Available Providers Near Client
```sql
SELECT sp.*, prs.average_rating
FROM service_providers sp
LEFT JOIN provider_rating_summary prs ON sp.id = prs.provider_id
WHERE sp.approval_status = 'approved' 
  AND sp.is_deleted = FALSE
  AND ST_Distance_Sphere(
    POINT(sp.home_location_longitude, sp.home_location_latitude),
    POINT(?, ?)  -- Client's coordinates
  ) <= 5000  -- 5km radius
ORDER BY prs.average_rating DESC
LIMIT 20;
```

### 2. Check Provider Availability
```sql
SELECT * FROM provider_availability_slots
WHERE provider_id = ? 
  AND available_date = ?
  AND is_available = TRUE
  AND start_time <= ?
  AND end_time >= ?
ORDER BY start_time;
```

### 3. Provider's Booking Schedule
```sql
SELECT b.*, c.user_id as client_id, s.service_name
FROM bookings b
JOIN clients c ON b.client_id = c.id
JOIN services s ON b.service_id = s.id
WHERE b.provider_id = ?
  AND DATE(b.service_date) = ?
  AND b.booking_status IN ('confirmed', 'completed')
ORDER BY b.start_time;
```

### 4. Provider Revenue Report
```sql
SELECT 
  DATE(b.created_at) as date,
  COUNT(b.id) as bookings,
  SUM(CASE WHEN b.booking_status = 'completed' THEN 1 ELSE 0 END) as completed,
  SUM(CASE WHEN b.booking_status = 'completed' THEN b.provider_earnings ELSE 0 END) as earnings
FROM bookings b
WHERE b.provider_id = ?
GROUP BY DATE(b.created_at)
ORDER BY date DESC;
```

### 5. Client's Booking History
```sql
SELECT b.*, sp.business_name, s.service_name, r.rating_stars
FROM bookings b
JOIN service_providers sp ON b.provider_id = sp.id
JOIN services s ON b.service_id = s.id
LEFT JOIN ratings r ON b.id = r.booking_id
WHERE b.client_id = ?
ORDER BY b.service_date DESC;
```

---

## Future Enhancements

1. **Recurring Bookings**: Add `recurring_bookings` table for weekly/monthly recurring services
2. **Promotions**: Add `promo_codes`, `discounts`, `loyalty_points` tables
3. **Chat/Messaging**: Add `messages`, `conversations` tables for client-provider communication
4. **Subscriptions**: Add `provider_subscriptions` for membership plans
5. **Analytics**: Add `daily_metrics`, `revenue_reports` for dashboard
6. **Waitlist**: Add `booking_waitlist` when provider is fully booked
7. **Time Off**: Add `provider_blackout_dates` for holidays/PTO
8. **Insurance/Liability**: Add `insurance_policies`, `liability_coverage`
9. **Multi-Language**: Add `translations` table for i18n
10. **Geofencing**: Track actual location during service (lat/long at start/end)

---

## Security Considerations

1. **PII Protection**: 
   - Hash passwords with bcrypt/argon2
   - Encrypt sensitive fields (ID number, SSN, etc.)
   - Mask phone numbers in UI for privacy

2. **Payment Security**:
   - Never store full credit card numbers
   - Use payment gateway tokenization (Stripe, PayPal)
   - Audit all financial transactions

3. **Admin Access**:
   - All admin actions logged in `audit_logs`
   - Role-based access control (who can approve what)
   - IP whitelisting for admin portal

4. **Data Privacy**:
   - GDPR compliance: right to be forgotten (soft delete)
   - Data retention policies
   - PII anonymization in logs/backups

---

## Maintenance & Operations

### Regular Tasks

1. **Backup Strategy**:
   - Daily incremental backups
   - Weekly full backups to cold storage
   - Test restore procedures

2. **Index Maintenance**:
   - Monthly ANALYZE TABLE to update statistics
   - Monitor slow query log
   - Rebuild fragmented indexes

3. **Data Cleanup**:
   - Archive old audit logs (>1 year)
   - Remove soft-deleted records after 2 years
   - Cleanup expired tokens/sessions

4. **Performance Monitoring**:
   - Monitor connection pool usage
   - Track query execution times
   - Alert on slow queries

---

## Questions to Revisit

As you build, consider:

1. **Multi-language**: Should provider names/services support multiple languages?
2. **Multi-currency**: Should providers set prices in different currencies?
3. **Taxes**: Need to track VAT/GST per region?
4. **Scaling**: Ready for sharding by geography or provider ID?
5. **Analytics**: What KPIs matter most? (completion rate, avg rating, revenue, etc.)

---

## Conclusion

This schema provides a solid foundation for BeautyPlug with:
- ✅ Clear separation of concerns (users, providers, clients, bookings, payments)
- ✅ Vetting workflow for quality control
- ✅ Flexible scheduling (per-booking availability)
- ✅ Financial tracking (commission, payouts, refunds)
- ✅ Rating system for trust & accountability
- ✅ Audit trail for transparency
- ✅ Soft deletes for compliance
- ✅ Proper indexing for performance
- ✅ Extensible design for future features

**Next Steps**:
1. Validate schema with your backend team
2. Create entity relationship diagram (ERD)
3. Build application models/ORM mappings
4. Implement database migration scripts
5. Add application-level business logic
