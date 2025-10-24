#!/usr/bin/env python3
"""
RBAC seed script for helpdesk production deployment
Creates initial admin and tech users with proper roles
"""
import os
import sys
import getpass
from werkzeug.security import generate_password_hash

# Add the current directory to Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from server.app_production import get_db_connection, DATABASE_URL

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
        if len(password) < 8:
            print("Password must be at least 8 characters long")
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
        if len(password) < 8:
            print("Password must be at least 8 characters long")
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

def main():
    """Main seed function"""
    print("Helpdesk RBAC Seed Script")
    print("=" * 30)
    
    try:
        # Create admin user
        create_admin_user()
        
        # Ask if user wants to create tech user
        create_tech = input("\nCreate tech user? (y/N): ").strip().lower()
        if create_tech in ['y', 'yes']:
            create_tech_user()
        
        print("\nRBAC seeding completed!")
        
    except KeyboardInterrupt:
        print("\nSeeding cancelled by user.")
    except Exception as e:
        print(f"\nError during seeding: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
