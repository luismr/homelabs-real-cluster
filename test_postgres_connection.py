#!/usr/bin/env python3
"""
Test script to connect to PostgreSQL from outside the cluster
"""
import psycopg2
import sys
import os

# Connection parameters
HOST = os.getenv("POSTGRES_HOST", "192.168.7.200")
PORT = int(os.getenv("POSTGRES_PORT", "30432"))
DATABASE = os.getenv("POSTGRES_DB", "carimbo")
USER = os.getenv("POSTGRES_USER", "postgres")
PASSWORD = os.getenv("POSTGRES_PASSWORD", "")

if not PASSWORD:
    print("ERROR: POSTGRES_PASSWORD environment variable is not set")
    print("Set it with: export POSTGRES_PASSWORD='your-password'")
    sys.exit(1)

print(f"Attempting to connect to PostgreSQL...")
print(f"  Host: {HOST}")
print(f"  Port: {PORT}")
print(f"  Database: {DATABASE}")
print(f"  User: {USER}")
print()

try:
    # Try to connect
    conn = psycopg2.connect(
        host=HOST,
        port=PORT,
        database=DATABASE,
        user=USER,
        password=PASSWORD,
        connect_timeout=10
    )
    
    print("✓ Connection successful!")
    
    # Test query
    cursor = conn.cursor()
    cursor.execute("SELECT version();")
    version = cursor.fetchone()[0]
    print(f"✓ PostgreSQL version: {version}")
    
    # Check pgvector extension
    cursor.execute("SELECT extname, extversion FROM pg_extension WHERE extname = 'vector';")
    result = cursor.fetchone()
    if result:
        print(f"✓ pgvector extension installed: {result[1]}")
    else:
        print("⚠ pgvector extension not found")
    
    # Check current connection info
    cursor.execute("SELECT inet_server_addr(), inet_server_port(), current_database(), current_user;")
    conn_info = cursor.fetchone()
    print(f"✓ Connection info:")
    print(f"    Server address: {conn_info[0]}")
    print(f"    Server port: {conn_info[1]}")
    print(f"    Database: {conn_info[2]}")
    print(f"    User: {conn_info[3]}")
    
    cursor.close()
    conn.close()
    print("\n✓ All tests passed!")
    sys.exit(0)
    
except psycopg2.OperationalError as e:
    print(f"✗ Connection failed: {e}")
    print("\nTroubleshooting:")
    print("1. Check if NodePort service is running: kubectl get svc -n carimbo-vip postgres-nodeport")
    print("2. Check if PostgreSQL pod is running: kubectl get pods -n carimbo-vip -l app=postgres")
    print("3. Check pg_hba.conf: kubectl exec -n carimbo-vip <pod-name> -- cat /var/lib/postgresql/data/pg_hba.conf")
    print("4. Verify password: kubectl get secret -n carimbo-vip postgres-password -o jsonpath='{.data.password}' | base64 -d")
    sys.exit(1)
    
except Exception as e:
    print(f"✗ Unexpected error: {e}")
    sys.exit(1)

