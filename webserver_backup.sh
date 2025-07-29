#!/bin/bash
# script to backup the webserver

# define the backup directory
BACKUP_DIR="/var/www/html/blog"

# define the date format
DATE=$(date +%Y-%m-%d)

# Create a zip archive named xfusioncorp_blog.zip of /var/www/html/blog directory
zip -r xfusioncorp_blog.zip $BACKUP_DIR

# Copy the zip archive to the backup server
cp xfusioncorp_blog.zip /backup/

cd /backup

scp xfusioncorp_blog.zip clint@stbkp01:/backup/




