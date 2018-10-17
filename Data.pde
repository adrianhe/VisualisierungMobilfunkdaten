/* Klasse Data um die CSV-Dateien mit den Verbindungsdaten einzulesen,
 *  diese mithilfe einer Online Abfrage mit den GPS-Koordinaten der Funkzellen zu ergänzen
 *  und ein Tabellenarray aller Datensätze auszugeben. Struktur der Tabellen:
 * Datum und Uhrzeit | Dienst | Richtung | MCC | MNC | Mobilfunkstandard | LAC | CellID | PSC | Signalstärke | Breitengrad | Längengrad
 */

class Data {
  String[] url; //  Pfade der Datensätze 
  Table[] data; // Datensätze als Tabellen
  int fileCount; // Anzahl der Dateien
  Table getGPSTable; // getGPSTable speichert jede Funkzelle nur einmal, um die Abfragelast an die Datenbank zu minimieren
  Boolean[] gpsUrl; // Wurden die Datensätze schon einmal verarbeitet?

  public Data(String[] url, int fileCount) { // Konstruktor
    this.fileCount = fileCount;
    this.url = url;
    data = new Table[url.length];
  }  

  public Table[] startTransition() { // Umwandlung der Dateien in Tabellen
    for (int id = 0; id<fileCount; id++) { // Jede Datei durchgehen
      data[id] = loadTable(url[id], "header"); // Datei als Tabelle laden, ohne Header
    }
    checkConverted();  // Weiter mit dem Überprüfen der Dateien
    return data; // Am Ende die Tabellen ausgeben
  }

  void checkConverted() { // Wurden die Datensätze schon einmal verarbeitet?
    gpsUrl = new Boolean[fileCount]; // Speichert Antwort darauf
    for (int id=0; id < fileCount; id++) { // Jeden Datensatz durchlaufen
      if (data[id].getColumnCount() >= 12) { // Hat die Tabelle 12 oder mehr Spalten?
        gpsUrl[id] = (data[id].getColumnTitle(10).equals("Breitengrad") && data[id].getColumnTitle(11).equals("Längengrad")); // Wenn die Bezeichnung der 11. und 12. Spalten stimmen, wurde die Datei schon verarbeitet
      } else gpsUrl[id] = false; // Ansonsten wurde die Datei noch nicht verarbeitet
    }

    // Ist der Server online zum Abfragen der Koordinaten? http://kasi.berlin:8888/TowerAPI/
    if (!APIToken.equals("xx-xx-xx-xx-xx") && loadStrings("https://eu1.unwiredlabs.com/v2/balance.php?token="+APIToken)[0].contains("ok")) //check for valid API Token
      createHelpTable(); // Weiter mit dem Erstellen der Hilfstablle
    else {
      println("API-Token ist nicht gültig.");
      JOptionPane.showMessageDialog(null, "Es wurde kein gültiger API-Token gefunden. (Zeile 19)", "API-Key ungültig", JOptionPane.WARNING_MESSAGE);  
      for (int id=0; id < fileCount; id++) { // Jeden Datensatz durchlaufen
        if (!gpsUrl[id]) {
          data[id].clearRows();
        }
      }
    }
  }

  void createHelpTable() { // Erzeugt eine Hilfstabelle aller Datensätze, in der jede Funkzelle nur einmal auftaucht
    getGPSTable = new Table(); // Neue Tabelle
    getGPSTable.addColumn("mcc", Table.STRING); // 6 Spalten mit Typ String hinzufügen
    getGPSTable.addColumn("mnc", Table.STRING);
    getGPSTable.addColumn("radio", Table.STRING);
    getGPSTable.addColumn("lac", Table.STRING);
    getGPSTable.addColumn("CellID", Table.STRING);
    getGPSTable.addColumn("psc", Table.STRING);
    getGPSTable.addColumn("signal", Table.STRING);
    getGPSTable.addColumn("lat", Table.STRING);
    getGPSTable.addColumn("lon", Table.STRING);

    for (int id = 0; id < fileCount; id++) { // Jeden Datensatz durchlaufen
      if (!gpsUrl[id]) { // Wenn die Datensätze vorher noch nicht verarbeitet wurden
        for (int k = 0; k < data[id].getRowCount(); k++) { // Jede Zeile des aktuellen Datensatzes überprüfen
          String t_mcc = data[id].getString(k, 3); // MCC, MNC, LAC und CellID der Zeile temporär speichern
          String t_mnc = data[id].getString(k, 4);
          String t_radio = data[id].getString(k, 5);
          String t_lac = data[id].getString(k, 6);
          String t_cellID = data[id].getString(k, 7);
          String t_psc = data[id].getString(k, 8);
          String t_signal = data[id].getString(k, 9);
          

          boolean insertCell = true; // Standardmäßig davon ausgehen, dass die Funkzelle noch in die Hilfstabelle eiongefügt werden muss

          for (TableRow cellRow : getGPSTable.matchRows(t_cellID, "CellID")) { // Jede Zeile der Hilfstabelle betrachten, wo die CellID übereinstimmt
            // Wenn auch LAC, Radio, PSC und Signalstärke übereinstimmen
            if (cellRow.getString("lac").equals(t_lac) && cellRow.getString("mcc").equals(t_mcc) && cellRow.getString("mnc").equals(t_mnc) && cellRow.getString("radio").equals(t_radio) && cellRow.getString("psc").equals(t_psc) && cellRow.getString("signal").equals(t_signal)) {
              insertCell = false; // Die Funkzelle existiert schon in der Hilfstabelle
              break; // for-Schleife kann beendet werden
            }
            
          }

// Funkzelle in Hilfstabelle einfügen falls noch nicht vorhanden
          if (insertCell)  { 
            TableRow newRow = getGPSTable.addRow(); // Neue Zeile erstellen
            newRow.setString("mcc", t_mcc); // Zeile mit temporären Daten der Zeile des Datensatzes füllen
            newRow.setString("mnc", t_mnc);
            newRow.setString("radio", t_radio);
            newRow.setString("lac", t_lac);
            newRow.setString("CellID", t_cellID);
            newRow.setString("psc", t_psc);
            newRow.setString("signal", t_signal);
            newRow.setString("lat", ""); // Breiten- und Längengrad bleiben nocht leer
            newRow.setString("lon", "");
          }
        }
      }
    } 
    getGPS(); // Weiter mit dem Abrufen der Koordinaten für die einzelnen Funkzellen
  }  

