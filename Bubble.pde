// Bubble (Mengenblase) ist ein Objekt um die Häufigkeit des Passierens
// an einem bestimmten Punkt zu messen
class Bubble {
  
  Location location; // Position der Blase
  float minDistance = 0.002; // Mindestabstand der zur Vergrößerung der Blase führt
  float diameter; // Durchmesser der Mengenblase
  float counter; // Zähler, wie oft diese schon passiert wurde
  
  // Überprüft ob zwei Mengenblasen an der gleichen Stelle liegen
  public boolean equalsOther(Location that) {
    float distance = (float) sqrt(sq(that.getLat() - this.location.getLat()) + sq(that.getLon() - this.location.getLon())); // Satz des Phythagoras zur Ermittlung der Entfernung
    return (distance < minDistance); // Wenn die Entfernung geringer als der Mindestabstand 'wahr' ausgeben
  }
}

// Neue Klasse für Mengenblasen, die nur von einer Person passiert werden
class Amountbubble extends Bubble{  
  
  public Amountbubble(Location punkt) { // Konstruktor je nach Position
    this.location = punkt; // Koordinaten
    this.diameter = 8; // Anfangsdurchmesser ist 8 Pixel
    this.counter = 1; // Zähler wird auf 1 gesetzt
  }
  
  void increaseSize() { // Zähler und Durchmesser erhöhen
    this.diameter = diameter+0.015;
    this.counter++;
  }
  
  // Zeichnen der Blase, Aufruf kommt aus der Hauptklasse
  void draw(UnfoldingMap map, int id, boolean highlight) {
    SimplePointMarker punkt = new SimplePointMarker(location); // Markierung an der Stelle der Blase auf der Karte
    draw(punkt.getScreenPosition(map).x, punkt.getScreenPosition(map).y, id, highlight); // Zeichnen am Punkt x|y für den jeweiligen Datensatz mit oder ohne Hervorhebung
  }

  // Mengenblase wird gezeichnet
  // Blase mit Zähler, Größenänderung und einer Hervorheben-Funktion, um den aktuellen Standort zu markieren
  void draw(float x, float y, int id, boolean highlight) {  
        if (!highlight) { // Die Blase entspricht nicht dem aktuellen Standort
         noStroke(); // Keine Umrandung
         fill((81*id+230)%360, 50 , 75); // Farbe je nach Datensatz-ID mit geringer Sättigung
        }
        else { // Die Blase entspricht dem aktuellem Standort der Person
         fill((81*id+230)%360, 100, 100); // Farbe je nach Datensatz-ID mit hoher Sättigung
         stroke(360); //weiße Umrandung
         strokeWeight(2); //mit 2 Pixel Dicke
        }
        ellipse(x, y, diameter, diameter); // Kreis an der Stelle zeichnen mit dem aktuellem Durchmesser
        textAlign(LEFT); // Zählertext links anordnen
        textFont(bubbleFont); // Schriftart der Wegblasen wählen
        outline(str(round(this.counter)), x +(this.diameter/2), y+(this.diameter/2),round(2 * this.diameter)); // Zählertext umranden
  }
}

// Neue Klasse für Multiblasen, die von mehreren Personen passiert werden
class Multibubble extends Bubble{  
  FloatList counterIDs; // Zähler, wie oft diese von den einzelnen Personen passiert wurden
  IntList ids; // Welche Datensätze passieren die Blase
  
  public Multibubble(Location punkt, int idA, float countA, float diaA, int idB) { // Konstruktor je nach Position
    this.location = punkt; // Koordinaten
    this.diameter = diaA+0.015; // Durchmesser übernehmen und einmalig erhöhen
    this.ids = new IntList(); // Welche Datensätze passieren die Blase
    this.ids.append(idA); // Die ersten beiden Datensätze hinzufügen
    this.ids.append(idB); // Für die, die Mengenblase erzeugt wurde
    this.counterIDs = new FloatList(); // Zähler, wie oft diese von den einzelnen Personen passiert wurden
    this.counterIDs.set(idA,countA); // Zähler wird auf vorigen Stand gesetzt
    this.counterIDs.set(idB,1); // Zähler wird auf 1 gesetzt
    this.counter = countA+1; // Gesamtzähler wird angepasst, Zähler übernehmen und einmalig erhöhen
    
  }
  
