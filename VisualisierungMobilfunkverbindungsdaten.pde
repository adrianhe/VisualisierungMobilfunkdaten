// Benötigte Bibliotheken von unfoldingmaps.org importieren
import de.fhpotsdam.unfolding.*;
//import de.fhpotsdam.unfolding.geo.*;
//import de.fhpotsdam.unfolding.utils.*;
//import de.fhpotsdam.unfolding.marker.SimplePointMarker;
//import de.fhpotsdam.unfolding.providers.*;
// Benötigte Java-Bibliotheken für SimpleDateFormat und Calendar importieren
import java.text.*; 
import java.util.*;
import java.io.*;
import java.net.*;
import javax.swing.JOptionPane; 

/**************************************************************************************** 
 Visualisierung von Verbindungsdaten
 ***************************************************************************************/

//API Key zum Herunterladen der Geodaten eigener Datensätze hier eintragen
String APIToken = "xx-xx-xx-xx-xx"; // Auf https://unwiredlabs.com/trial beantragen

/*Interaktion mit der Software:
 
 Pfeiltasten/Maus Drag - Bewegen der Karte
 +/-/Mausrad - Rein-/Rauszoomen
 W - Schneller Durchlauf
 Q - Langsamerer Durchlauf
 S - Screenshot speichern
 
 Im Folgenden kann das Verhalten des Programms geändert werden: */

// Datumsfilter zur Anzeige der Daten
boolean filterDate = false; // Filter an: true; Filter aus: false

// Zeitspanne (von - bis) der Visualisierung, wenn Datumsfilter aktiviert ist
String beginnDate = "01.06.2018 15:00:00"; // Im Format "dd.MM.yyyy HH:mm:ss"
String endDate = "01.06.2019 00:00:00"; // Im Format "dd.MM.yyyy HH:mm:ss"

// Tagesfilter zur Anzeige der Daten
boolean filterDays = false; // Filter an: true; Filter aus: false

// Anzuzeigende Wochentage, wenn der Tagesfilter aktiviert ist
int[] days = {1, 2, 3, 4, 5, 6, 7};  // Woche beginnt mit Sonntag (1) und endet mit Samstag (7)

// Stundenfilter zur Anzeige der Daten
boolean filterHours = false; // Filter an: true; Filter aus: false

// Anzuzeigende Stunden (von - bis), wenn der Stundenfilter aktiviert ist
int beginHour = 0; // Werte von 0 bis 24
int endHour = 24; // Werte von 0 bis 24

// Durchlaufgeschwindigkeit, mit Hoch/Rechts oder Runter/Links während des Durchlaufs schneller oder langsamer einstellen
int speed = 10; // Werte größer als 0; umso größer, desto schneller

// Fenstergröße der Visualiserung, eine Fenstergröße kleiner als 800 x 600 ist nicht empfohlen
int windowWidth = 1000; // Fensterbreite in Pixel
int windowHeight = 800; // Fensterhöhe in Pixel

/* Anzeigemodus der Karte
 Zum Ändern der angezeigten Karte, passe die Variable mapMode an, hier die möglichen Modi:
 
 0: Standardkarte von OpenStreetMap
 1: Terrainkarte von Stamen Design
 */
int mapMode = 0;

/* ################################################################ */
/*     Variablen und Objekte für den Programmablauf deklarieren     */
/* ################################################################ */

// Karte
UnfoldingMap map;
String license; // Lizenzbestimmungen

// Button
PlayButton play; // Wiedergabe
StopButton stop; // Stopp

// Schriftarten
PFont infoFont, bubbleFont; 

// Zähler für Telefongespräche, SMS, Mobile Datendienste, Wegpunkte, fehlerhafte Funkzellen der jeweiligen Datensätze
IntList callCounter, smsCounter, dataCounter, trackpointsCounter, errorCounter;

// Wegpunkte
Trackpoint currentTrackpoint; // Aktueller Wegpunkt
Trackpoint[] lastTrackpoints; // Jeweilis letzter Wegpunkt für Verbindungslinien
ArrayList<ArrayList<Trackpoint>> trackpoints; // Liste von Wegpunktenlisten

// Mengenblase
ArrayList<ArrayList<Amountbubble>> amountbubbles; // Liste von Mengenblasenlisten
ArrayList<Multibubble> allBubbles; // Liste mit allen Multiblasen, die mehr als eine Person passieren

// Infoboxen
ArrayList<InfoBox> infoboxes; // Infoboxen für die jeweiligen Datensätze

// Werte
int fileCount, maxFiles; // Aktuelle und maximale Anzahl von Datensätze

// Flaggen
boolean playing, dataIsSet; // Status der Wiedergabe der Visualiserung (läuft/läuft nicht) und Status der Dateninitaliserung
boolean[] finished;  // Status der Visualiserung der jeweiligen Datensätze (abgeschlossen/nicht abgeschlossen)

// Dateipfade 
String[] url;
char slash; // Art des Schrägstriches je nach Betriebssystem

