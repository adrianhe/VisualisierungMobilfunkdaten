// Button ist ein Objekt zur Abbildung der Knöpfe der Visualiserung

class Button {  
  int x, y, w, h; // Position sowie Breite und Höhe des Buttons
  
  Button(int x, int y, int w, int h) { // Konstruktor je nach Position im Fenster und Größe
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  } 
  
  boolean mouseOver() { // Befindet sich die Maus über dem Kreis-Button?
    return (sq(mouseX - x) + sq(mouseY - y) <= sq((w+h)/4)); // prüft, ob der Mauszeiger innerhalb des Kreises liegt mithilfe der Kreisfunktion
  }
  
  void draw() { // Button zeichnen
    stroke(150); // Umrandung in grau
    strokeWeight(1); // mit 1 Pixel Dicke
    fill(mouseOver() ? 260 : 310); // Je nach Position der Maus Füllfarbe anpassen
    ellipse(x,y,w,h); // Kreis zeichnen
  }
}

// Neue Klasse für den Wiedergabebutton
class PlayButton extends Button {
  
  PlayButton() { // Konstruktor
    super(width/2-25, height-25, 40, 40); // Einen Button der Superklasse konstruieren
  }
  
  // Playbutton zeichnen
  void draw() {
    super.draw(); // Button der Superklasse zeichnen
    noStroke(); // Keine Umrandung
    fill(120); // Farbe ist dunkelgrau
    textAlign(CENTER); // Mittig anordnen
    textFont(infoFont); // Schrifart ist die der Infotexte 
    if(playing) { // Ist die Wiedergabe aktiviert?
      rect(width/2-31, height-32, 4, 14); // Zeichne zwei hochkante Rechtecke
      rect(width/2-22, height-32, 4, 14); // Die das Pausezeichen ergeben
      if (mouseOver()){ // Ist zusätzlich die Maus über den Button
        outline("Pause",width/2-25,height-55,12); // Schreibe "Pause" über den Button
      }
    }
    else { // Ist die Wiedergabe deaktiviert zeichne ein Dreieck, das das Playsymbol ergibt
      triangle(width/2-30, height-32, width/2-30, height-16, width/2-16, height-25);
      if (mouseOver()){ // Ist zusätzlich die Maus über den Button
        outline("Play",width/2-25,height-55,12); // Schreibe "Play" über den Button
      }
    }
  }
  
}

// Neue Klasse für den Stoppbutton
class StopButton extends Button {
  
  StopButton() { // Konstruktor
    super(width/2+25,height-25,40,40); // Einen Button der Superklasse konstruieren
  }
  
  //Stoppbutton zeichnen
  void draw() {
    super.draw(); // Button der Superklasse zeichnen
    noStroke(); // Keine Umrandung
    fill(120); // Farbe ist dunkelgrau
    rect(width/2+18, height-32, 14, 14); // Zeichne ein Quadrat, das dem Stoppsysmbol entspricht
    if (mouseOver()){ // Wenn die Maus über den Button ist
      textAlign(CENTER); // Mittig anordnen
      textFont(infoFont); // Schrifart ist die der Infotexte 
      outline("Stopp",width/2+25,height-55,12); // Schreibe "Stopp" über den Button
    }
  }
}