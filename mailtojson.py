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