// Datum und Zeit
SimpleDateFormat dateformat; // Zum Vergleich von Zeitdaten
Calendar currentTime, startTime, endTime, startOfSet, endOfSet; // Aktueller Zeitpunkt, Start und Ende der Wiedergabe,  Start- und Endzeitpunkt bei Datumsfilter

/* ############################# */
/*         Einstellungen         */
/* ############################# */

void settings() {

  /* Fenstergröße der Visualiserung und Renderer:
   * Für "P2D" muss die Grafikkarte OpenGL 2 unterstützen.
   * Alternativ: "FX2D", dann kann jedoch nicht mit dem Mausrad gezoomt werden,
   * siehe Bugtracker: https://github.com/processing/processing/issues/4169
   * Vollbild mit fullScreen() statt size() ist auch möglich */

  size(windowWidth, windowHeight, P2D);
}

void setup() {  
  // Farbmodus und Farbintervalle
  colorMode(HSB, 360, 100, 100);

  /* ### Variablen und Objekte für den Programmablauf initalisieren und erzeugen ### */

  // Karte
  switch(mapMode) { // Kartenmodus und jeweilige Lizenz festlegen
  case 0: // Standardkarte von OpenStreetMap
    map = new UnfoldingMap(this, new OpenStreetMap.OpenStreetMapProvider());
    license = "Kartendaten und Kacheln von OpenStreetMap, unter CC BY SA";
    break;
  case 1: // Schwarz-Weiß-Karte von Stamen Design
    map = new UnfoldingMap(this, new StamenMapProvider.TonerLite());
    license = "Kartenkacheln von Stamen Design, unter CC BY 3.0. Kartendaten von OpenStreetMap, unter CC BY SA";
    break; 

    /*** Lizenzbedingungen für folgendene Karten sind unklar.
     case 2: // Straßenkarte von Microsoft
     map = new UnfoldingMap(this, new Microsoft.RoadProvider()); 
     license = "Kartendaten und Kacheln von Microsoft";
     break;
     case 3: // Standardkarte von Google Maps
     map = new UnfoldingMap(this, new Google.GoogleMapProvider()); 
     license = "Kartendaten und Kacheln von Google";
     break; 
     case 4: // Satellitenbilder von Microsoft
     map = new UnfoldingMap(this, new Microsoft.AerialProvider());
     license = "Kartendaten und Kacheln von Microsoft";
     break;
     case 5: // Terrainkarte von Google Maps
     map = new UnfoldingMap(this, new Google.GoogleTerrainProvider());
     license = "Kartendaten und Kacheln von Google";
     break;
     ***/

  default: // Standardkarte von OpenStreetMap
    map = new UnfoldingMap(this, new OpenStreetMap.OpenStreetMapProvider()); 
    license = "Kartendaten und Kacheln von OpenStreetMap, unter CC BY SA";
  }

  MapUtils.createDefaultEventDispatcher(this, map); // Karte erzeugen

  // Wiedergabe- und Stoppbutton
  play = new PlayButton();
  stop = new StopButton();

  // Standardschriftart
  bubbleFont = createFont("Helvetica", 100); // Schriftart für die Zähler an den Mengenblasen
  infoFont = createFont("Helvetica", 14); // Schriftart für Infotexte

  // Zähler für Anrufe, SMS, Datendienste, Wegpunkte und fehlerhafte Funzellen der jeweiligen Datensätze
  callCounter = new IntList();
  smsCounter = new IntList();
  dataCounter = new IntList();
  trackpointsCounter = new IntList();
  errorCounter = new IntList();

  // Wegpunkte
  trackpoints = new ArrayList<ArrayList<Trackpoint>>(); // Liste von Wegpunktlisten

  // Mengenblasen
  amountbubbles = new ArrayList<ArrayList<Amountbubble>>(); // Liste von Mangenblasenlisten
  allBubbles = new ArrayList<Multibubble>(); // Liste mit allen Multiblasen, die mehr als eine Person passieren

  // Infoboxen
  infoboxes = new ArrayList<InfoBox>();  // Liste von Infoboxen

  // Werte
  maxFiles = 2*(floor(height/100)); // Maximale Anzahl von Datensätze je nach Größe des Fensters
  fileCount = 0; // Anzahl der Datensätze zum Start auf 0 setzen

  // Flaggen
  finished = new boolean[maxFiles]; // Nach fertigem Durchlauf die Bubbles nicht mehr verändern, standardmäßig mit false initalisert
  playing = false; // true: Wiedergabe beginnt sofort, false: Erst auf Play drücken
  dataIsSet = false; // Kein Ausführen von großen Teilen in der Methode draw() bis die Datensätze eingelesen wurden

  // Dateipfade
  url = new String[maxFiles]; // Pfade der Datensätze im Dateisystem

  // Art des Schrägstriches je nach Betriebssystem
  if (System.getProperty("os.name").toLowerCase().contains("windows")) slash = '\\'; // Backslash für Windows
  else slash = '/'; // Forwardslash für Linux und Co.

  // Datum und Zeit
  dateformat = new SimpleDateFormat("dd.MM.yyyy HH:mm:ss"); // Zum Vergleich von Zeitdaten
  startTime = Calendar.getInstance(); // Startzeit der Wiedergabe
  startOfSet = Calendar.getInstance(); // Startzeit der Wiedergabe bei aktivem Datumsfilter
  endOfSet = Calendar.getInstance(); // Ende der Wiedergabe bei aktivem Datumsfilter

  // Aufforderung Datensätze mit Verbindungsdaten auszuwählen
  JOptionPane.showMessageDialog(null, "Du kannst nachfolgend bis zu "+maxFiles+" Datensätze auswählen. \nWähle dazu jede Datei einzeln aus und bestätige mit 'Öffnen'. \nBeende den Vorgang nach dem letzten Datensatz mit 'Abbrechen'.", "Datensätze auswählen", JOptionPane.INFORMATION_MESSAGE);   
  // Die Auswahl wird an fileSelected() weitergereicht
  selectInput("Wähle einen Datensatz (Verbindungen_???.csv) aus", "fileSelected");
}

