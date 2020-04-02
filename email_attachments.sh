#!/bin/bash

### Notes ###
# A script to send zero or more attachments with mime-encoding from any email address 
# to any email address.
#
# Script was adapted from the one posted on:
#	https://backreference.org/2013/05/22/send-email-with-attachments-from-script-or-command-line/
#
# The latest version of this script can be found at:
#	https://www.github.com/jaburt
#
# This script has been checked for bugs with the online ShellCheck website:
#	https://www.shellcheck.net/
### End ###

### Parameter count check ###
# Check that a minimum of 4 parameters are passed when the script executes, 
# otherwise display an error.  Note: Only useful if run from the CLI.
if [ "$#" -lt 4 ] ; then
  echo "Usage: ${0} from@email to@email \"subject of email\" \"body of email\" [attachment1 [...]]"
  exit 1
fi
### End ###

### System/Script defined Variables ###
# email requirements, from the first 4 parameters.
from="$1"
to="$2"
subject="$3"
body="$4"

# Random'ish (see https://tools.ietf.org/html/rfc2046#section-5.1.1) boundary text
boundary="ZZ_/afg6432dfgkl.94531q"

# Declare an array for the list of attachments.
declare -a attachments

# Reduce the amount of parameters by 4, and then place all remaining parameters in 
# the array.
shift 4
attachments=("$@")
### End ###

### Determine MIME type of attachments ###
# We need to determine the MIME type of the file given as a parameter. A simple way
# to implement it is to use the file utility with its --mime-type option.
get_mimetype()
{
# Warning: This assumes that the passed file exists
  file --mime-type "$1" | sed 's/.*: //'
}
### End ###

### Create the "email"
{

# Build the email headers
printf '%s\n' "From: $from
To: $to
Subject: $subject
Mime-Version: 1.0
Content-Type: multipart/mixed; boundary=\"$boundary\"

--${boundary}
Content-Type: text/plain; charset=\"US-ASCII\"
Content-Transfer-Encoding: 7bit
Content-Disposition: inline

$body
"

# Now loop over the attachments, guess the type
# and produce the corresponding part, encoded with base64
for file in "${attachments[@]}" ; do

  [ ! -f "$file" ] && echo "Warning: attachment $file not found, skipping" >&2 && continue

  mimetype=$(get_mimetype "$file")

  printf '%s\n' "--${boundary}
Content-Type: $mimetype
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename=\"$file\"
"

  base64 "$file"
  echo
done

# Print final boundary with closing --
printf '%s\n' "--${boundary}--"

} | sendmail -t -oi # one may also use -f here to set the envelope-from
### End ###
