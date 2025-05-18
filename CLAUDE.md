# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Development Environment

```bash
# Install dependencies
bundle install

# Setup database
rails db:setup

# Run development server
rails server

# Access console
rails console
```

### Testing

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/path/to/file_spec.rb

# Run specific test (line number)
bundle exec rspec spec/path/to/file_spec.rb:42

# Run tests with focus tag
bundle exec rspec --tag focus
```

### Static Analysis & Linting

```bash
# Run security checks
bundle exec brakeman

# Run Ruby linting
bundle exec rubocop

# Run autofix for linting issues
bundle exec rubocop -a
```

### Database Management

```bash
# Create database
rails db:create

# Run migrations
rails db:migrate

# Seed database
rails db:seed

# Reset database (drop, create, migrate, seed)
rails db:reset
```

## Application Architecture

This is a Rails 8 invoicing application for managing clients and their associated billing rates. The system tracks client information, billing rates over time, and client sessions.

### Core Domain Models:

1. **Client**:
   - Represents a client with contact information (name, address, email)
   - Has associated fee records that track billing rates over time
   - Has associated client sessions for time tracking

2. **Fee**:
   - Represents a billing rate for a specific time period
   - Has start and end dates (`from` and `to` fields)
   - Tracks the hourly charge rate (stored using the Money gem)
   - Current rates have a `nil` end date

3. **ClientSession**:
   - Represents billable time spent with a client
   - Tracks start time and duration

### Key Functionality:

1. **Rate Management**:
   - Client rates can change over time
   - The system maintains a history of rate changes
   - Prevents overlapping fee periods
   - Current rate is always available via the `current_rate` method

2. **Data Validation**:
   - Validates required client fields (name, email, address1, town, postcode)
   - Validates postcode format using UK-style format
   - Ensures fee periods don't overlap
   - Validates rate change data integrity

### Testing Strategy:

The application uses RSpec with FactoryBot for testing. Factory definitions include:
- Basic client factory
- Client with random name
- Client with fee history
- Client with session history

Tests cover validation rules, rate calculation logic, and fee period management.

## Implementation Notes

- The application uses Rails 8.0.2
- Uses SQLite for development and test environments
- Uses the Money gem for currency handling
- Uses Solid gems (solid_cache, solid_queue, solid_cable) for caching, job queues, and ActionCable
- RSpec and FactoryBot are used for testing
- Uses rubocop-rails-omakase for Ruby style enforcement