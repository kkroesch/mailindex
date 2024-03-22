MAIL_BASE_DIR="/Volumes/backup/karsten/mail"
MAIL_WORK_DIR="Sent/cur"
SOLR_BASE_URL="http://bio:8983/solr/mail_archive"


count=0
find "${MAIL_BASE_DIR}/${MAIL_WORK_DIR}" -name "*.mail*" |
while read -r mail
do
    echo "Working on $mail"
    cat $mail |
    ./mailtojson.py |
    jq -s '{subject, "return-path", "x-originating-ip", received, from, to, "content-language", body}' |
    curl "${SOLR_BASE_URL}/update/json/docs?commit=true" \
        -H "Content-Type: application/json" \
        --data-binary @- |
    jq -r '.. | .status? // empty'

done
