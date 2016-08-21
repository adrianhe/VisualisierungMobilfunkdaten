/* Klasse Data um die CSV-Dateien mit den Verbindungsdaten einzulesen,
*  diese mithilfe einer Online Abfrage mit den GPS-Koordinaten der Funkzellen zu ergänzen
*  und ein Tabellenarray aller Datensätze auszugeben. Struktur der Tabellen:
* Datum und Uhrzeit | Dienst | Richtung | MCC | MNC | LAC | CellID | Breitengrad | Längengrad
*/

class Data{
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
    for (int id = 0; id<fileCount; id++){ // Jede Datei durchgehen
      data[id] = loadTable(url[id],"header"); // Datei als Tabelle laden, ohne Header
    }
    checkConverted();  // Weiter mit dem Überprüfen der Dateien
    return data; // Am Ende die Tabellen ausgeben
  }
    
  void checkConverted(){ // Wurden die Datensätze schon einmal verarbeitet?
    gpsUrl = new Boolean[fileCount]; // Speichert Antwort darauf
    for (int id=0;id < fileCount;id++){ // Jeden Datensatz durchlaufen
        if (data[id].getColumnCount() >= 9){ // Hat die Tabelle 9 oder mehr Spalten?
          gpsUrl[id] = (data[id].getColumnTitle(7).equals("Breitengrad") && data[id].getColumnTitle(8).equals("Längengrad")); // Wenn die Bezeichnung der 8. und 9. Spalte stimmen, wurde die Datei schon verarbeitet
        }
        else gpsUrl[id] = false; // Ansonsten wurde die Datei noch nicht verarbeitet
    }
    
    // Ist der Server onlinezum Abfragen der Koordinaten? http://adrian.henning-net.de/ http://kasi.berlin:8888/TowerAPI/
    if (loadStrings("http://adrian.henning-net.de/")[0].contains("online")) createHelpTable(); // Weiter mit dem Erstellen der Hilfstablle
    else {
       println("Server zum Abrufen der Koordinaten ist nicht online");
       for (int id=0;id < fileCount;id++){ // Jeden Datensatz durchlaufen
         if (!gpsUrl[id]){
           data[id].clearRows();
         }
       }
    }
  }
  
  void createHelpTable(){ // Erzeugt eine Hilfstabelle aller Datensätze, in der jede Funkzelle nur einmal auftaucht
    getGPSTable = new Table(); // Neue Tabelle
    getGPSTable.addColumn("mcc", Table.STRING); // 6 Spalten mit Typ String hinzufügen
    getGPSTable.addColumn("mnc", Table.STRING);
    getGPSTable.addColumn("lac", Table.STRING);
    getGPSTable.addColumn("CellID", Table.STRING);
    getGPSTable.addColumn("lat", Table.STRING);
    getGPSTable.addColumn("lon", Table.STRING);
    
    for(int id = 0; id < fileCount; id++){ // Jeden Datensatz durchlaufen
      if (!gpsUrl[id]){ // Wenn die Datensätze vorher noch nicht verarbeitet wurden
        for (int k = 0; k < data[id].getRowCount(); k++){ // Jede Zeile des aktuellen Datensatzes überprüfen
          String t_mcc = data[id].getString(k,3); // MCC, MNC, LAC und CellID der Zeile temporär speichern
          String t_mnc = data[id].getString(k,4);
          String t_lac = data[id].getString(k,5);
          String t_cellID = data[id].getString(k,6);
          
          boolean insertCell = true; // Standardmäßig davon ausgehen, dass die Funkzelle noch in die Hilfstabelle eiongefügt werden muss
          
          for (TableRow cellRow : getGPSTable.matchRows(t_cellID, "CellID")) { // Jede Zeile der Hilfstabelle betrachten, wo die CellID übereinstimmt
            // Wenn auch LAC, MNC und MCC übereinstimmen
            if (cellRow.getString("lac").equals(t_lac) && cellRow.getString("mnc").equals(t_mnc) && cellRow.getString("mcc").equals(t_mcc)){
              insertCell = false; // Die Funkzelle existiert schon in der Hilfstabelle
              break; // for-Schleife kann beendet werden
            }
          }
          
          if (insertCell){ // Funkzelle in Hilfstabelle einfügen falls noch nicht vorhanden
              TableRow newRow = getGPSTable.addRow(); // Neue Zeile erstellen
              newRow.setString("mcc", t_mcc); // Zeile mit temporären Daten der Zeile des Datensatzes füllen
              newRow.setString("mnc", t_mnc);
              newRow.setString("lac", t_lac);
              newRow.setString("CellID", t_cellID);
              newRow.setString("lat", ""); // Breiten- und Längengrad bleiben nocht leer
              newRow.setString("lon", "");
          }
        }
      }
    } 
    getGPS(); // Weiter mit dem Abrufen der Koordinaten für die einzelnen Funkzellen
  }  
  
  void getGPS(){ // Hilfstabelle mit Koordinaten vervollständigen
    String mcc, mnc, lac, cellID, lat, lon; // Tabellenangaben
    processing.data.XML response; // Serverantwort
     
    for (int id = 0; id < getGPSTable.getRowCount(); id++){ // Für jede Zeile der Hilfstabelle
      
      // Ladefortschritt anzeigen
      println("Für "+(id*100/getGPSTable.getRowCount())+"% der Funkzellen die Koordinaten geladen");
      
      // Webanfrage, um die Koordinaten der Funkzelle zu erhalten 
        mcc = getGPSTable.getString(id,0); // Daten aus der Tabelle lesen
        mnc = getGPSTable.getString(id,1);
        lac = getGPSTable.getString(id,2);
        cellID = getGPSTable.getString(id,3);
        
        if (!cellID.equals("ERROR") || !lac.equals("ERROR")){ // CellID und LAC müssen vorhanden sein
          // Anfrage an Datenbank von S. Kasberger (towertracker@kasi.berlin) formulieren
          response = loadXML("http://kasi.berlin:8888/TowerAPI/rest/getLatLonAsXml/"+mcc+"/"+mnc+"/"+lac+"/"+cellID);
          //Antwort auf Fehler überprüfen
          if (response.getChild("lat").getContent().isEmpty() || response.getChild("lon").getContent().isEmpty()){
            lat = "QUERY ERROR"; // Fehlermeldungen speichern
            lon = "QUERY ERROR";
          }
          else { // Bei korrekter Antwort
            lat = response.getChild("lat").getContent();  // Breiten- und Längengrad extrahieren
            lon = response.getChild("lon").getContent(); 
          }
        }
        else {
            lat = "CELL ERROR"; // Fehlermeldungen speichern
            lon = "CELL ERROR";
        }
        
        getGPSTable.setString(id,4,lat); // Breiten- und Längengrad in Hilfstabelle einfügen
        getGPSTable.setString(id,5,lon);
    }
    
    // Statusmeldung anzeigen, wenn Koordinaten geladen wurden
    if (getGPSTable.getRowCount() > 0) println("Laden der Koordinaten für alle Funkzellen abgeschlossen");
    
    fillTables(); // Weiter mit dem Ergänzen der Dateien mit den Koordinaten
  }
  
  void fillTables(){ // Ursprüngliche Tabellen mit Koordinaten aus der Hilfstabelle auffüllen und Datensatz-ID ergänzen
    for (int id = 0;id < fileCount; id++){ // Jeden Datensatz durchlaufen
      if (!gpsUrl[id]){ // Wenn die Datensätze vorher noch nicht verarbeitet wurden
        data[id].addColumn("Breitengrad"); // Spalte Breitengrad hinzufügen
        data[id].addColumn("Längengrad"); // Spalte Längengrad hinzufügen
        
        for (int k =0;k < data[id].getRowCount(); k++){ // Jede Zeile des aktuellen Datensatzes mit GPS Koordinaten erweitern
          String t_mcc = data[id].getString(k,3); // MCC, MNC, LAC und CellID der Zeile temporär speichern
          String t_mnc = data[id].getString(k,4);
          String t_lac = data[id].getString(k,5);
          String t_cellID = data[id].getString(k,6);
    
          for (TableRow cellRow : getGPSTable.matchRows(t_cellID, "CellID")) { // Wähle korrekte Zeille in Hilfstabelle, in der die CellID übereinstimmt
            // Wenn auch die LAC, MNC und MCC übereinstimmt
            if (cellRow.getString("lac").equals(t_lac) && cellRow.getString("mnc").equals(t_mnc) && cellRow.getString("mcc").equals(t_mcc)){
              data[id].setString(k,7,cellRow.getString("lat")); //Breiten- und Längengrad zur Tabelle hinzufügen
              data[id].setString(k,8,cellRow.getString("lon"));
              break; // for-Schleife beenden
            }
          }
        }
      }
    }
    saveTables(); // Weiter mit dem Speichern der bearbeiteten Tabellen
  }  
  
  void saveTables(){ // Tabellen als Dateien speichern
    for (int id=0;id < fileCount;id++){ // Jeden Datensatz durchlaufen
      if (!gpsUrl[id]){ // Wenn die Datensätze vorher noch nicht verarbeitet wurden
        saveTable(data[id],url[id],"csv"); // Datei speichern
      }
    }
  }
}