/* ####################################### */
/*         Dateien überprüfen              */
/* ####################################### */

void fileSelected(File selection) {
  if (selection != null) { // Überprüfen, ob eine Datei ausgewählt wurde

    // Gewählte Datei überprüfen
    Boolean correctInput = true; // Standardmäßig wird davon ausgegangen, dass die Eingabe korrekt ist
    String path = selection.getAbsolutePath(); // Dateipfad
    String errorMessage = "Error: "; // Anzuzeigende Fehlermeldung bei fehlerhafter Datei

    // Handelt es sich um eine CSV-Datei?
    if (!path.substring(Math.max(0, path.length() - 4)).equals(".csv")) {
      correctInput = false;
      errorMessage += "Keine CSV-Datei. Datei muss die Endung .csv haben.\n";
    }

    // Stimmt die Header Zeile?
    String[] compare = {"Datum und Uhrzeit", "Dienst", "Richtung", "MCC", "MNC", "Radio", "LAC", "CellID", "PSC", "Signal"};
    try {
      TableRow tempRow = loadTable(path).getRow(0); // Header laden und vergleichen
      for (int i=0; i<compare.length; i++) { // Jede Spalte überprüfen
        if (!trim(tempRow.getString(i)).equals(compare[i])) { // Evtl. überflüssige Leerzeichen entfernen
          correctInput = false;
          errorMessage += "Fehlerhafter Header. Die Tabelle muss dem Format: 'Datum und Uhrzeit,Dienst,Richtung,MCC,MNC,Radio,LAC,CellID,PSC,Signal' entsprechen.\n";
          break;
        }
      }
    }
    catch(Exception e) { // Tabelle konnte vom Programm nicht geladen werden
      correctInput = false;
      errorMessage += "Keine Tabelle. Daten können nicht gelesen werden.\n";
    }

    // Wurde die Datei bereits ausgewählt?
    for (int id = 0; id < fileCount; id++) {
      if (path.substring(path.lastIndexOf(slash)).equals(url[id].substring(url[id].lastIndexOf(slash)))) {
        correctInput = false;
        errorMessage += "Datei mit diesem Namen wurde schon ausgewählt. Wähle eine andere Datei oder fahre fort.\n";
      }
    }

    // Ist die maximale Anzahl an anzeigbaren Datensätzen erreicht?
    if (fileCount >= maxFiles) {
      correctInput = false;
      errorMessage += "Du kannst nur maximal "+maxFiles+" Datensätze auswählen. Vergrößere das Fenster über size(), um mehr Datensätze anzuzeigen.\n";
    }

    // Wenn keine Fehler gefunden wurden, Dateipfad speichern
    if (correctInput) {
      url[fileCount] = path;
      fileCount++; // Anzahl der Datensätze um 1 erhöhen
    } else { // Ansonsten Fehlermeldungen anzeigen
      println(errorMessage);
      JOptionPane.showMessageDialog(null, errorMessage, "Visualisierung fehlgeschlagen", JOptionPane.ERROR_MESSAGE);
    }

    // Weitere Datensätze einlesen
    selectInput("Wähle einen Datensatz (Verbindungen_???.csv) aus. Insgesamt sind noch "+(maxFiles-fileCount)+" Datensätze möglich.", "fileSelected");
  } else { // Keine Datei ausgewählt 

    if (fileCount > 0) {

      Data data = new Data(url, fileCount); // Objekt der Klasse Data anlegen
      Table[] queriedData = data.startTransition();

      boolean hasData = false;
      for (int id=0; id < fileCount; id++) { // Jeden Datensatz durchlaufen
        hasData = (hasData || (queriedData[id].getRowCount() > 0));
      }

      if (hasData) makeTrackpoints(queriedData); // Wegpunkte aus dem Ergebnis der Transformation der Datensätze erstellen
      else {
        println("Es können keine Datensätze angezeigt werden. Starte das Programm erneut.");
        JOptionPane.showMessageDialog(null, "Es können keine Datensätze angezeigt werden. Starte das Programm erneut.", "Visualisierung fehlgeschlagen", JOptionPane.WARNING_MESSAGE);
      }
    } else {
      println("Keine (gültigen) Datensätze ausgewählt. Starte das Programm erneut.");
      JOptionPane.showMessageDialog(null, "Keine (gültigen) Datensätze ausgewählt. Starte das Programm erneut.", "Visualisierung fehlgeschlagen", JOptionPane.WARNING_MESSAGE);
    }
  }
}

