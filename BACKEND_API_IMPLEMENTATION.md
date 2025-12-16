# MuzaksFood Backend API Implementation Guide

## Overview

This document provides comprehensive guidelines for implementing 9 new API endpoints in the Laravel backend to support advanced features in the MuzaksFood Flutter app. These endpoints enable cross-device synchronization for saved payment methods, filter analytics, and search history.

**Key Principle**: The Flutter app has graceful fallback mechanisms. All features work with local storage (SharedPreferences) initially. Once these backend endpoints are implemented and available, the app automatically syncs data without requiring any frontend code changes.

---

## Table of Contents

1. [Payment Methods Endpoints (5)](#payment-methods-endpoints)
2. [Filter Analytics Endpoints (2)](#filter-analytics-endpoints)
3. [Search History Endpoints (4)](#search-history-endpoints)
4. [Database Schema](#database-schema)
5. [Implementation Checklist](#implementation-checklist)
6. [Security Considerations](#security-considerations)

---

## Payment Methods Endpoints

### 1. GET `/api/v1/customer/payment-methods`

Retrieve all saved payment methods for the logged-in customer.

**Authentication**: Required (Bearer token)

**Query Parameters**:
- None

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "customer_id": 123,
      "card_holder_name": "John Doe",
      "card_number": "****1234",
      "expiry_month": 12,
      "expiry_year": 2025,
      "is_default": true,
      "created_at": "2025-01-01T10:00:00Z"
    },
    {
      "id": 2,
      "customer_id": 123,
      "card_holder_name": "Jane Doe",
      "card_number": "****5678",
      "expiry_month": 6,
      "expiry_year": 2026,
      "is_default": false,
      "created_at": "2025-01-02T10:00:00Z"
    }
  ]
}
```

**Implementation Notes**:
- Return only the last 4 digits of card number (masked)
- Order by `is_default DESC`, then `created_at DESC`
- Include only non-deleted payment methods

---

### 2. POST `/api/v1/customer/payment-methods/add`

Save a new payment method for the customer.

**Authentication**: Required

**Request Body**:
```json
{
  "card_holder_name": "John Doe",
  "card_number": "4111111111111111",
  "expiry_month": 12,
  "expiry_year": 2025,
  "cvv": "123"
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "message": "Payment method added successfully",
  "data": {
    "id": 3,
    "customer_id": 123,
    "card_holder_name": "John Doe",
    "card_number": "****1111",
    "expiry_month": 12,
    "expiry_year": 2025,
    "is_default": false,
    "created_at": "2025-01-16T10:00:00Z"
  }
}
```

**Implementation Notes**:
- Validate card number using Luhn algorithm
- Validate expiry date (not expired)
- Encrypt full card number before storing
- If this is the first payment method for the customer, set `is_default = true`
- Otherwise, set `is_default = false`
- CVV should NOT be stored (process via payment gateway and discard)
- Return validation errors with 422 status

**Validation Errors** (422):
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "card_number": ["Invalid card number"],
    "expiry_year": ["Card has expired"]
  }
}
```

---

### 3. PUT `/api/v1/customer/payment-methods/update`

Update an existing payment method (non-sensitive fields only).

**Authentication**: Required

**Request Body**:
```json
{
  "payment_method_id": 1,
  "card_holder_name": "John Michael Doe",
  "expiry_month": 12,
  "expiry_year": 2027
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Payment method updated successfully",
  "data": {
    "id": 1,
    "customer_id": 123,
    "card_holder_name": "John Michael Doe",
    "card_number": "****1234",
    "expiry_month": 12,
    "expiry_year": 2027,
    "is_default": true,
    "created_at": "2025-01-01T10:00:00Z"
  }
}
```

**Implementation Notes**:
- Only allow updating: `card_holder_name`, `expiry_month`, `expiry_year`
- Verify customer owns this payment method (authorization check)
- Validate new expiry date
- Return 403 Forbidden if customer doesn't own the payment method
- Return 404 Not Found if payment method doesn't exist

---

### 4. DELETE `/api/v1/customer/payment-methods/delete/{id}`

Delete a saved payment method.

**Authentication**: Required

**Path Parameters**:
- `id` (integer): Payment method ID

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Payment method deleted successfully"
}
```

**Error Responses**:

403 Forbidden (if customer doesn't own it):
```json
{
  "success": false,
  "message": "Unauthorized action"
}
```

400 Bad Request (if it's the only payment method):
```json
{
  "success": false,
  "message": "Cannot delete the only payment method. Add another payment method first."
}
```

**Implementation Notes**:
- Verify customer owns this payment method
- If this is the default payment method, automatically set the oldest (by created_at) payment method as default
- Prevent deletion if it's the customer's only payment method
- Use soft delete if audit trails are required

---

### 5. POST `/api/v1/customer/payment-methods/set-default`

Set a payment method as the default for one-click checkout.

**Authentication**: Required

**Request Body**:
```json
{
  "payment_method_id": 1
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Default payment method updated",
  "data": {
    "id": 1,
    "customer_id": 123,
    "card_holder_name": "John Doe",
    "card_number": "****1234",
    "expiry_month": 12,
    "expiry_year": 2025,
    "is_default": true,
    "created_at": "2025-01-01T10:00:00Z"
  }
}
```

**Implementation Notes**:
- Verify customer owns this payment method
- Set all other payment methods for this customer to `is_default = false`
- Set specified payment method to `is_default = true`
- Use a database transaction to ensure consistency
- Return 404 if payment method doesn't exist or customer doesn't own it

---

## Filter Analytics Endpoints

### 6. POST `/api/v1/customer/analytics/filter-usage`

Log filter usage analytics when user applies product filters. The app batches events and sends them when 10+ events accumulate.

**Authentication**: Required

**Request Body**:
```json
{
  "events": [
    {
      "filter_type": "price_range",
      "min_price": 100,
      "max_price": 5000,
      "rating": null,
      "timestamp": "2025-01-16T10:00:00Z"
    },
    {
      "filter_type": "rating",
      "min_price": null,
      "max_price": null,
      "rating": 4.5,
      "timestamp": "2025-01-16T10:01:00Z"
    }
  ]
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Filter usage logged",
  "synced_count": 2
}
```

**Implementation Notes**:
- Store each event in `filter_usage_analytics` table
- `filter_type` can be: `price_range`, `rating`, or `combined`
- Allow `null` values for unused filter fields
- Use `timestamp` from request (client-side timing)
- Log customer_id automatically from authenticated user
- Don't validate timestamps strictly (allow up to 1 hour in past)
- Return synced_count for verification

---

### 7. GET `/api/v1/customer/analytics/popular-filters`

Retrieve popular filters across all customers for insights and recommendations.

**Authentication**: Optional (can be public)

**Query Parameters**:
- `days` (integer, default: 7): Number of days to analyze

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "popular_price_ranges": [
      {
        "min": 100,
        "max": 500,
        "count": 245,
        "percentage": 35.2
      },
      {
        "min": 500,
        "max": 1000,
        "count": 182,
        "percentage": 26.1
      },
      {
        "min": 0,
        "max": 100,
        "count": 160,
        "percentage": 23.0
      }
    ],
    "popular_ratings": [
      {
        "rating": 4.5,
        "count": 320,
        "percentage": 45.9
      },
      {
        "rating": 4.0,
        "count": 215,
        "percentage": 30.9
      },
      {
        "rating": 3.5,
        "count": 161,
        "percentage": 23.2
      }
    ],
    "period": "last_7_days",
    "total_filter_events": 696
  }
}
```

**Implementation Notes**:
- Query events from last N days
- Group price ranges by min/max combinations
- Group ratings and round to nearest 0.5
- Calculate percentages
- Cache results for 1 hour (Redis recommended)
- Order results by count (descending)
- Include top 10 items for each category

---

## Search History Endpoints

### 8. GET `/api/v1/products/trending-searches`

Get trending search queries across all customers.

**Authentication**: Optional (can be public)

**Query Parameters**:
- `limit` (integer, default: 10): Number of trending searches to return
- `days` (integer, default: 7): Number of days to analyze

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "query": "bread",
      "count": 1250,
      "trend": "up",
      "trend_percentage": 15.5
    },
    {
      "query": "milk",
      "count": 1120,
      "trend": "stable",
      "trend_percentage": 0
    },
    {
      "query": "eggs",
      "count": 980,
      "trend": "down",
      "trend_percentage": -8.2
    }
  ],
  "period": "last_7_days"
}
```

**Implementation Notes**:
- Query `search_analytics` table
- Group by query (case-insensitive)
- Count occurrences
- Compare with previous period to determine trend (up/down/stable)
- Calculate trend percentage: `((current - previous) / previous) * 100`
- Sort by count descending
- Limit results to requested amount
- Cache for 1 hour
- Exclude single-character queries and common stopwords if desired

---

### 9. GET `/api/v1/customer/search-history`

Retrieve customer's personal search history.

**Authentication**: Required

**Query Parameters**:
- `limit` (integer, default: 20): Maximum number of history items to return

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "query": "bread whole wheat",
      "result_count": 45,
      "timestamp": "2025-01-16T14:30:00Z"
    },
    {
      "id": 2,
      "query": "milk",
      "result_count": 120,
      "timestamp": "2025-01-16T12:15:00Z"
    },
    {
      "id": 3,
      "query": "eggs",
      "result_count": 87,
      "timestamp": "2025-01-16T10:45:00Z"
    }
  ]
}
```