  void getGPS() { // Hilfstabelle mit Koordinaten vervollständigen

    String mcc, mnc, radio, lac, cellID, psc, signal, lat, lon; // Tabellenangaben
    processing.data.JSONObject request = new processing.data.JSONObject(); //JSON Objekt für Serveranfrage
    processing.data.JSONArray cells = new processing.data.JSONArray(); //Hilfsobjekte für das Anfrageformat
    processing.data.JSONObject cellArray = new processing.data.JSONObject();
    request.setString("token", APIToken); //API Key der Anfrage hinzufügen
    request.setInt("Address", 0); // Keine Adresse als Teil der Antwort
    String baseURL = "https://eu1.unwiredlabs.com/v2/process.php"; // URL zur Verarbeitung der Serveranfrage

    int numberOfRows = getGPSTable.getRowCount(); //Einmalig zählen wie viele Datensätze geladen werden müssen

    for (int id = 0; id < numberOfRows; id++) { // Für jede Zeile der Hilfstabelle

      // Ladefortschritt anzeigen
      println("Für "+(id*100/numberOfRows)+"% der Funkzellen die Koordinaten geladen");

      mcc = getGPSTable.getString(id, 0); // Daten aus der Tabelle lesen
      mnc = getGPSTable.getString(id, 1);
      radio = getGPSTable.getString(id, 2);
      lac = getGPSTable.getString(id, 3);
      cellID = getGPSTable.getString(id, 4);
      psc = getGPSTable.getString(id, 5);
      signal = getGPSTable.getString(id, 6);
      // Webanfrage, um die Koordinaten der Funkzelle zu erhalten 
      if (!mcc.equals("ERROR") && !mnc.equals("ERROR") && !radio.equals("ERROR") && !cellID.equals("ERROR") && !cellID.equals("-1") && !cellID.equals("2147483647") && !lac.equals("ERROR")) { // CellID und LAC müssen vorhanden sein

        // HTTP Verbindung für Webanfrage
        HttpURLConnection conn = null;

        //Verbindung aufbauen
        try {
          URL url = new URL(baseURL);
          conn = (HttpURLConnection) url.openConnection();
          try {
            conn.setRequestMethod("POST"); //POST nutzen
            conn.setDoOutput(true); //Sachen senden
            conn.setUseCaches(false); //Kein Cache
            conn.setAllowUserInteraction(false); // Keine Nutzerinteraktion
            conn.setRequestProperty("Content-Type", "text/xml");
          }
          catch (ProtocolException e) {
          }

          // Anfrage an Datenbank von UnwiredLabs formulieren
          request.setInt("mcc", int(mcc));
          request.setInt("mnc", int(mnc));
          request.setString("radio", radio); //gsm umts cdma oder lte
          cellArray.setInt("lac", int(lac));
          cellArray.setInt("cid", int(cellID));
          if (radio.equals("lte") || radio.equals("umts")) cellArray.setInt("psc", int(psc));
          if (radio.equals("lte")) cellArray.setInt("signal", int(signal)); //rssi rssp in dBm
          //Anfrage zusammenführen
          cells.setJSONObject(0, cellArray);
          request.setJSONArray("cells", cells);
          // Anfrage abschicken
          OutputStream out = conn.getOutputStream();

          try {          
            OutputStreamWriter wr = new OutputStreamWriter(out);
            wr.write(request.toString());
            wr.flush();
            wr.close();
          }
          catch (IOException e) {
          }
          finally { // close the output stream
            if (out != null);
            out.close();
          }

          //Antwort verarbeiten
          StringBuilder response = new StringBuilder();
          InputStream in = conn.getInputStream();
          try {
            BufferedReader rd  = new BufferedReader(new InputStreamReader(in));
            String inputStr;
            while ((inputStr = rd.readLine()) != null) {
              response.append(inputStr);
            }
            rd.close(); 
            processing.data.JSONObject jsonResponse = parseJSONObject(response.toString());
            if (jsonResponse.getString("status").equals("error") || jsonResponse.isNull("lat") || jsonResponse.isNull("lon")) {
              lat = "QUERY ERROR"; // Fehlermeldungen speichern
              lon = "QUERY ERROR";
            } else {
              lat = jsonResponse.get("lat").toString();
              lon = jsonResponse.get("lon").toString();
              //jsonResponse.getString("accurancy");
              //jsonResponse.getString("balance");
            }
            getGPSTable.setString(id, 7, lat); // Breiten- und Längengrad in Hilfstabelle einfügen
            getGPSTable.setString(id, 8, lon);
          }
          catch (IOException e) {
          }
          finally { //close the input stream
            if (in != null);
            in.close();
          }
        }
        catch (IOException e) {
        }
        finally {  //in this case, we are ensured to close the connection itself
          if (conn != null)
            conn.disconnect();
        }
      } else {
        getGPSTable.setString(id, 7, "CELL ERROR"); // Breiten- und Längengrad in Hilfstabelle einfügen
        getGPSTable.setString(id, 8, "CELL ERROR");
      }
    }
    // Statusmeldung anzeigen, wenn Koordinaten geladen wurden (und es etwas zu laden gab)
    if (numberOfRows > 0) {
      println("Laden der Koordinaten für alle Funkzellen abgeschlossen");
      JOptionPane.showMessageDialog(null, "Herunterladen der Koordinaten für alle Funkzellen abgeschlossen.", "Koordinaten heruntergeladen", JOptionPane.INFORMATION_MESSAGE); 
    }

    fillTables(); // Weiter mit dem Ergänzen der Dateien mit den Koordinaten
  }