/* ################################# */
/*   Daten in Wegpunkte umwandeln    */
/* ################################# */

void makeTrackpoints(Table[] data) { // Wegpunkte aus Tabellen erstellen

  lastTrackpoints = new Trackpoint[fileCount]; // Sammlung der jeweils letzten Wegpunkte für jeden Datensatz
  int sumTrackpoints = 0; // Anzahl aller Wegpunkte zu Beginn auf 0 setzen

  if (filterDate) { // Wenn Datumsfilter aktiv ist, Start und Ende aus den Zeiten des Datumsfilters einlesen
    try {
      startOfSet.setTime(dateformat.parse(beginnDate)); // Startzeit des Datumsfilter einlesen
      endOfSet.setTime(dateformat.parse(endDate)); // Ende des Datumsfilters einlesen
    }
    catch(ParseException e) { // Einlesefehler abfangen
      e.printStackTrace();
    }
  }

  for (int id=0; id < fileCount; id++) { // Jeden Datensatz durchlaufen

    // Listen initaliseren
    ArrayList trackpointlist = new ArrayList(); // Leere Wegpunktliste
    trackpoints.add(trackpointlist); // Diese Liste der globalen Liste aller Wegpunktlisten hinzufügen
    ArrayList amountbubblelist = new ArrayList(); // Leere Mengenblasenliste
    amountbubbles.add(amountbubblelist); // Diese Liste der globalen Liste aller Mengenblasenlisten hinzufügen

    String pID = url[id].substring(url[id].lastIndexOf(slash)+1, url[id].lastIndexOf('.')); // Datensatzkennung aus Dateiname lesen
    if (pID.startsWith("Verbindungen_")) pID = pID.substring(13); // Verbindungen wegschneiden
    InfoBox infobox = new InfoBox(id, pID); // Neue Infobox
    infoboxes.add(infobox);  // Diese Infobox der globalen Liste aller Infoboxen hinzufügen 

    // Alle Zähler für den jeweiligen Datensatz auf 0 setzen
    trackpointsCounter.set(id, 0);
    callCounter.set(id, 0);
    smsCounter.set(id, 0);
    dataCounter.set(id, 0);
    errorCounter.set(id, 0);
    for (int k =0; k < data[id].getRowCount(); k++) { // Jede Zeile des Datensatzes durchgehen
    println("anzahl zeilen: "+data[id].getRowCount());
    println("zeile "+k);
      // Gab es Fehler beim Laden der Koordinaten der aktuellen Funkzelle?
      if ((data[id].getString(k, "Breitengrad").equals("QUERY ERROR")) || (data[id].getString(k, "Längengrad").equals("QUERY ERROR")) || (data[id].getString(k, "Breitengrad").equals("CELL ERROR")) || (data[id].getString(k, "Längengrad").equals("CELL ERROR"))) {
        errorCounter.increment(id); // Fehlerzähler um 1 erhöhen
      } else { //Ansonsten neuen Trackpoint für jede Zeile erzeugen mit: Datum und Uhrzeit | Dienst | Richtung | Breitengrad | Längengrad | Datensatz-ID            
        Trackpoint t = new Trackpoint (data[id].getString(k, "Datum und Uhrzeit"), data[id].getString(k, "Dienst"), data[id].getString(k, "Richtung"), data[id].getString(k, "Breitengrad"), data[id].getString(k, "Längengrad"), id); 
        // Auswahl je nach aktiviertem Filter vornehmen
        // Datumsfilter beachten, wenn aktiviert
        if (!filterDate || t.time.after(startOfSet) && t.time.before(endOfSet)) {
          // Tagesfilter beachten, wenn aktiviert
          if (!filterDays || checkDay(days, t.time.get(Calendar.DAY_OF_WEEK))) {

            // Falls Stundenfilter deaktiviert 
            if (!filterHours) {
              trackpoints.get(id).add(t); // Aktuellen Trackpoint zur globalen Liste zur Anzeige für den jeweiligen Datensatz hinzufügen
println("Added trackpoint no. "+k);              
            } else {
              if (beginHour > endHour) {  // Der Beginn des Stundenfilters liegt nach dem Ende
                // Vergleiche entsprechend die Stunde des Trackpoints mit denen des Stundenfilters
                if (t.time.get(Calendar.HOUR_OF_DAY) >= beginHour || t.time.get(Calendar.HOUR_OF_DAY) < endHour) {
                  trackpoints.get(id).add(t); // Aktuellen Trackpoint zur globalen Liste zur Anzeige für den jeweiligen Datensatz hinzufügen
                }
              } else { // Der Beginn des Stundenfilters liegt vor dem Ende
                // Vergleiche die Stunde des Trackpoints mit denen des Stundenfilters
                if (t.time.get(Calendar.HOUR_OF_DAY) >= beginHour && t.time.get(Calendar.HOUR_OF_DAY) < endHour) {
                  trackpoints.get(id).add(t); // Aktuellen Trackpoint zur globalen Liste zur Anzeige für den jeweiligen Datensatz hinzufügen
                }                
              }
            }
          }
        }
      }
    }
    println("Point A");
    // Wenn mindestens ein Wegpunkt angezeigt wird, Letzten Wegpunkt für Verbindungslinie auf ersten Wegpunkt setzen
    if (trackpoints.get(id).size() > 0) lastTrackpoints[id] = trackpoints.get(id).get(0);
        println("Point B");
    // Wenn es Fehler beim Laden der Koordinaten für bestimmte Funkzellen gab, Anzahl der Fehler anzeigen
    if (errorCounter.get(id) > 0) println("Der "+(id+1)+". Datensatz hat "+errorCounter.get(id)+" Verbindungen, für die die Koordinaten der Funkzelle nicht geladen werden konnten.");
    sumTrackpoints = sumTrackpoints + trackpoints.get(id).size();  // Anzahl aller Wegpunkte um die Anzahl der Wegpunkte des jeweiligen Datensatzes erhöhen
  }
  // Fehlermeldung anzeigen, wenn keine Wegpunkte angezeigt werden würden
  if (sumTrackpoints <= 0) {
    println("Error: Keine Trackpoints gefunden. Das könnte daran liegen, dass die Filter falsch eingestellt wurden. Starte das Programm erneut.");
    JOptionPane.showMessageDialog(null, "Error: Keine Trackpoints gefunden. Das könnte daran liegen, dass die Filter falsch eingestellt wurden. Starte das Programm erneut.", "Keine Wegpunkte anzuzeigen", JOptionPane.WARNING_MESSAGE);  
  }
  // Ansonsten Startzeit und Ende der Visualiserung berechnen
  else {
    // Wenn Datumsfilter aktiviert ist, Start und Ende auf Start- und Endzeit des Datumsfilters setzen
    if (filterDate) {
      startTime = (Calendar) startOfSet.clone();
      endTime = (Calendar) endOfSet.clone();
    } else { // Ansonsten Startzeit der Wiedergabe auf Zeit des ersten Trackpoints und Ende der Wiedergabe auf Zeit des letzten Trackpoints setzen
      try { 
        startTime.setTime(dateformat.parse("30.12.2049 15:00:00")); // Startzeit hoch ansetzen, um bei folgenden Vergleichen immer später zu sein
      }
      catch(ParseException e) { // Einlesefehler abfangen
        e.printStackTrace();
      }
      
      for (int id=0; id < fileCount; id++) { // Jeden Datensatz durchlaufen
        if (trackpoints.get(id).size() > 0) {
          // Startzeit auf frühesten Wegpunktes setzen
          if (trackpoints.get(id).get(0).time.before(startTime)) startTime = (Calendar) trackpoints.get(id).get(0).time.clone();
        }
      }
      endTime = (Calendar) startTime.clone(); // Ende auf Startzeit setzen, um bei folgenden Vergleichen immer früher zu sein
      for (int id=0; id < fileCount; id++) { // Jeden Datensatz durchlaufen
        if (trackpoints.get(id).size() > 0) {
          // Ende der Wiedergabe auf Zeit des letzten Wegpunktes setzen
          if (trackpoints.get(id).get(trackpoints.get(id).size()-1).time.after(endTime)) endTime = (Calendar) trackpoints.get(id).get(trackpoints.get(id).size()-1).time.clone();
        }
      }
      startTime.add(Calendar.MINUTE, -1); // Startzeit eine Stunde früher, damit auch der erste Wegpunkt angezeigt wird
    }

    Calendar compareTime = (Calendar) endTime.clone(); // Vegleichzeit zum Finden des ersten Wegpunktes
    for (int id=0; id < fileCount; id++) { // Jeden Datensatz durchlaufen
      if (trackpoints.get(id).size() > 0) {
        // Karte auf Position des frühesten Wegpunktes setzen
        if (trackpoints.get(id).get(0).time.before(compareTime)) {
          compareTime = (Calendar) trackpoints.get(id).get(0).time.clone(); // Vergleichszeit für nächsten Vergleich aktualisieren
          map.zoomAndPanTo(10, trackpoints.get(id).get(0).location);  // Startposition auf ersten Wegpunkt setzten mit Zoomlevel 10
        }
      }
    }

    currentTime = (Calendar) startTime.clone(); // Aktuellen Zeitpunkt auf Startzeit der Wiedergabe setzen
    dataIsSet = true; // Setup ist abgeschlossen, ab jetzt wird draw() vollständig ausgeführt
  }
}

