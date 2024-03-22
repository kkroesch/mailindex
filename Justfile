MAIL_BASE_DIR := "/Volumes/backup/karsten/mail"
MAIL_WORK_DIR := "Sent/cur"
SOLR_BASE_URL := "http://bio:8983/solr/mail_archive"

[confirm]
import:
    #!/bin/bash
    count=0
    find "{{MAIL_BASE_DIR}}/{{MAIL_WORK_DIR}}" -name "*.mail*" |
    while read -r mail
    do
        echo "Working on $mail"
        cat $mail |
        ./mailtojson.py |
        jq -s '{subject, "return-path", "x-originating-ip", received, from, to, "content-language", body}' |
        curl "{{SOLR_BASE_URL}}/update/json/docs?commit=true" \
            -H "Content-Type: application/json" \
            --data-binary @- |
        jq -r '.. | .status? // empty'
    done
    echo "${count} mails imported."


convert:
    #!/usr/bin/env python3

    import sys
    import json
    from mailparser import parse_from_string

    # E-Mail-Daten von STDIN lesen
    eml_data = sys.stdin.read()

    # EML-Daten parsen
    mail = parse_from_string(eml_data)

    # JSON-String anzeigen
    print(mail.mail_json)


serve:
    #!/usr/bin/env python3

    from flask import Flask, request, send_from_directory
    import requests

    app = Flask(__name__)

    # Statische HTML-Datei ausliefern
    @app.route('/')
    def index():
        return send_from_directory('.', 'mail.html')  # Stelle sicher, dass 'index.html' im gleichen Verzeichnis liegt

    # Suchanfragen an Solr weiterleiten
    @app.route('/search')
    def search():
        query = request.args.get('q', '')  # Standardwert ist ein leerer String, falls kein Query-Parameter übergeben wurde
        solr_url = f'http://bio:8983/solr/mail_archive/select?q=body:{query}*'
        response = requests.get(solr_url)
        return response.json()  # Gibt die JSON-Antwort von Solr zurück

    if __name__ == '__main__':
        app.run(debug=True)  # Startet den Server im Debug-Modus
