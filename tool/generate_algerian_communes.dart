import 'dart:convert';
import 'dart:io';

void main() async {
  final wilayasFile = File('assets/data/wilayas.json');
  final wilayasRaw = json.decode(wilayasFile.readAsStringSync()) as List<dynamic>;
  final Map<int, Map<String, dynamic>> wilayaMap = {
    for (var w in wilayasRaw) (w['code'] as num).toInt(): w as Map<String, dynamic>
  };

  final client = HttpClient();

  print('Fetching ihahachi algeria_cities.geojson (1,541 communes with coordinates)...');
  final req = await client.getUrl(Uri.parse(
      'https://raw.githubusercontent.com/ihahachi/Algeria-Cities/master/geojson/algeria_cities.geojson'));
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  final geoRaw = json.decode(body) as Map<String, dynamic>;
  final features = geoRaw['features'] as List<dynamic>;
  print('Loaded ${features.length} features from ihahachi.');

  // Mapping of 2026 delegated wilayas (59-69) back to the 58 official baseline Wilayas (Law 19-12):
  final Map<int, int> parentWilayaMap = {
    59: 3,  // Aflou -> Laghouat
    60: 32, // El Abiodh Sidi Cheikh -> El Bayadh
    61: 13, // El Aricha -> Tlemcen
    62: 7,  // El Kantara -> Biskra
    63: 5,  // Barika -> Batna
    64: 28, // Bou Saada -> M'Sila
    65: 12, // Bir El Ater -> Tebessa
    66: 26, // Ksar El Boukhari -> Medea
    67: 14, // Ksar Chellala -> Tiaret
    68: 17, // Ain Oussara -> Djelfa
    69: 17, // Messaad -> Djelfa
  };

  final Map<int, List<Map<String, dynamic>>> communesByWilaya = {
    for (int w = 1; w <= 58; w++) w: []
  };

  for (final f in features) {
    final geom = f['geometry'] as Map<String, dynamic>;
    final coords = geom['coordinates'] as List<dynamic>;
    final props = f['properties'] as Map<String, dynamic>;

    final rawWilaya = (props['wilaya_code'] as num).toInt();
    final wilayaCode = rawWilaya <= 58 ? rawWilaya : (parentWilayaMap[rawWilaya] ?? rawWilaya);

    final wilaya = wilayaMap[wilayaCode];
    if (wilaya == null) {
      throw StateError('Unknown wilaya code: $wilayaCode');
    }

    final wilayaLng = (wilaya['longitude'] as num).toDouble();
    final lng = (coords[0] as num).toDouble();
    final lat = (coords[1] as num).toDouble();

    // Official MARW / CRAAG solar longitude formula:
    final minuteOffset = ((wilayaLng - lng) * 4.0).round().clamp(-15, 15);
    final code = (props['code_commune'] as num).toInt();
    final nameAr = (props['commune_name'] as String).trim();
    final nameFr = (props['commune_name_fr'] as String).trim();

    communesByWilaya[wilayaCode]!.add({
      'code': code,
      'wilayaCode': wilayaCode,
      'nameAr': nameAr,
      'nameFr': nameFr,
      'latitude': double.parse(lat.toStringAsFixed(4)),
      'longitude': double.parse(lng.toStringAsFixed(4)),
      'minuteOffset': minuteOffset,
    });
  }

  // Sort: For each Wilaya, put the chef-lieu (capital matching wilaya name) first, then sort alphabetically
  final List<Map<String, dynamic>> sortedCommunes = [];
  for (int w = 1; w <= 58; w++) {
    final list = communesByWilaya[w]!;
    final wilaya = wilayaMap[w]!;
    final wilayaNameAr = wilaya['nameAr'] as String;
    final wilayaNameFr = (wilaya['nameFr'] as String).toLowerCase();

    list.sort((a, b) {
      final aIsChefLieu = a['nameAr'] == wilayaNameAr ||
          (a['nameFr'] as String).toLowerCase() == wilayaNameFr;
      final bIsChefLieu = b['nameAr'] == wilayaNameAr ||
          (b['nameFr'] as String).toLowerCase() == wilayaNameFr;
      if (aIsChefLieu && !bIsChefLieu) return -1;
      if (!aIsChefLieu && bIsChefLieu) return 1;
      return (a['nameAr'] as String).compareTo(b['nameAr'] as String);
    });

    sortedCommunes.addAll(list);
  }

  print('Total sorted communes: ${sortedCommunes.length} across 58 wilayas.');

  final outFile = File('assets/data/algerian_communes.json');
  final encoder = const JsonEncoder.withIndent('  ');
  outFile.writeAsStringSync(encoder.convert(sortedCommunes));
  print('Successfully generated assets/data/algerian_communes.json with 1,541 communes.');
}
