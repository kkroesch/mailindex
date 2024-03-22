MAIL_BASE_DIR := "/Volumes/backup/karsten/mail"
SOLR_BASE_URL := "http://bio:8983/solr/mail_archive"

[confirm]
import workdir:
    #!/bin/bash
    count=0
    find "{{MAIL_BASE_DIR}}/{{workdir}}" -name "*.mail*" |
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
    from os import getenv

    app = Flask(__name__)

    # Statische HTML-Datei ausliefern
    @app.route('/')
    def index():
        return send_from_directory(getenv('PWD'), 'mail.html')

    # Suchanfragen an Solr weiterleiten
    @app.route('/search')
    def search():
        query = request.args.get('q', '')  # Standardwert ist ein leerer String, falls kein Query-Parameter übergeben wurde
        solr_url = f'http://bio:8983/solr/mail_archive/select?q=body:{query}*'
        response = requests.get(solr_url)
        return response.json()  # Gibt die JSON-Antwort von Solr zurück

    if __name__ == '__main__':
        app.run(debug=True, port=8080)  # Startet den Server im Debug-Modus
