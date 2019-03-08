#/bin/bash
BUCKET=${DROPBOX_SYNC_BUCKET:-avalon-pilot-ingest}
DROPBOX_DIR=/home/app/avalon/dropbox

function decho { echo [`date -u +"%Y-%m-%dT%H:%M:%S.%N"`] S3-DROPBOX-SYNC: $1; }

mp3_files_synced=0
csv_files_synced=0

# Get list of all files in the ingest bucket and store the keys in a tmp file
aws s3api list-objects --bucket $BUCKET --prefix dropbox/ | jq -r .Contents[].Key > /tmp/ap_ingest-s3_keys

# 1. Sync MP3 files listed in the s3_keys file
while read mp3_filename; do
  decho "Processing $mp3_filename"
  # Download MP3 file to the correct location in local dropbox directory
  local_filename="$DROPBOX_DIR/${mp3_filename/dropbox\///}"
  decho "Sync MP3: s3://$BUCKET/$mp3_filename to $local_filename!"
  aws s3 cp s3://$BUCKET/$mp3_filename $local_filename
  copy_status=$?
  if [ $copy_status -eq 0 ]; then
    mp3_files_synced=$((mp3_files_synced+1))
    # Move MP3 file from S3 dropbox folder to S3 archives folder.
    new_name=${mp3_filename/dropbox/archives}
    decho "Archive s3://$BUCKET/$mp3_filename to s3://$BUCKET/$new_name"
    aws s3 mv s3://$BUCKET/$mp3_filename s3://$BUCKET/$new_name
    # Add can_expire tag to archived MP3 file which is used by the S3 life-cycle-policy
    # to delete it after set number of days
    aws s3api put-object-tagging --bucket $BUCKET --key $new_name --tagging 'TagSet=[{Key=can_expire,Value=true}]'
  fi
done < <(cat /tmp/ap_ingest-s3_keys | grep .mp3$)

# 2. Sync Batch Manifest (.csv) files listed in the s3_keys file
while read csv_filename; do
  decho "Processing $csv_filename"
  dir_name=`dirname $csv_filename`
  all_batch_files_exist=true
  # Download manifest file to tmp location
  aws s3 cp s3://$BUCKET/$csv_filename /tmp/batch_manifest
  copy_status=$?
  if [ $copy_status -eq 0 ]; then
    # Verify that all MP3 files specified in the manifest exist locally
    while read mp3_file_path; do
      if [ ! -f "$dir_name/$mp3_file_path" ]; then
        all_batch_files_exist=false
        decho "MP3 File specified in manifest does not exist locally: $dir_name/$mp3_file_path"
      fi
    done < <(tail -n+2 /tmp/batch_manifest | csvcut -c File | tail -n+2)
    if [ "$all_batch_files_exist" = true ]; then
      # Move manifest file to correct location
      local_filename="$DROPBOX_DIR/${csv_filename/dropbox\///}"
      decho "Sync manifest: s3://$BUCKET/$csv_filename to $local_filename!"
      mkdir -p `dirname $local_filename`
      mv /tmp/batch_manifest $local_filename
      csv_files_synced=$((csv_files_synced+1))
      # Move manifest file from S3 dropbox folder to S3 archives folder
      new_name=${csv_filename/dropbox/archives}
      decho "Archive s3://$BUCKET/$csv_filename to s3://$BUCKET/$new_name"
      aws s3 mv s3://$BUCKET/$csv_filename s3://$BUCKET/$new_name
    else
      decho "Skipping sync of $csv_filename as some of its batch file(s) are missing!"
    fi
  fi
done < <(cat /tmp/ap_ingest-s3_keys | grep .csv$)

rm -f /tmp/ap_ingest-s3_keys /tmp/batch_manifest

decho "MP3 files synced: $mp3_files_synced"
decho "Batch Manifest synced: $csv_files_synced"
