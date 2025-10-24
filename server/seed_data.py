#!/usr/bin/env python3
"""
Seed script for helpdesk database with initial users and roles
"""
import os
import sys
import getpass
from werkzeug.security import generate_password_hash

# Add the current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app_production import get_db_connection, DATABASE_URL

def create_admin_user():
    """Create an admin user interactively"""
    print("Creating admin user...")
    username = input("Enter admin username (default: admin): ").strip() or "admin"
    
    # Check if user already exists
    conn = get_db_connection()
    c = conn.cursor()
    
    if DATABASE_URL.startswith('postgresql://'):
        c.execute("SELECT id FROM users WHERE username = %s", (username,))
    else:
        c.execute("SELECT id FROM users WHERE username = ?", (username,))
    
    if c.fetchone():
        print(f"User '{username}' already exists!")
        conn.close()
        return
    
    # Get password
    while True:
        password = getpass.getpass(f"Enter password for {username}: ")
        if len(password) < 6:
            print("Password must be at least 6 characters long")
            continue
        confirm = getpass.getpass("Confirm password: ")
        if password != confirm:
            print("Passwords don't match")
            continue
        break
    
    email = input("Enter email (optional): ").strip() or None
    
    # Create user
    hashed_password = generate_password_hash(password)
    
    if DATABASE_URL.startswith('postgresql://'):
        c.execute(
            "INSERT INTO users (username, email, password, role) VALUES (%s, %s, %s, %s)",
            (username, email, hashed_password, 'admin')
        )
    else:
        c.execute(
            "INSERT INTO users (username, email, password, role) VALUES (?, ?, ?, ?)",
            (username, email, hashed_password, 'admin')
        )
    
    conn.commit()
    conn.close()
    
    print(f"Admin user '{username}' created successfully!")

def create_tech_user():
    """Create a tech user interactively"""
    print("\nCreating tech user...")
    username = input("Enter tech username (default: tech): ").strip() or "tech"
    
    # Check if user already exists
    conn = get_db_connection()
    c = conn.cursor()
    
    if DATABASE_URL.startswith('postgresql://'):
        c.execute("SELECT id FROM users WHERE username = %s", (username,))
    else:
        c.execute("SELECT id FROM users WHERE username = ?", (username,))
    
    if c.fetchone():
        print(f"User '{username}' already exists!")
        conn.close()
        return
    
    # Get password
    while True:
        password = getpass.getpass(f"Enter password for {username}: ")
        if len(password) < 6:
            print("Password must be at least 6 characters long")
            continue
        confirm = getpass.getpass("Confirm password: ")
        if password != confirm:
            print("Passwords don't match")
            continue
        break
    
    email = input("Enter email (optional): ").strip() or None
    
    # Create user
    hashed_password = generate_password_hash(password)
    
    if DATABASE_URL.startswith('postgresql://'):
        c.execute(
            "INSERT INTO users (username, email, password, role) VALUES (%s, %s, %s, %s)",
            (username, email, hashed_password, 'tech')
        )
    else:
        c.execute(
            "INSERT INTO users (username, email, password, role) VALUES (?, ?, ?, ?)",
            (username, email, hashed_password, 'tech')
        )
    
    conn.commit()
    conn.close()
    
    print(f"Tech user '{username}' created successfully!")

def create_sample_tickets():
    """Create sample tickets for testing"""
    print("\nCreating sample tickets...")
    
    conn = get_db_connection()
    c = conn.cursor()
    
    # Get a user to create tickets for
    if DATABASE_URL.startswith('postgresql://'):
        c.execute("SELECT id FROM users LIMIT 1")
    else:
        c.execute("SELECT id FROM users LIMIT 1")
    
    user_row = c.fetchone()
    if not user_row:
        print("No users found. Please create users first.")
        conn.close()
        return
    
    user_id = user_row['id'] if DATABASE_URL.startswith('postgresql://') else user_row[0]
    
    sample_tickets = [
        {
            'title': 'Printer not working on 3rd floor',
            'description': 'The HP printer in the break room is showing an error and won\'t print any documents.',
            'priority': 'High',
            'status': 'Open'
        },
        {
            'title': 'Email server slow',
            'description': 'Email delivery is taking much longer than usual. Users are reporting delays.',
            'priority': 'Normal',
            'status': 'In Progress'
        },
        {
            'title': 'New employee setup',
            'description': 'Need to set up workstation and accounts for new hire starting Monday.',
            'priority': 'Low',
            'status': 'Open'
        },
        {
            'title': 'WiFi connectivity issues',
            'description': 'Several users reporting intermittent WiFi disconnections in conference room B.',
            'priority': 'High',
            'status': 'Closed'
        }
    ]
    
    for ticket in sample_tickets:
        if DATABASE_URL.startswith('postgresql://'):
            c.execute(
                "INSERT INTO tickets (title, description, priority, status, user_id, created_at, updated_at) VALUES (%s, %s, %s, %s, %s, NOW(), NOW())",
                (ticket['title'], ticket['description'], ticket['priority'], ticket['status'], user_id)
            )
        else:
            from datetime import datetime
            now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            c.execute(
                "INSERT INTO tickets (title, description, priority, status, user_id, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                (ticket['title'], ticket['description'], ticket['priority'], ticket['status'], user_id, now, now)
            )
    
    conn.commit()
    conn.close()
    
    print(f"Created {len(sample_tickets)} sample tickets!")

def main():
    """Main seed function"""
    print("Helpdesk Database Seed Script")
    print("=" * 40)
    
    try:
        # Create admin user
        create_admin_user()
        
        # Ask if user wants to create tech user
        create_tech = input("\nCreate tech user? (y/N): ").strip().lower()
        if create_tech in ['y', 'yes']:
            create_tech_user()
        
        # Ask if user wants to create sample tickets
        create_tickets = input("\nCreate sample tickets? (y/N): ").strip().lower()
        if create_tickets in ['y', 'yes']:
            create_sample_tickets()
        
        print("\nSeeding completed!")
        
    except KeyboardInterrupt:
        print("\nSeeding cancelled by user.")
    except Exception as e:
        print(f"\nError during seeding: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