/* ################ */
/*      Zeichnen    */
/* ################ */

void draw() {

  // Karte zeichnen
  map.draw();

  // Nutzungsbedingungen zeichnen
  textAlign(RIGHT, BOTTOM);  // Unten Rechts
  textFont(infoFont); // Mit der der Scchriftart für Infotexte
  fill(360); // In Weiß
  outline(license, width-2, height-2, 10); // Mit Umrandung in Größe 1 Lizenz zeichnen

  if (dataIsSet) { // Sind die Datensätze schon fertig eingelesen? Verhindert Fehlermeldungen beim draw() Durchlauf

    for (int id=0; id < fileCount; id++) { // Jeden Datensatz durchlaufen

      // Infobox des Datensatzes zeichnen
      infoboxes.get(id).draw();

      // Wenn je nach Filtereinsellungen Wegpunkte anzuzeigen sind, setze aktuellen Wegpunkt auf nächsten Wegpunkt des aktuellen Datensatzes
      if (trackpoints.get(id).size() > 0) {
        currentTrackpoint = (Trackpoint) trackpoints.get(id).get(trackpointsCounter.get(id));

        // Solange durchführen, bis der aktuelle Zeitpunkt eingeholt wurde
        while (currentTrackpoint.time.before(currentTime)) {
          SimplePointMarker punkt = new SimplePointMarker(currentTrackpoint.location); // Neue Markierung auf der Karte für aktuellen Wegpunkt

          // Wegpunkt mit vorigem verbinden, sodass Verbindungslinien entstehen
          if (lastTrackpoints[id] != null && playing) { // Existiert ein letzter Wegpunkt und läuft die Wiedergabe?
            SimplePointMarker lastPoint = new SimplePointMarker(lastTrackpoints[id].location); // Neue Markierung auf der Karte, an der Stelle des letzten Wegpunktes
            strokeWeight(2); // Umrandung der Dicke 2 Pixel
            stroke(0); // Farbe der Umrandung schwarz
            // Verbindungslinie  zwischen den beiden Markierungen zeichen
            line(punkt.getScreenPosition(map).x, punkt.getScreenPosition(map).y, lastPoint.getScreenPosition(map).x, lastPoint.getScreenPosition(map).y);
          }

          // Amountbubble erzeugen, wenn es an einem Punkt noch keine gibt
          // sonst den Zähler der bestehenden erhöhen
          boolean foundInData = false; // Flagge, ob an diesem Punkt schon eine Mengenblase für diesen Datensatz existiert

          if (!finished[id]) { // Wurde die Wiedergabe vom aktuellen Datensatz noch nicht abgeschlossen?
            if (currentTrackpoint.service.contains("Telefonie")) { 
              callCounter.increment(id); // Anrufzähler erhöhen, wenn der Wegpunkt "Telefonie" als Dienst enthält
            } else if (currentTrackpoint.service.contains("Mobile Daten")) {
              dataCounter.increment(id); // Datenzähler erhöhen, wenn der Wegpunkt "Mobile Daten" als Dienst enthält
            } else if (currentTrackpoint.service.contains("SMS")) {
              smsCounter.increment(id); // SMS-Zähler erhöhen, wenn der Wegpunkt "SMS" als Dienst enthält
            }

            for (int i = 0; i < amountbubbles.get(id).size(); i++) { // Für jede Mengenblase des aktuellen Datesatzes durchführen
              Amountbubble bubbletemp = (Amountbubble) amountbubbles.get(id).get(i); // Mengenblase  aus der Liste der Mengenblasen des Datensatzes holen
              if (bubbletemp.equalsOther(currentTrackpoint.location)) { // Hat diese Mengenblase die gleichen Koordinaten wie der aktuelle Wegpunkt?
                bubbletemp.increaseSize(); // Dann Zähler und Durchmesser dieser Mengenblase erhöhen
                foundInData = true; // Flagge setzen, dass an diesem Punkt schon eine Blase für diesen Datensatz existiert
                break; // for-Schleife kann beendet werden
              }
            }

            if (!foundInData) { // Existiert noch keine Blase an dem aktuellem Wegpunkt des Datensatzes
              boolean foundInAll = false; // Flagge, ob an diesem Punkt schon eine Mengenblase eines anderen Datensatzes existiert
              for (int i = 0; i < allBubbles.size(); i++) { // Liste der Multiblasen durchgehen
                Multibubble bubbletemp = (Multibubble) allBubbles.get(i); // Mengenblase aus der Liste der Multiblasen holen
                if (bubbletemp.equalsOther(currentTrackpoint.location)) { // Hat diese Mengenblase die gleichen Koordinaten wie der aktuelle Wegpunkt?
                  foundInAll = true; // Flagge setzen, dass an diesem Punkt schon eine Multiblase existiert
                  bubbletemp.increaseSize(id); // Zähler dieser Multiblase erhöhen
                  break; // for-Schleife kann beendet werden
                }
              }
              for (int j = 0; j < fileCount; j++) { // Jeden Datensatz durchlaufen
                if (j!=id) { // Außer den eigenen
                  for (int i = 0; i < amountbubbles.get(j).size(); i++) { // Für jede Mengenblase der anderen Listen durchführen
                    Amountbubble bubbletemp = (Amountbubble) amountbubbles.get(j).get(i); // Mengenblase aus der Liste der Mengenblasen holen
                    if (bubbletemp.equalsOther(currentTrackpoint.location)) { // Hat diese Mengenblase die gleichen Koordinaten wie der aktuelle Wegpunkt?
                      foundInAll = true; // Flagge setzen, dass an diesem Punkt schon eine Multiblase existiert
                      Multibubble multibubble = new Multibubble(bubbletemp.location, j, bubbletemp.counter, bubbletemp.diameter, id); // Neue Multiblase erstellen
                      allBubbles.add(multibubble); // Blase in Gesamtliste hinzufügen
                      amountbubbles.get(j).remove(i); // Blase aus Ursprungsliste entfernen
                      break; // for-Schleife kann beendet werden
                    }
                  }
                }
              }
              if (!foundInAll) { // Existiert auch keine Blase an dem aktuellem Wegpunkt in der Gesamtliste der Multiblasen oder in anderen Datensätzen
                Amountbubble amountbubble = new Amountbubble(currentTrackpoint.location); // Neue Mengenblase erstellen
                amountbubbles.get(id).add(amountbubble); // Mengenblase der Liste der Mengenblasen des Datensatzes hinzufügen
              }
            }
          }

          // Festellen, ob die Wiedergabe für diesen Datensatz beendet ist
          if (trackpointsCounter.get(id) < trackpoints.get(id).size()-1 && playing) { // Entspricht der Zähler der Wegpunkte noch nicht der Größe der Wegpunktliste und wird momentan abgespielt?
            trackpointsCounter.increment(id); // Zähler der Wegpunkte für diesen Datensatz um 1 erhöhen
            if (!equalsOther(currentTrackpoint.location, lastTrackpoints[id].location)) { // Befindet sich der Wegpunkt nicht an der gleichen Stelle?
              lastTrackpoints[id] = currentTrackpoint; // Dann letzten Wegpunkt auf aktuellen Wegpunkt setzen
            }         
            currentTrackpoint = (Trackpoint) trackpoints.get(id).get(trackpointsCounter.get(id)); // Nächsten Wegpunkt aus der Liste holen
          } else {
            finished[id] = true; // Die Wiedergabe des aktuellen Datensatzes ist beendet
            break; // while-Schleife kann beendet werden
          }
        }

        // Alle Mengenblasen zeichnen
        for (int i = 0; i < amountbubbles.get(id).size(); i++) { // Jede Blase der Liste des Datensatzes durchgehen
          Amountbubble bubbletemp = (Amountbubble) amountbubbles.get(id).get(i); // Blase aus Liste holen
          bubbletemp.draw(map, id, bubbletemp.equalsOther(lastTrackpoints[id].location)); // Blase zeichnen
        }
        for (int i = 0; i < allBubbles.size(); i++) { // Jede Blase der Liste der Multiblasen durchgehen
          Multibubble bubbletemp = (Multibubble) allBubbles.get(i); // Blase aus Liste holen
          bubbletemp.draw(map, bubbletemp.equalsOther(lastTrackpoints[id].location)); // Blase zeichnen
        }
      }

      /* Buttons */

      // Button zeichnen und überprüfen ob Maus darüber ist
      boolean hand = false; // Standardmäßig wird davon ausgegeangen, dass die Maus nicht über den Buttons ist
      play.draw(); // Wiedergabebutton zeichnen
      stop.draw(); // Stoppbutton zeichnen
      hand = hand || play.mouseOver() || stop.mouseOver(); // Flagge ändert den Wert, wenn Maus über den Buttons

      // Wenn die Maus über einem Button ist soll der Zeiger als Hand dargestellt werden sonst als Pfeil
      cursor(hand ? HAND : ARROW);

      // Wochentag, Datum und Uhrzeit oben mittig hinschreiben
      textAlign(CENTER, TOP); // Oben, mittig
      textFont(infoFont); // Schriftart für Infotexte
      outline("Aktueller Zeitpunkt: "+getWeekDay(currentTime.get(Calendar.DAY_OF_WEEK))+" "+dateformat.format(currentTime.getTime()), width/2, 5, 15); // Umranden
    }

    if (playing && currentTime.before(endTime)) { // Wenn die Wiedergabe läuft und die aktuelle Zeit noch vor dem Ende der Wiedergabe ist
      currentTime.add(Calendar.SECOND, +(speed)); // Aktuellen Zeitpunkt, je nach Geschwindigkeit in Sekunden erhöhen
    } else {
      if (!currentTime.before(endTime)) { // Ansonsten schauen, ob Ende der Wiergabe erreicht wurde
        playing = false; // Wiedergabe deaktivieren
      }
    }
  }
}