  void increaseSize(int id) { // Zähler und Durchmesser erhöhen
    this.diameter = diameter+0.015;
    this.counter++;
    if (ids.hasValue(id)){ // War die Person bereits an dieser Multiblase beteiligt?
      this.counterIDs.add(id,1);
    }
    else { // Ansonsten Person hinzufügen
      this.ids.append(id);
      this.counterIDs.set(id,1);      
    }
  }
  
  // Zeichnen der Blase, Aufruf kommt aus der Hauptklasse
  void draw(UnfoldingMap map, boolean highlight) {
    SimplePointMarker punkt = new SimplePointMarker(location); // Markierung an der Stelle der Blase auf der Karte
    draw(punkt.getScreenPosition(map).x, punkt.getScreenPosition(map).y, ids, highlight); // Zeichnen am Punkt x|y für den jeweiligen Datensatz mit oder ohne Hervorhebung
  }

  // Multiblase wird gezeichnet
  // Blase mit Zähler, Größenänderung, IDs und einer Hervorheben-Funktion, um den aktuellen Standort zu markieren
  void draw(float x, float y, IntList ids, boolean highlight) {
        
        FloatList angles = new FloatList(); // Winkel für die Aufteilung der Blase
        for (int i : ids){ // Für jede Person, die an der Multiblase beteiligt ist
          angles.append(max((counterIDs.get(i)/counter)*360,15.0)); // Kreissegment berechnet, min. 15 Grad
        }
       
        float lastAng = 0; // Anfangszeichenwinkel auf 0 Grad setzen
       
        for (int i = 0; i < angles.size(); i++) { // Für jede Person, die an der Multiblase beteiligt ist
          if (!highlight) { // Die Blase entspricht nicht dem aktuellen Standort
           noStroke(); // Keine Umrandung
           fill((81*ids.get(i)+230)%360, 50 , 75); // Farbe je nach Datensatz-ID mit geringer Sättigung
          }
          else { // Die Blase entspricht dem aktuellem Standort der Person
           fill((81*ids.get(i)+230)%360, 100, 100); // Farbe je nach Datensatz-ID mit hoher Sättigung
           stroke(360); //weiße Umrandung
           strokeWeight(2); //mit 2 Pixel Dicke
          }
          
         arc(x, y, diameter, diameter, lastAng, lastAng+radians(angles.get(i))); // Kreisabschnitt an der Stelle zeichnen mit dem aktuellem Durchmesser
         lastAng += radians(angles.get(i)); // Winkel auf Zeichenwinkel addieren
        }
        
        textAlign(LEFT); // Zählertext links anordnen
        textFont(bubbleFont); // Schriftart der Wegblasen wählen
        
        FloatList sizes = new FloatList(); // Größen aller Zähler
        Float sizeSum = 0.0; // Gesamtgröße der Zähler
        for (int i : ids) { // Für jede Person der Multiblase
          float size = round(2*(8+(0.015 * this.counterIDs.get(i)))); // Schriftgröße berechnen
          sizes.set(i,size); // Diese zur Liste Hinzufügen
          sizeSum +=size; // Zu Gesamtgröße addieren 
        }
        sizeSum = (sizeSum/2)*(-1)-5; // Gesamtgröße invertieren und anpassen für Verschiebung 
        
        for (int i : ids) { // Für jede Person eine eigene Zeile mit unterschiedlicher Anordnung
          sizeSum += (sizes.get(i)); // Größe zur Gesamtgröße hinzuaddieren
          outline(str(round(this.counterIDs.get(i))), x +(this.diameter/2), y+sizeSum,sizes.get(i)); // Zählertext umranden
        }
  }
}