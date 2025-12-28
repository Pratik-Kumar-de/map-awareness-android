/// ARS (Official Regional Key) lookup for German cities
/// Extended coverage with major cities and their regions
const Map<String, String> _arsLookup = {
  // City States
  'berlin': '11000000',
  'hamburg': '02000000',
  'bremen': '04011000',
  'bremerhaven': '04012000',
  
  // Bavaria
  'munich': '09162000',
  'nuremberg': '09564000',
  'augsburg': '09761000',
  'regensburg': '09362000',
  'ingolstadt': '09161000',
  'wurzburg': '09663000',
  'furth': '09563000',
  'erlangen': '09562000',
  'bamberg': '09461000',
  'bayreuth': '09462000',
  'landshut': '09261000',
  'passau': '09262000',
  'rosenheim': '09163000',
  
  // Baden-Württemberg
  'stuttgart': '08111000',
  'karlsruhe': '08212000',
  'mannheim': '08222000',
  'freiburg': '08311000',
  'heidelberg': '08221000',
  'ulm': '08421000',
  'heilbronn': '08121000',
  'pforzheim': '08231000',
  'reutlingen': '08415000',
  'esslingen': '08116000',
  'ludwigsburg': '08118000',
  'konstanz': '08335000',
  'tuebingen': '08416000',
  
  // North Rhine-Westphalia (NRW)
  'cologne': '05315000',
  'duesseldorf': '05111000',
  'dortmund': '05913000',
  'essen': '05113000',
  'duisburg': '05112000',
  'bochum': '05911000',
  'wuppertal': '05124000',
  'bielefeld': '05711000',
  'bonn': '05314000',
  'muenster': '05515000',
  'aachen': '05334000',
  'gelsenkirchen': '05513000',
  'moenchengladbach': '05116000',
  'krefeld': '05114000',
  'oberhausen': '05119000',
  'hagen': '05914000',
  'hamm': '05915000',
  'muelheim': '05117000',
  'leverkusen': '05316000',
  'solingen': '05122000',
  'remscheid': '05120000',
  'paderborn': '05774000',
  'siegen': '05970000',
  
  // Hesse
  'frankfurt': '06412000',
  'wiesbaden': '06414000',
  'kassel': '06611000',
  'darmstadt': '06411000',
  'offenbach': '06413000',
  'giessen': '06531000',
  'marburg': '06534000',
  'fulda': '06631000',
  
  // Lower Saxony
  'hanover': '03241000',
  'braunschweig': '03101000',
  'oldenburg': '03403000',
  'osnabrueck': '03404000',
  'wolfsburg': '03103000',
  'goettingen': '03152000',
  'salzgitter': '03102000',
  'hildesheim': '03254000',
  'delmenhorst': '03401000',
  'wilhelmshaven': '03405000',
  'celle': '03351000',
  'lueneburg': '03355000',
  
  // Saxony
  'leipzig': '14713000',
  'dresden': '14612000',
  'chemnitz': '14511000',
  'zwickau': '14524000',
  'plauen': '14523000',
  'goerlitz': '14626000',
  
  // Saxony-Anhalt
  'magdeburg': '15003000',
  'halle': '15002000',
  'dessau': '15001000',
  'wittenberg': '15091000',
  
  // Thuringia
  'erfurt': '16051000',
  'jena': '16053000',
  'gera': '16052000',
  'weimar': '16055000',
  'gotha': '16067000',
  'eisenach': '16056000',
  
  // Brandenburg
  'potsdam': '12054000',
  'cottbus': '12052000',
  'brandenburg': '12051000',
  'frankfurt oder': '12053000',
  
  // Schleswig-Holstein
  'kiel': '01002000',
  'luebeck': '01003000',
  'flensburg': '01001000',
  'neumuenster': '01004000',
  
  // Mecklenburg-Vorpommern
  'rostock': '13003000',
  'schwerin': '13004000',
  'neubrandenburg': '13071000',
  'stralsund': '13073000',
  'greifswald': '13001000',
  'wismar': '13074000',
  
  // Rhineland-Palatinate
  'mainz': '07315000',
  'ludwigshafen': '07314000',
  'koblenz': '07111000',
  'trier': '07211000',
  'kaiserslautern': '07312000',
  
  // Saarland
  'saarbruecken': '10041000',
  'saarlouis': '10044000',
  'neunkirchen': '10043000',
};

/// Looks up ARS code for a city name (case-insensitive, handles common variants)
String? lookupARSForCity(String cityName) {
  final normalized = cityName.toLowerCase().trim();
  
  if (_arsLookup.containsKey(normalized)) {
    return _arsLookup[normalized];
  }
  
  for (final entry in _arsLookup.entries) {
    if (normalized.startsWith(entry.key) || entry.key.startsWith(normalized)) {
      return entry.value;
    }
  }
  
  return null;
}