/* ################# */
/*     Steuerung     */
/* ################# */

void keyReleased() { // Diese Methode wird aufgerufen, wenn eine Taste losgelassen wird
  // Bei "S" oder "s"  wird ein Screenshot im Ordner "Screenshot" der Visualisierungssoftware gespeichert
  if (key == 's' || key == 'S') {
    //save(url[0].substring(0, url[0].lastIndexOf(slash))+slash+"screenshot_"+timestamp()+".jpg");
    save("Screenshots"+slash+"screenshot_"+timestamp()+".jpg");
  }
  // Bei "W" oder "w" wird die Durchlaufgeschwindigkeit verdoppelt
  else if (key == 'w' || key == 'W') {
    // Überprüfe den aktuellen Wert, damit der Wert nicht zu groß wird
    if (speed < 1000)  speed = speed*2;
  }
  //  Bei "Q" oder "q" wird die Durchlaufgeschwindigkeit halbiert   
  else if (key == 'q' || key == 'Q') {
    // Überprüfe den aktuellen Wert, damit der Wert größer 0 bleibt
    if (speed > 2) speed = speed/2;
  }
}

// Schauen ob die Maus über einem Button ist und entsprechend bei Klick reagieren
void mouseClicked() { // Diese Methode wird aufgerufen, wenn die linke Maustaste gedrückt wird
  if (play.mouseOver()) { // Ist der Mauszeiger über dem Wiedergabebutton
    playing = !playing; // Wiedergabe wird (de)aktiviert, je nach aktuellem Status
  } else if (stop.mouseOver()) {  // Ist der Mauszeiger über dem Stoppebutton
    playing = false; // Wiedergabe wird deaktiviert
    currentTime = (Calendar) startTime.clone(); // Aktueller Zeitpunkt wird auf Startzeit der Wiedergabe gesetzt
    allBubbles.clear(); // Liste der Multiblasen leeren
    for (int id=0; id < fileCount; id++) { // Jeden Datensatz durchlaufen

      // Listen und Zähler wieder auf Anfang setzen
      amountbubbles.get(id).clear();
      trackpointsCounter.set(id, 0);
      callCounter.set(id, 0);
      smsCounter.set(id, 0);
      dataCounter.set(id, 0);
      finished[id] = false;
    }
  }
}

