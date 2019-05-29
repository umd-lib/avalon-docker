#/bin/bash
BUCKET=${DROPBOX_SYNC_BUCKET:-avalon-pilot-ingest}
DROPBOX_DIR=${SETTINGS__DROPBOX__PATH:-/masterfiles/dropbox}
CLIENT_NAME=${DROPBOX_SYNC_CLIENT_NAME:-developer_workstation}
TAG_FOR_DELETION=${TAG_FOR_DELETION_ON_SYNC:-false}

function log_suffix { echo $CLIENT_NAME"_"`date -u +"%Y%m%dT%H%M%S"`.log; }

function decho { echo [`date -u +"%Y-%m-%dT%H:%M:%S.%N"`] S3-DROPBOX-SYNC: $1; }

function list_s3_objects { aws s3api list-objects --bucket $BUCKET --prefix $1; }

function tag_s3_object { aws s3api put-object-tagging --bucket $BUCKET --key $1 --tagging "TagSet=$2"; }

function get_s3_object_tags { aws s3api get-object-tagging --bucket $BUCKET --key $1; }

function get_s3_object_tag { get_s3_object_tags $1 | jq '.TagSet[] | select(.Key == "'$2'")'; }

function get_s3_object_tag_value { get_s3_object_tag $1 $2 | jq -r .Value; }

function is_processed { if [ "$(get_s3_object_tag_value $1 $CLIENT_NAME)" = "processed" ]; then return 0; else return 1; fi; }

mp3_files_synced=0
csv_files_synced=0

# Get list of all files in the ingest bucket and store the keys in a tmp file
list_s3_objects dropbox/ | jq -r .Contents[].Key > /tmp/ap_ingest-s3_keys

# 1. Sync MP3 files listed in the s3_keys file
while read mp3_filename; do
  decho "Processing $mp3_filename"
  if ! is_processed $mp3_filename; then
    # Download MP3 file to the correct location in local dropbox directory
    local_filename="$DROPBOX_DIR/${mp3_filename/dropbox\///}"
    decho "Sync MP3: s3://$BUCKET/$mp3_filename to $local_filename!"
    aws s3 cp s3://$BUCKET/$mp3_filename $local_filename
    copy_status=$?
    if [ $copy_status -eq 0 ]; then
      mp3_files_synced=$((mp3_files_synced+1))
      # Tag MP3 file in S3 dropbox as processed by this client.
      tag_s3_object $mp3_filename "[{Key=$CLIENT_NAME,Value=processed}]"
      # Add can_expire tag to file which is used by the S3 life-cycle-policy
      # to delete it after set number of days, if TAG_FOR_DELETION is true
      if [ "$TAG_FOR_DELETION" = true ]; then tag_s3_object $mp3_filename '[{Key=can_expire,Value=true}]'; fi;
    fi
  else
    decho "Skipping! File is be already processed by this client: $CLIENT_NAME"
  fi
done < <(cat /tmp/ap_ingest-s3_keys | grep .mp3$)

# 2. Sync Batch Manifest (.csv) files listed in the s3_keys file
while read csv_filename; do
  decho "Processing $csv_filename" | tee /tmp/batch_manifest_log
  if ! is_processed $csv_filename; then
    dir_name=`dirname ${csv_filename/dropbox\///}`
    all_batch_files_exist=true
    # Download manifest file to tmp location
    aws s3 cp s3://$BUCKET/$csv_filename /tmp/batch_manifest
    copy_status=$?
    if [ $copy_status -eq 0 ]; then
      # Verify that all MP3 files specified in the manifest exist locally
      while read mp3_file_path; do
        local_filepath="$DROPBOX_DIR/$dir_name/$mp3_file_path"
        if [ ! -f "$local_filepath" ]; then
          all_batch_files_exist=false
          decho "MP3 File specified in manifest does not exist locally: $local_filepath" | tee -a /tmp/batch_manifest_log
        fi
      done < <(tail -n+2 /tmp/batch_manifest | csvcut -c File | tail -n+2)
      if [ "$all_batch_files_exist" = true ]; then
        # Move manifest file to correct location
        local_filename="$DROPBOX_DIR/${csv_filename/dropbox\///}"
        decho "Sync manifest: s3://$BUCKET/$csv_filename to $local_filename!" | tee -a /tmp/batch_manifest_log
        mkdir -p `dirname $local_filename`
        mv /tmp/batch_manifest $local_filename
        csv_files_synced=$((csv_files_synced+1))
        # Add can_expire tag to file which is used by the S3 life-cycle-policy
        # to delete it after set number of days, if TAG_FOR_DELETION is true
        if [ "$TAG_FOR_DELETION" = true ]; then
          decho "Tagging $csv_filename for deletion!" | tee -a /tmp/batch_manifest_log
          tag_s3_object $csv_filename '[{Key=can_expire,Value=true}]';
        fi
      else
        decho "Skipping sync of $csv_filename as some of its batch file(s) are missing!" | tee -a /tmp/batch_manifest_log
      fi
      # Tag manifest file in S3 dropbox as processed by this client.
      decho "Tagging $csv_filename as 'processed'! The file will not be processed by '$CLIENT_NAME' again unless updated!" | tee -a /tmp/batch_manifest_log
      tag_s3_object $csv_filename "[{Key=$CLIENT_NAME,Value=processed}]"
    fi
    # Copy manifest log to S3 bucket logs folder
    s3_log_file_name=${csv_filename/dropbox/logs}_$(log_suffix)
    aws s3 cp /tmp/batch_manifest_log s3://$BUCKET/$s3_log_file_name
  else
    decho "Skipping! File is be already processed by this client: $CLIENT_NAME"
  fi
done < <(cat /tmp/ap_ingest-s3_keys | grep .csv$)

rm -f /tmp/ap_ingest-s3_keys /tmp/batch_manifest  /tmp/batch_manifest_log

decho "MP3 files synced: $mp3_files_synced"
decho "Batch Manifest synced: $csv_files_synced"