**Implementation Notes**:
- Return only authenticated customer's history
- Order by timestamp descending (most recent first)
- Limit to requested amount
- Include result_count for UX (show "45 products found" etc.)
- Return empty array if no history

---

### 10. POST `/api/v1/customer/search-history/save`

Save a search query to customer's history. Called after each search.

**Authentication**: Required

**Request Body**:
```json
{
  "query": "bread whole wheat",
  "result_count": 45
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "message": "Search saved to history",
  "data": {
    "id": 4,
    "query": "bread whole wheat",
    "result_count": 45,
    "timestamp": "2025-01-16T14:32:00Z"
  }
}
```

**Implementation Notes**:
- Accept and store the exact query (preserving case)
- Store result_count for analytics
- **Deduplication**: If identical query exists, delete the old one and insert as new (latest always at top)
- Keep only last 20 entries per customer (delete oldest if exceeding)
- Automatically log to `search_analytics` table for trending analysis
- Strip/trim whitespace from query
- Don't store empty queries (return 400 Bad Request)

---

### 11. DELETE `/api/v1/customer/search-history/clear`

Clear all search history for the authenticated customer.

**Authentication**: Required

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Search history cleared successfully"
}
```

**Implementation Notes**:
- Delete all rows in `customer_search_history` for authenticated customer
- Don't affect `search_analytics` (trending data)
- Return success even if history was already empty

---

## Database Schema

### Table: `saved_payment_methods`

```sql
CREATE TABLE saved_payment_methods (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    customer_id BIGINT UNSIGNED NOT NULL,
    card_holder_name VARCHAR(255) NOT NULL,
    card_number_encrypted LONGTEXT NOT NULL,  -- Encrypted full card number
    card_number_last_four CHAR(4) NOT NULL,   -- Last 4 digits (for display)
    expiry_month TINYINT UNSIGNED NOT NULL,   -- 1-12
    expiry_year SMALLINT UNSIGNED NOT NULL,   -- 2025+
    is_default BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,         -- Soft delete
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    INDEX idx_customer_is_default (customer_id, is_default),
    INDEX idx_customer_created (customer_id, created_at DESC)
);
```

### Table: `filter_usage_analytics`

```sql
CREATE TABLE filter_usage_analytics (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    customer_id BIGINT UNSIGNED NOT NULL,
    filter_type VARCHAR(50) NOT NULL,         -- 'price_range', 'rating', 'combined'
    min_price DECIMAL(10, 2) NULLABLE,
    max_price DECIMAL(10, 2) NULLABLE,
    rating DECIMAL(3, 1) NULLABLE,            -- 0.5 to 5.0
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    INDEX idx_customer_created (customer_id, created_at DESC),
    INDEX idx_filter_type (filter_type),
    INDEX idx_created_date (DATE(created_at))
);
```

### Table: `customer_search_history`

```sql
CREATE TABLE customer_search_history (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    customer_id BIGINT UNSIGNED NOT NULL,
    query VARCHAR(255) NOT NULL,
    result_count INT UNSIGNED DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    INDEX idx_customer_created (customer_id, created_at DESC),
    INDEX idx_query (query)
);
```

### Table: `search_analytics` (Optional, for trending)

```sql
CREATE TABLE search_analytics (
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    query VARCHAR(255) NOT NULL,
    customer_id BIGINT UNSIGNED NULLABLE,     -- Can be null for public searches
    product_result_count INT UNSIGNED DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL,
    INDEX idx_query (query),
    INDEX idx_created_date (DATE(created_at)),
    INDEX idx_query_date (query, DATE(created_at))
);
```

---

## Implementation Checklist

### Database Setup
- [ ] Create migration for `saved_payment_methods` table
- [ ] Create migration for `filter_usage_analytics` table
- [ ] Create migration for `customer_search_history` table
- [ ] Create migration for `search_analytics` table (optional)
- [ ] Add database indexes as shown in schema
- [ ] Set up encryption keys for payment data

### Controllers & Routes
- [ ] Create `PaymentMethodController` with 5 methods
- [ ] Create `FilterAnalyticsController` with 2 methods
- [ ] Create `SearchHistoryController` with 4 methods
- [ ] Create `TrendingSearchController` with 1 method (or add to SearchHistoryController)
- [ ] Register routes in `routes/api.php`
  - Prefix: `/api/v1/customer`
  - Use middleware: `auth:api`, `throttle:60,1` (adjust as needed)

### Security & Validation
- [ ] Add `Illuminate\Support\Facades\Crypt` for card encryption
- [ ] Create FormRequest validators for each endpoint
  - `PaymentMethodRequest` (add, update, set-default)
  - `FilterAnalyticsRequest` (batch events)
  - `SearchHistoryRequest` (save)
- [ ] Add authorization checks (customer owns resource)
- [ ] Add rate limiting per endpoint
- [ ] Validate card numbers with Luhn algorithm
- [ ] Implement CORS if frontend is on different domain
- [ ] Add audit logging for sensitive operations

### Testing
- [ ] Write unit tests for each controller method
- [ ] Test authorization (customer can't access other customer's data)
- [ ] Test validation errors (422 responses)
- [ ] Test edge cases (only payment method, expired dates, etc.)
- [ ] Test batch operations (multiple filter events)
- [ ] Load test trending searches endpoint

### Documentation
- [ ] Document all endpoints in Swagger/OpenAPI
- [ ] Add request/response examples to Postman collection
- [ ] Create developer documentation
- [ ] Document encryption/decryption strategy
- [ ] Document caching strategy for analytics endpoints

### Deployment
- [ ] Deploy migrations to production
- [ ] Set up encrypted card storage
- [ ] Configure Redis for caching (optional but recommended)
- [ ] Set up monitoring and logging
- [ ] Test endpoints with real Flutter app
- [ ] Verify automatic sync works without app code changes

---

## Security Considerations

### Payment Data
- **Encryption**: Use Laravel's `Crypt::encrypt()` to encrypt full card numbers before storing
- **Decryption**: Only decrypt when needed (during payment processing)
- **PCI Compliance**: Consider using tokenization service (Stripe, Square) instead of storing raw cards
- **CVV**: NEVER store CVV - accept it only for verification and discard immediately
- **Audit Trail**: Log all payment method operations with customer ID, action, and timestamp

### API Security
- **Authentication**: Require Bearer token for all authenticated endpoints
- **Authorization**: Always verify customer owns the resource they're accessing
- **Rate Limiting**: Implement to prevent abuse
  - Payment methods: 100 requests/hour per customer
  - Analytics: 1000 requests/hour per customer
  - Search: 5000 requests/hour per customer
- **Input Validation**: Validate all inputs against schema
- **SQL Injection**: Use parameterized queries (Laravel Eloquent does this)
- **CORS**: Configure appropriately for your domain

### Data Privacy
- **Personal Data**: Customer search queries and payment info are sensitive
- **GDPR/Privacy**: Implement data export and deletion features
- **Retention**: Define retention policies (e.g., delete search history after 90 days)
- **Compliance**: Document compliance with local data protection laws

---

## Sync Flow (Frontend to Backend)

The Flutter app automatically syncs data with these endpoints using the following flow:

```
1. User performs action (saves payment method, applies filter, searches)
   ↓