/* ######################################### */
/*     Zusätzliche brauchbare Funktionen     */
/* ######################################### */

// Wochentage konvertieren: von Zahlen in deutsche Wörter 
String getWeekDay(int dayID) { // Eingabe: Numerische Repräsentation eines Wochentages
  switch(dayID) { // Je nach Wert Wochentagsabkürzung ausgeben
  case 1:
    return "So.";
  case 2: 
    return "Mo.";
  case 3:
    return "Di.";
  case 4: 
    return "Mi.";
  case 5:
    return "Do.";
  case 6: 
    return "Fr.";
  case 7:
    return "Sa.";
  default: 
    return "k.A.";
  }
}

// Überprüfen ob Wochentag in einer Sammlung von Wochentagen enthalten ist
boolean checkDay(int[] weekDays, int weekDay) { // Eingabe: Array ganzer Zahlen und numerische Repräsentation eines Wochentages
  for (int k = 0; k < weekDays.length; k++) { // Jede Stelle des Arrays durchlaufen
    if (weekDays[k] == weekDay) return true; // Wenn eine Stelle dem gesuchten Wert entspricht 'wahr' ausgeben
  }
  return false; // Ansonsten 'falsch' ausgeben
}

// Datum und Systemzeit abrufen
String timestamp() {
  Calendar now = Calendar.getInstance(); // Kalenderobjekt erzeugen
  return String.format("%1$ty%1$tm%1$td_%1$tH%1$tM%1$tS", now); // Datum und Zeit als String ausgeben
}

// Schriften umranden
void outline(String text, float x, float y, float size) { // Eingabe: Text, x-y Koordinaten und Textgröße
  textSize(size); // Textgröße setzen
  fill(360); // Schriftfarbe ist weiß
  int outlineWeight = 1; // Umrandung ist 1 Pixel dick
  for (int i = -outlineWeight; i <= outlineWeight; i++) { // Für die Dicke der Umrandung
    text(text, x+i, y); // Text zeichnen mit Versatz in x-Richtung
    text(text, x, y+i); // Text zeichnen mit Versatz in y-Richtung
  }
  fill(0); // Schriftfarbe ist schwarz
  text(text, x, y); // Text zeichnen
}

// Überprüft ob zwei Punkte an der gleichen Stelle liegen
public boolean equalsOther(Location a, Location b) {
  float minDistance = 0.002; // Mindestabstand der zur Vergrößerung der Blase führt, siehe AmountBubble
  float distance = (float) sqrt(sq(a.getLat() - b.getLat()) + sq(a.getLon() - b.getLon())); // Satz des Phythagoras zur Ermittlung der Entfernung
  return (distance < minDistance); // Wenn die Entfernung geringer als der Mindestabstand 'wahr' ausgeben
}