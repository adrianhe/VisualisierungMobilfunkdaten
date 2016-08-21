/* InfoBox ist ein Objekt, um bestimmte Informationen eines Datensatzes zu visualisieren.
*  Dazu zählen die Anzahl der bereits visualisierten Wegpunkte an denen Telefongespräche
*  stattfanden, SMS geschrieben oder empfangen wurden, mobile Datendienste genutzt wurden
*  sowie der Zeitpunkt des nächsten Wegpunktes.
*/

class InfoBox{
  String nextActivity; // Zeit des nächsten Wegpunktes
  int id; // ID des Datensatzes
  String personaID; // Datensatzkennung aus Dateiname
  
  public InfoBox(int id, String personaID){ // Konstruktor
    this.id =id;
    this.personaID = personaID;
  }
  
  // Infobox zeichnen
  void draw(){ 
      // Nächsten Wegpunkt auslesen, wenn es noch welche gibt
      if (trackpointsCounter.get(id) < trackpoints.get(id).size()) {
            Trackpoint nextTrackpoint = (Trackpoint) trackpoints.get(id).get(trackpointsCounter.get(id));
            
            // Beim letzten Trackpoint schauen, ob die Zeit schon überschritten wurde
            if ((trackpointsCounter.get(id) >= trackpoints.get(id).size()-1) && nextTrackpoint.time.before(currentTime)) nextActivity = "Keine";
            else nextActivity = dateformat.format(nextTrackpoint.time.getTime()); // Zeitpunkt in die Infobox zu schreiben
      }
      else { // Ansonsten existiert kein weiterer Wegpunkt 
            nextActivity = "Keine";
      }
      
      int x,y; // Koordinaten der Infobox
      // Wenn der Datensatz einer der ersten ist
      if ((id*100+100) < height){ // links anordnen
        x = 10; // Infobox positionieren
        y= 10+(id*100);
      }
      else { // Ansonsten rechts anordnen
        x = width-110; // Infobox positionieren
        y = (id-maxFiles/2)*100+10;
      }
    stroke(150); // Umrandung 
    fill((81*id+230)%360, 50 , 75); // Infoxboxen farblich an Mengenblasen der Datensätze anpassen
    rect(x,y,155,80,10); // Infoboxen als abgerundete Rechtecke mit 140 Breite und 80 Höhe
    textAlign(CENTER, CENTER); // Den Text mittig platzieren udn zentrieren
    textFont(infoFont); // Schriftart der Infotexte verwenden
    fill(360);  // Textfarbe weiß
    textSize(12); // Textgröße 12
    // Anzuzeigener Text 
    String display = "ID:"+personaID+" | Tel:"+callCounter.get(id)+" | SMS:"+smsCounter.get(id)+" | Daten:"+dataCounter.get(id)+" | Nächste Aktivität: "+nextActivity;
    text(display, x, y, 155, 80); // Infobox mit Text füllen
    } 
}