  void fillTables() { // Ursprüngliche Tabellen mit Koordinaten aus der Hilfstabelle auffüllen und Datensatz-ID ergänzen
    for (int id = 0; id < fileCount; id++) { // Jeden Datensatz durchlaufen
      if (!gpsUrl[id]) { // Wenn die Datensätze vorher noch nicht verarbeitet wurden
        data[id].addColumn("Breitengrad"); // Spalte Breitengrad hinzufügen
        data[id].addColumn("Längengrad"); // Spalte Längengrad hinzufügen

        for (int k =0; k < data[id].getRowCount(); k++) { // Jede Zeile des aktuellen Datensatzes mit GPS Koordinaten erweitern
          String t_mcc = data[id].getString(k, 3); // MCC, MNC, LAC und CellID der Zeile temporär speichern
          String t_mnc = data[id].getString(k, 4);
          String t_radio = data[id].getString(k, 5);
          String t_lac = data[id].getString(k, 6);
          String t_cellID = data[id].getString(k, 7);
          String t_psc = data[id].getString(k, 8);
          String t_signal = data[id].getString(k, 9);

          for (TableRow cellRow : getGPSTable.matchRows(t_cellID, "CellID")) { // Wähle korrekte Zeille in Hilfstabelle, in der die CellID übereinstimmt
            // Wenn auch die die weiteren Daten übereinstimmen
            if (cellRow.getString("lac").equals(t_lac) && cellRow.getString("mcc").equals(t_mcc) && cellRow.getString("mnc").equals(t_mnc) && cellRow.getString("radio").equals(t_radio) && cellRow.getString("psc").equals(t_psc) && cellRow.getString("signal").equals(t_signal)) {
              data[id].setString(k, 10, cellRow.getString("lat")); //Breiten- und Längengrad zur Tabelle hinzufügen
              data[id].setString(k, 11, cellRow.getString("lon"));
              break; // for-Schleife beenden
            }
          }
        }
      }
    }
    saveTables(); // Weiter mit dem Speichern der bearbeiteten Tabellen
  }  

  void saveTables() { // Tabellen als Dateien speichern
    for (int id=0; id < fileCount; id++) { // Jeden Datensatz durchlaufen
      if (!gpsUrl[id]) { // Wenn die Datensätze vorher noch nicht verarbeitet wurden
        saveTable(data[id], url[id], "csv"); // Datei speichern
      }
    }
  }
}