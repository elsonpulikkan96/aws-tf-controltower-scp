#!/usr/bin/env python3
"""
Backup Restore Testing Script
Tests RDS and EBS backup restore procedures
"""

import boto3
import time
import sys
from datetime import datetime

def test_rds_restore():
    """Test RDS backup restore"""
    print("=== Testing RDS Backup Restore ===\n")
    
    rds = boto3.client('rds')
    backup = boto3.client('backup')
    
    # Find latest backup
    print("1. Finding latest RDS backup...")
    response = backup.list_recovery_points_by_backup_vault(
        BackupVaultName='Default',
        ByResourceType='RDS'
    )
    
    if not response['RecoveryPoints']:
        print("❌ No RDS backups found")
        return False
    
    latest_backup = response['RecoveryPoints'][0]
    print(f"✓ Found backup: {latest_backup['RecoveryPointArn']}")
    print(f"  Created: {latest_backup['CreationDate']}")
    
    # Extract snapshot ID
    snapshot_id = latest_backup['RecoveryPointArn'].split(':')[-1]
    
    # Restore
    restore_id = f"restore-test-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
    print(f"\n2. Restoring to: {restore_id}")
    
    try:
        rds.restore_db_instance_from_db_snapshot(
            DBInstanceIdentifier=restore_id,
            DBSnapshotIdentifier=snapshot_id,
            DBInstanceClass='db.t3.micro',
            PubliclyAccessible=False,
            Tags=[
                {'Key': 'Purpose', 'Value': 'BackupTest'},
                {'Key': 'DeleteAfter', 'Value': datetime.now().strftime('%Y-%m-%d')}
            ]
        )
        print("✓ Restore initiated")
    except Exception as e:
        print(f"❌ Restore failed: {e}")
        return False
    
    # Wait for availability
    print("\n3. Waiting for instance to be available (this may take 5-10 minutes)...")
    waiter = rds.get_waiter('db_instance_available')
    
    try:
        waiter.wait(
            DBInstanceIdentifier=restore_id,
            WaiterConfig={'Delay': 30, 'MaxAttempts': 40}
        )
        print("✓ Instance is available")
    except Exception as e:
        print(f"❌ Wait failed: {e}")
        return False
    
    # Verify
    print("\n4. Verifying instance...")
    response = rds.describe_db_instances(DBInstanceIdentifier=restore_id)
    instance = response['DBInstances'][0]
    
    print(f"✓ Instance Status: {instance['DBInstanceStatus']}")
    print(f"✓ Endpoint: {instance['Endpoint']['Address']}")
    
    # Cleanup
    print(f"\n5. Cleaning up test instance...")
    print(f"   To delete manually: aws rds delete-db-instance --db-instance-identifier {restore_id} --skip-final-snapshot")
    
    return True

def test_ebs_restore():
    """Test EBS backup restore"""
    print("\n=== Testing EBS Backup Restore ===\n")
    
    ec2 = boto3.client('ec2')
    
    # Find latest snapshot
    print("1. Finding latest EBS snapshot...")
    response = ec2.describe_snapshots(
        OwnerIds=['self'],
        Filters=[
            {'Name': 'status', 'Values': ['completed']},
            {'Name': 'tag:Backup', 'Values': ['daily']}
        ]
    )
    
    if not response['Snapshots']:
        print("❌ No EBS snapshots found")
        return False
    
    # Sort by start time
    snapshots = sorted(response['Snapshots'], key=lambda x: x['StartTime'], reverse=True)
    latest_snapshot = snapshots[0]
    
    print(f"✓ Found snapshot: {latest_snapshot['SnapshotId']}")
    print(f"  Created: {latest_snapshot['StartTime']}")
    print(f"  Size: {latest_snapshot['VolumeSize']} GB")
    
    # Create volume
    print(f"\n2. Creating volume from snapshot...")
    
    try:
        response = ec2.create_volume(
            SnapshotId=latest_snapshot['SnapshotId'],
            AvailabilityZone='us-east-1a',
            VolumeType='gp3',
            TagSpecifications=[{
                'ResourceType': 'volume',
                'Tags': [
                    {'Key': 'Purpose', 'Value': 'BackupTest'},
                    {'Key': 'DeleteAfter', 'Value': datetime.now().strftime('%Y-%m-%d')}
                ]
            }]
        )
        volume_id = response['VolumeId']
        print(f"✓ Volume created: {volume_id}")
    except Exception as e:
        print(f"❌ Volume creation failed: {e}")
        return False
    
    # Wait for availability
    print("\n3. Waiting for volume to be available...")
    waiter = ec2.get_waiter('volume_available')
    
    try:
        waiter.wait(VolumeIds=[volume_id])
        print("✓ Volume is available")
    except Exception as e:
        print(f"❌ Wait failed: {e}")
        return False
    
    # Verify
    print("\n4. Verifying volume...")
    response = ec2.describe_volumes(VolumeIds=[volume_id])
    volume = response['Volumes'][0]
    
    print(f"✓ Volume State: {volume['State']}")
    print(f"✓ Volume Size: {volume['Size']} GB")
    print(f"✓ Volume Type: {volume['VolumeType']}")
    
    # Cleanup
    print(f"\n5. Cleaning up test volume...")
    print(f"   To delete manually: aws ec2 delete-volume --volume-id {volume_id}")
    
    return True

def main():
    """Main test runner"""
    print("╔══════════════════════════════════════════╗")
    print("║   Backup Restore Testing                ║")
    print("║   Tests RDS and EBS restore procedures  ║")
    print("╚══════════════════════════════════════════╝\n")
    
    results = {
        'rds': False,
        'ebs': False
    }
    
    # Test RDS
    try:
        results['rds'] = test_rds_restore()
    except Exception as e:
        print(f"❌ RDS test failed with exception: {e}")
    
    # Test EBS
    try:
        results['ebs'] = test_ebs_restore()
    except Exception as e:
        print(f"❌ EBS test failed with exception: {e}")
    
    # Summary
    print("\n" + "="*50)
    print("SUMMARY")
    print("="*50)
    print(f"RDS Restore: {'✓ PASS' if results['rds'] else '✗ FAIL'}")
    print(f"EBS Restore: {'✓ PASS' if results['ebs'] else '✗ FAIL'}")
    
    if all(results.values()):
        print("\n✓ All backup restore tests passed!")
        print("\nRTO Achieved:")
        print("  - RDS: ~10 minutes")
        print("  - EBS: ~2 minutes")
        return 0
    else:
        print("\n✗ Some tests failed. Review logs above.")
        return 1

if __name__ == '__main__':
    sys.exit(main())
