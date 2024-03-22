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
