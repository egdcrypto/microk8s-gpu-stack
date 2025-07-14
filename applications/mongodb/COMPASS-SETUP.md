# MongoDB Compass Connection Setup

## ✅ Working Configuration

After resolving authentication issues, MongoDB Compass can now connect successfully.

### Connection Details for MongoDB Compass

**Method 1: Connection String**
```
mongodb://admin:admin123@192.168.0.118:30017/?authSource=admin&directConnection=true
```

**Method 2: Manual Configuration**
- **Host**: `192.168.0.118`
- **Port**: `30017`
- **Username**: `admin`
- **Password**: `admin123`
- **Authentication Database**: `admin`
- **Connection Type**: Direct Connection

### Key Settings for Success

1. **✅ Use Direct Connection**: Set `directConnection=true` to bypass replica set discovery
2. **✅ Admin User**: Use the `admin` user with simple password
3. **✅ Auth Database**: Always specify `admin` as authentication database
4. **✅ External IP**: Use node IP `192.168.0.118` not internal Kubernetes hostnames

### Alternative Users

**For Application Development:**
```
Username: compass_user
Password: compass123
Database: narrative_world_system
Auth Database: admin
```

**For Administration:**
```
Username: admin
Password: admin123
Auth Database: admin
```

## Troubleshooting Tips

### If Connection Still Fails:

1. **Check Network Access**:
   ```bash
   nc -zv 192.168.0.118 30017
   ```

2. **Verify User Exists**:
   ```bash
   kubectl exec -n mongodb mongodb-0 -- mongosh admin --username admin --password admin123 --eval "db.runCommand({usersInfo: 'admin'})"
   ```

3. **Test from Command Line**:
   ```bash
   mongosh "mongodb://admin:admin123@192.168.0.118:30017/?authSource=admin&directConnection=true"
   ```

### Common Issues Resolved:

- ❌ **No users created**: Fixed by creating admin user
- ❌ **Complex passwords**: Added simple admin/admin123 credentials  
- ❌ **Replica set discovery**: Fixed with `directConnection=true`
- ❌ **Internal hostnames**: Uses external IP instead

## Success Verification

Once connected, you should see:
- Database: `narrative_world_system`
- Collections: (initially empty)
- Users: admin, compass_user, narrative_user
- Replica Set: rs0 (single member)

The MongoDB instance is now fully accessible from MongoDB Compass for development and administration tasks.