2. App stores data locally in SharedPreferences
   ↓
3. App attempts to sync with backend API
   ↓
4. If successful → data persisted on server, cross-device sync enabled
   ↓
5. If fails → app continues using local data, retries on next action
   ↓
6. Once endpoint becomes available → automatic sync begins without code changes
```

**Key**: The frontend doesn't require any code changes once these endpoints are live. It automatically detects and uses them.

---

## Common Implementation Errors to Avoid

1. **Not encrypting card numbers** - This is a security must-have
2. **Storing CVV** - Never do this; it's against PCI standards
3. **Missing authorization checks** - Always verify customer owns resources
4. **Not deduplicating search queries** - Causes bloated history
5. **Not handling soft deletes properly** - Ensure is_deleted flag is checked
6. **Not indexing correctly** - Performance will suffer without proper indexes
7. **Missing transaction for set-default** - Can leave multiple defaults in inconsistent state
8. **Not limiting search history** - Can cause unbounded growth
9. **Trusting client timestamp** - Validate and use server timestamp instead for critical data
10. **Not implementing pagination for lists** - Will have performance issues with large datasets

---

## Questions?

For implementation questions, refer to:
- Flutter app's `app_constants.dart` for exact endpoint URIs
- Controller implementations in respective provider files
- Test files for expected request/response formats

Happy coding! 🚀
