/* Objekt Trackpoint (Wegpunkt), um die Verbindungsdaten der Personen zu speichern.
* Jeder Wegpunkt ist eine Position an der sich die Person befand.
* Es enhält das Datum (wann sie dort war), die Position (wo sie war),
* den Dienst (was sie mit ihrem Handy gemacht hat), die Richtung (ein- oder ausgehend)
* und die ID der jeweiligen Person.
*/

class Trackpoint {
  Calendar time = Calendar.getInstance(); // Datum und Uhrzeit
  String service; // Dienst
  String direction; // Richtung
  Location location; // Position
  int id;  // Person-ID

  // Konstruktor mit Datum und Uhrzeit | Dienst | Richtung | Breitengrad | Längengrad | Person-ID
  public Trackpoint(String time, String service, String direction, String lat, String lon, int id) {
    try { // Versuche Datum und Uhrzeit einzulesen
      this.time.setTime(dateformat.parse(time));
    }
    catch(ParseException e) { // Einlesefehler abfangen
      e.printStackTrace();
    }
    this.service = service;
    this.direction = direction;
    this.location = new Location(float(lat), float(lon)); // Position aus Breiten- und Längengrad bestimmen
    this.id = id;
  }
}