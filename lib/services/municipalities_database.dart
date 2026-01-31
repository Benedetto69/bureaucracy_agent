/// Database dei comuni italiani con indirizzi PEC
/// per facilitare l'invio di ricorsi e comunicazioni
class MunicipalitiesDatabase {
  /// Cerca comuni per nome (case-insensitive, parziale)
  static List<Municipality> search(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase().trim();

    // Exact match first, then partial matches
    final exactMatches = <Municipality>[];
    final startsWithMatches = <Municipality>[];
    final containsMatches = <Municipality>[];

    for (final municipality in _municipalities) {
      final lowerName = municipality.name.toLowerCase();
      if (lowerName == lowerQuery) {
        exactMatches.add(municipality);
      } else if (lowerName.startsWith(lowerQuery)) {
        startsWithMatches.add(municipality);
      } else if (lowerName.contains(lowerQuery)) {
        containsMatches.add(municipality);
      }
    }

    return [...exactMatches, ...startsWithMatches, ...containsMatches];
  }

  /// Cerca per provincia (sigla)
  static List<Municipality> searchByProvince(String provinceCode) {
    final upperCode = provinceCode.toUpperCase().trim();
    return _municipalities
        .where((m) => m.provinceCode == upperCode)
        .toList();
  }

  /// Ottieni un comune per nome esatto
  static Municipality? getByName(String name) {
    final lowerName = name.toLowerCase().trim();
    try {
      return _municipalities.firstWhere(
        (m) => m.name.toLowerCase() == lowerName,
      );
    } catch (_) {
      return null;
    }
  }

  /// Lista di tutti i capoluoghi di provincia
  static List<Municipality> get provincialCapitals {
    return _municipalities.where((m) => m.isProvincialCapital).toList();
  }

  /// Lista di tutte le province disponibili
  static List<String> get availableProvinces {
    final provinces = <String>{};
    for (final m in _municipalities) {
      provinces.add(m.provinceCode);
    }
    return provinces.toList()..sort();
  }

  /// Database dei comuni più popolosi e capoluoghi
  static final List<Municipality> _municipalities = [
    // Lombardia
    const Municipality(
      name: 'Milano',
      provinceCode: 'MI',
      region: 'Lombardia',
      pecPoliziaMunicipale: 'polizialocale@pec.comune.milano.it',
      pecProtocollo: 'protocollo@pec.comune.milano.it',
      pecPrefettura: 'protocollo.prefmi@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Monza',
      provinceCode: 'MB',
      region: 'Lombardia',
      pecPoliziaMunicipale: 'polizialocale@pec.comune.monza.it',
      pecProtocollo: 'protocollo@pec.comune.monza.it',
      pecPrefettura: 'protocollo.prefmb@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Bergamo',
      provinceCode: 'BG',
      region: 'Lombardia',
      pecPoliziaMunicipale: 'polizialocale@cert.comune.bergamo.it',
      pecProtocollo: 'protocollo@cert.comune.bergamo.it',
      pecPrefettura: 'protocollo.prefbg@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Brescia',
      provinceCode: 'BS',
      region: 'Lombardia',
      pecPoliziaMunicipale: 'polizialocale@pec.comune.brescia.it',
      pecProtocollo: 'protocollo@pec.comune.brescia.it',
      pecPrefettura: 'protocollo.prefbs@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Como',
      provinceCode: 'CO',
      region: 'Lombardia',
      pecPoliziaMunicipale: 'polizialocale.comune.como@pec.regione.lombardia.it',
      pecProtocollo: 'comune.como@pec.regione.lombardia.it',
      pecPrefettura: 'protocollo.prefco@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Varese',
      provinceCode: 'VA',
      region: 'Lombardia',
      pecPoliziaMunicipale: 'polizialocale@comune.varese.legalmail.it',
      pecProtocollo: 'protocollo@comune.varese.legalmail.it',
      pecPrefettura: 'protocollo.prefva@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Pavia',
      provinceCode: 'PV',
      region: 'Lombardia',
      pecPoliziaMunicipale: 'polizialocale@pec.comune.pavia.it',
      pecProtocollo: 'protocollo@pec.comune.pavia.it',
      pecPrefettura: 'protocollo.prefpv@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Cremona',
      provinceCode: 'CR',
      region: 'Lombardia',
      pecPoliziaMunicipale: 'poliziamunicipale@comunedicremona.legalmail.it',
      pecProtocollo: 'protocollo@comunedicremona.legalmail.it',
      pecPrefettura: 'protocollo.prefcr@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Mantova',
      provinceCode: 'MN',
      region: 'Lombardia',
      pecPoliziaMunicipale: 'poliziamunicipale.comunemantova@legalmail.it',
      pecProtocollo: 'protocollo.comunemantova@legalmail.it',
      pecPrefettura: 'protocollo.prefmn@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Lecco',
      provinceCode: 'LC',
      region: 'Lombardia',
      pecPoliziaMunicipale: 'polizialocale@pec.comunedilecco.it',
      pecProtocollo: 'comune@pec.comunedilecco.it',
      pecPrefettura: 'protocollo.preflc@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Lodi',
      provinceCode: 'LO',
      region: 'Lombardia',
      pecPoliziaMunicipale: 'polizialocale@pec.comune.lodi.it',
      pecProtocollo: 'comunelodi@pec.comune.lodi.it',
      pecPrefettura: 'protocollo.preflo@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Sondrio',
      provinceCode: 'SO',
      region: 'Lombardia',
      pecPoliziaMunicipale: 'polizialocale.sondrio@cert.polizialocale.it',
      pecProtocollo: 'protocollo.sondrio@cert.legalmail.it',
      pecPrefettura: 'protocollo.prefso@pec.interno.it',
      isProvincialCapital: true,
    ),

    // Piemonte
    const Municipality(
      name: 'Torino',
      provinceCode: 'TO',
      region: 'Piemonte',
      pecPoliziaMunicipale: 'poliziamunicipale@cert.comune.torino.it',
      pecProtocollo: 'protocollo@cert.comune.torino.it',
      pecPrefettura: 'protocollo.prefto@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Novara',
      provinceCode: 'NO',
      region: 'Piemonte',
      pecPoliziaMunicipale: 'poliziamunicipale@cert.comune.novara.it',
      pecProtocollo: 'protocollo@cert.comune.novara.it',
      pecPrefettura: 'protocollo.prefno@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Alessandria',
      provinceCode: 'AL',
      region: 'Piemonte',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.alessandria.it',
      pecProtocollo: 'protocollo@pec.comune.alessandria.it',
      pecPrefettura: 'protocollo.prefal@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Asti',
      provinceCode: 'AT',
      region: 'Piemonte',
      pecPoliziaMunicipale: 'poliziamunicipale.comuneasti@pec.it',
      pecProtocollo: 'protocollo.comuneasti@pec.it',
      pecPrefettura: 'protocollo.prefat@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Cuneo',
      provinceCode: 'CN',
      region: 'Piemonte',
      pecPoliziaMunicipale: 'poliziamunicipale.cuneo@cert.ruparpiemonte.it',
      pecProtocollo: 'comune.cuneo@cert.ruparpiemonte.it',
      pecPrefettura: 'protocollo.prefcn@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Vercelli',
      provinceCode: 'VC',
      region: 'Piemonte',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.vercelli.it',
      pecProtocollo: 'protocollo@pec.comune.vercelli.it',
      pecPrefettura: 'protocollo.prefvc@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Biella',
      provinceCode: 'BI',
      region: 'Piemonte',
      pecPoliziaMunicipale: 'poliziamunicipale.biella@pec.ptbiellese.it',
      pecProtocollo: 'comune.biella.bi@legalmail.it',
      pecPrefettura: 'protocollo.prefbi@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Verbania',
      provinceCode: 'VB',
      region: 'Piemonte',
      pecPoliziaMunicipale: 'polizialocale@pec.comune.verbania.it',
      pecProtocollo: 'protocollo@pec.comune.verbania.it',
      pecPrefettura: 'protocollo.prefvb@pec.interno.it',
      isProvincialCapital: true,
    ),

    // Veneto
    const Municipality(
      name: 'Venezia',
      provinceCode: 'VE',
      region: 'Veneto',
      pecPoliziaMunicipale: 'polizialocale@pec.comune.venezia.it',
      pecProtocollo: 'protocollo@pec.comune.venezia.it',
      pecPrefettura: 'protocollo.prefve@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Padova',
      provinceCode: 'PD',
      region: 'Veneto',
      pecPoliziaMunicipale: 'polizialocale@pec.comune.padova.it',
      pecProtocollo: 'comune.padova@cert.comune.padova.it',
      pecPrefettura: 'protocollo.prefpd@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Verona',
      provinceCode: 'VR',
      region: 'Veneto',
      pecPoliziaMunicipale: 'poliziamunicipale.comune.verona@pecveneto.it',
      pecProtocollo: 'protocollo.comune.verona@pecveneto.it',
      pecPrefettura: 'protocollo.prefvr@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Vicenza',
      provinceCode: 'VI',
      region: 'Veneto',
      pecPoliziaMunicipale: 'polizialocale@cert.comune.vicenza.it',
      pecProtocollo: 'comune.vicenza@cert.comune.vicenza.it',
      pecPrefettura: 'protocollo.prefvi@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Treviso',
      provinceCode: 'TV',
      region: 'Veneto',
      pecPoliziaMunicipale: 'polizialocale.comune.treviso@pecveneto.it',
      pecProtocollo: 'postacertificata.comune.treviso@pecveneto.it',
      pecPrefettura: 'protocollo.preftv@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Belluno',
      provinceCode: 'BL',
      region: 'Veneto',
      pecPoliziaMunicipale: 'polizialocale.comune.belluno@pecveneto.it',
      pecProtocollo: 'comune.belluno@pecveneto.it',
      pecPrefettura: 'protocollo.prefbl@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Rovigo',
      provinceCode: 'RO',
      region: 'Veneto',
      pecPoliziaMunicipale: 'poliziamunicipale.comune.rovigo@pecveneto.it',
      pecProtocollo: 'comune.rovigo@legalmail.it',
      pecPrefettura: 'protocollo.prefro@pec.interno.it',
      isProvincialCapital: true,
    ),

    // Emilia-Romagna
    const Municipality(
      name: 'Bologna',
      provinceCode: 'BO',
      region: 'Emilia-Romagna',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.bologna.it',
      pecProtocollo: 'protocollogenerale@pec.comune.bologna.it',
      pecPrefettura: 'protocollo.prefbo@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Modena',
      provinceCode: 'MO',
      region: 'Emilia-Romagna',
      pecPoliziaMunicipale: 'poliziamunicipale@cert.comune.modena.it',
      pecProtocollo: 'comune.modena@cert.comune.modena.it',
      pecPrefettura: 'protocollo.prefmo@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Parma',
      provinceCode: 'PR',
      region: 'Emilia-Romagna',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.parma.it',
      pecProtocollo: 'protocollo@pec.comune.parma.it',
      pecPrefettura: 'protocollo.prefpr@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Reggio Emilia',
      provinceCode: 'RE',
      region: 'Emilia-Romagna',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.municipio.re.it',
      pecProtocollo: 'comune.reggioemilia@pec.municipio.re.it',
      pecPrefettura: 'protocollo.prefre@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Ravenna',
      provinceCode: 'RA',
      region: 'Emilia-Romagna',
      pecPoliziaMunicipale: 'pg.polizia.municipale.ravenna@legalmail.it',
      pecProtocollo: 'pg.comune.ravenna@legalmail.it',
      pecPrefettura: 'protocollo.prefra@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Rimini',
      provinceCode: 'RN',
      region: 'Emilia-Romagna',
      pecPoliziaMunicipale: 'pm@pec.comune.rimini.it',
      pecProtocollo: 'comune.rimini@legalmail.it',
      pecPrefettura: 'protocollo.prefrn@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Ferrara',
      provinceCode: 'FE',
      region: 'Emilia-Romagna',
      pecPoliziaMunicipale: 'poliziamunicipale@cert.comune.fe.it',
      pecProtocollo: 'comune.ferrara@cert.comune.fe.it',
      pecPrefettura: 'protocollo.preffe@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Forlì',
      provinceCode: 'FC',
      region: 'Emilia-Romagna',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.forli.fc.it',
      pecProtocollo: 'comune.forli@pec.comune.forli.fc.it',
      pecPrefettura: 'protocollo.preffc@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Piacenza',
      provinceCode: 'PC',
      region: 'Emilia-Romagna',
      pecPoliziaMunicipale: 'poliziamunicipale@cert.comune.piacenza.it',
      pecProtocollo: 'comune.piacenza@cert.comune.piacenza.it',
      pecPrefettura: 'protocollo.prefpc@pec.interno.it',
      isProvincialCapital: true,
    ),

    // Toscana
    const Municipality(
      name: 'Firenze',
      provinceCode: 'FI',
      region: 'Toscana',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.fi.it',
      pecProtocollo: 'protocollo@pec.comune.fi.it',
      pecPrefettura: 'protocollo.preffi@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Pisa',
      provinceCode: 'PI',
      region: 'Toscana',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.pisa.it',
      pecProtocollo: 'comune.pisa@postacert.toscana.it',
      pecPrefettura: 'protocollo.prefpi@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Livorno',
      provinceCode: 'LI',
      region: 'Toscana',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.livorno.it',
      pecProtocollo: 'comune.livorno@postacert.toscana.it',
      pecPrefettura: 'protocollo.prefli@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Siena',
      provinceCode: 'SI',
      region: 'Toscana',
      pecPoliziaMunicipale: 'poliziamunicipale@postacert.comune.siena.it',
      pecProtocollo: 'comune.siena@postacert.toscana.it',
      pecPrefettura: 'protocollo.prefsi@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Arezzo',
      provinceCode: 'AR',
      region: 'Toscana',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.arezzo.it',
      pecProtocollo: 'comune.arezzo@postacert.toscana.it',
      pecPrefettura: 'protocollo.prefar@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Lucca',
      provinceCode: 'LU',
      region: 'Toscana',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.lucca.it',
      pecProtocollo: 'comune.lucca@postacert.toscana.it',
      pecPrefettura: 'protocollo.preflu@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Pistoia',
      provinceCode: 'PT',
      region: 'Toscana',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.pistoia.it',
      pecProtocollo: 'comune.pistoia@postacert.toscana.it',
      pecPrefettura: 'protocollo.prefpt@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Grosseto',
      provinceCode: 'GR',
      region: 'Toscana',
      pecPoliziaMunicipale: 'pm.comunegrosseto@postacert.toscana.it',
      pecProtocollo: 'comune.grosseto@postacert.toscana.it',
      pecPrefettura: 'protocollo.prefgr@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Massa',
      provinceCode: 'MS',
      region: 'Toscana',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.massa.ms.it',
      pecProtocollo: 'comune.massa@postacert.toscana.it',
      pecPrefettura: 'protocollo.prefms@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Prato',
      provinceCode: 'PO',
      region: 'Toscana',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.prato.it',
      pecProtocollo: 'comune.prato@postacert.toscana.it',
      pecPrefettura: 'protocollo.prefpo@pec.interno.it',
      isProvincialCapital: true,
    ),

    // Lazio
    const Municipality(
      name: 'Roma',
      provinceCode: 'RM',
      region: 'Lazio',
      pecPoliziaMunicipale: 'poliziaromacapitale@pec.comune.roma.it',
      pecProtocollo: 'protocollo.comuneroma@pec.comune.roma.it',
      pecPrefettura: 'protocollo.prefrm@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Latina',
      provinceCode: 'LT',
      region: 'Lazio',
      pecPoliziaMunicipale: 'polizialocale@pec.comune.latina.it',
      pecProtocollo: 'protocollo@pec.comune.latina.it',
      pecPrefettura: 'protocollo.preflt@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Frosinone',
      provinceCode: 'FR',
      region: 'Lazio',
      pecPoliziaMunicipale: 'pm@pec.comune.frosinone.it',
      pecProtocollo: 'protocollo@pec.comune.frosinone.it',
      pecPrefettura: 'protocollo.preffr@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Viterbo',
      provinceCode: 'VT',
      region: 'Lazio',
      pecPoliziaMunicipale: 'polizialocale@pec.comuneviterbo.it',
      pecProtocollo: 'protocollo@pec.comuneviterbo.it',
      pecPrefettura: 'protocollo.prefvt@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Rieti',
      provinceCode: 'RI',
      region: 'Lazio',
      pecPoliziaMunicipale: 'polizialocale.rieti@legalmail.it',
      pecProtocollo: 'comune.rieti@legalmail.it',
      pecPrefettura: 'protocollo.prefri@pec.interno.it',
      isProvincialCapital: true,
    ),

    // Campania
    const Municipality(
      name: 'Napoli',
      provinceCode: 'NA',
      region: 'Campania',
      pecPoliziaMunicipale: 'polizialocale@pec.comune.napoli.it',
      pecProtocollo: 'protocollo@pec.comune.napoli.it',
      pecPrefettura: 'protocollo.prefna@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Salerno',
      provinceCode: 'SA',
      region: 'Campania',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.salerno.it',
      pecProtocollo: 'protocollo@pec.comune.salerno.it',
      pecPrefettura: 'protocollo.prefsa@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Caserta',
      provinceCode: 'CE',
      region: 'Campania',
      pecPoliziaMunicipale: 'comandopm@pec.comune.caserta.it',
      pecProtocollo: 'protocollo@pec.comune.caserta.it',
      pecPrefettura: 'protocollo.prefce@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Avellino',
      provinceCode: 'AV',
      region: 'Campania',
      pecPoliziaMunicipale: 'poliziamunicipale.avellino@asmepec.it',
      pecProtocollo: 'protocollo.avellino@asmepec.it',
      pecPrefettura: 'protocollo.prefav@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Benevento',
      provinceCode: 'BN',
      region: 'Campania',
      pecPoliziaMunicipale: 'poliziamunicipale.comune.benevento@pec.it',
      pecProtocollo: 'protocollo@pec.comunebenevento.it',
      pecPrefettura: 'protocollo.prefbn@pec.interno.it',
      isProvincialCapital: true,
    ),

    // Sicilia
    const Municipality(
      name: 'Palermo',
      provinceCode: 'PA',
      region: 'Sicilia',
      pecPoliziaMunicipale: 'poliziamunicipale@cert.comune.palermo.it',
      pecProtocollo: 'protocollo@cert.comune.palermo.it',
      pecPrefettura: 'protocollo.prefpa@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Catania',
      provinceCode: 'CT',
      region: 'Sicilia',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.catania.it',
      pecProtocollo: 'protocollo@pec.comune.catania.it',
      pecPrefettura: 'protocollo.prefct@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Messina',
      provinceCode: 'ME',
      region: 'Sicilia',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.messina.it',
      pecProtocollo: 'protocollo@pec.comune.messina.it',
      pecPrefettura: 'protocollo.prefme@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Siracusa',
      provinceCode: 'SR',
      region: 'Sicilia',
      pecPoliziaMunicipale: 'poliziamunicipale.siracusa@pec.it',
      pecProtocollo: 'comune.siracusa@pec.it',
      pecPrefettura: 'protocollo.prefsr@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Ragusa',
      provinceCode: 'RG',
      region: 'Sicilia',
      pecPoliziaMunicipale: 'poliziamunicipale.ragusa@pec.it',
      pecProtocollo: 'protocollo@pec.comune.ragusa.it',
      pecPrefettura: 'protocollo.prefrg@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Trapani',
      provinceCode: 'TP',
      region: 'Sicilia',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.trapani.it',
      pecProtocollo: 'protocollo@pec.comune.trapani.it',
      pecPrefettura: 'protocollo.preftp@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Agrigento',
      provinceCode: 'AG',
      region: 'Sicilia',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.agrigento.it',
      pecProtocollo: 'protocollo@pec.comune.agrigento.it',
      pecPrefettura: 'protocollo.prefag@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Caltanissetta',
      provinceCode: 'CL',
      region: 'Sicilia',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.caltanissetta.it',
      pecProtocollo: 'protocollo@pec.comune.caltanissetta.it',
      pecPrefettura: 'protocollo.prefcl@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Enna',
      provinceCode: 'EN',
      region: 'Sicilia',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.enna.it',
      pecProtocollo: 'protocollo@pec.comune.enna.it',
      pecPrefettura: 'protocollo.prefen@pec.interno.it',
      isProvincialCapital: true,
    ),

    // Sardegna
    const Municipality(
      name: 'Cagliari',
      provinceCode: 'CA',
      region: 'Sardegna',
      pecPoliziaMunicipale: 'poliziamunicipale@comune.cagliari.legalmail.it',
      pecProtocollo: 'comune.cagliari@legalmail.it',
      pecPrefettura: 'protocollo.prefca@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Sassari',
      provinceCode: 'SS',
      region: 'Sardegna',
      pecPoliziaMunicipale: 'pm.comunesassari@pec.it',
      pecProtocollo: 'protocollo@pec.comune.sassari.it',
      pecPrefettura: 'protocollo.prefss@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Nuoro',
      provinceCode: 'NU',
      region: 'Sardegna',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.nuoro.it',
      pecProtocollo: 'protocollo@pec.comune.nuoro.it',
      pecPrefettura: 'protocollo.prefnu@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Oristano',
      provinceCode: 'OR',
      region: 'Sardegna',
      pecPoliziaMunicipale: 'poliziamunicipale.oristano@pec.comunas.it',
      pecProtocollo: 'protocollo.oristano@pec.comunas.it',
      pecPrefettura: 'protocollo.prefor@pec.interno.it',
      isProvincialCapital: true,
    ),

    // Puglia
    const Municipality(
      name: 'Bari',
      provinceCode: 'BA',
      region: 'Puglia',
      pecPoliziaMunicipale: 'poliziamunicipale.comunebari@pec.rupar.puglia.it',
      pecProtocollo: 'protocollo.comunebari@pec.rupar.puglia.it',
      pecPrefettura: 'protocollo.prefba@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Lecce',
      provinceCode: 'LE',
      region: 'Puglia',
      pecPoliziaMunicipale: 'polizialocale.lecce@pec.rupar.puglia.it',
      pecProtocollo: 'protocollo.comunelecce@pec.rupar.puglia.it',
      pecPrefettura: 'protocollo.prefle@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Taranto',
      provinceCode: 'TA',
      region: 'Puglia',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.taranto.it',
      pecProtocollo: 'protocollo@pec.comune.taranto.it',
      pecPrefettura: 'protocollo.prefta@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Foggia',
      provinceCode: 'FG',
      region: 'Puglia',
      pecPoliziaMunicipale: 'poliziamunicipale@cert.comune.foggia.it',
      pecProtocollo: 'protocollo@cert.comune.foggia.it',
      pecPrefettura: 'protocollo.preffg@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Brindisi',
      provinceCode: 'BR',
      region: 'Puglia',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.brindisi.it',
      pecProtocollo: 'protocollo@pec.comune.brindisi.it',
      pecPrefettura: 'protocollo.prefbr@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Barletta',
      provinceCode: 'BT',
      region: 'Puglia',
      pecPoliziaMunicipale: 'pl.comunebarletta@pec.rupar.puglia.it',
      pecProtocollo: 'protocollo.barletta@pec.rupar.puglia.it',
      pecPrefettura: 'protocollo.prefbt@pec.interno.it',
      isProvincialCapital: true,
    ),

    // Altre regioni - capoluoghi principali
    const Municipality(
      name: 'Genova',
      provinceCode: 'GE',
      region: 'Liguria',
      pecPoliziaMunicipale: 'polizialocale@pec.comune.genova.it',
      pecProtocollo: 'comunegenova@postemailcertificata.it',
      pecPrefettura: 'protocollo.prefge@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Trieste',
      provinceCode: 'TS',
      region: 'Friuli-Venezia Giulia',
      pecPoliziaMunicipale: 'polizialocale@certgov.fvg.it',
      pecProtocollo: 'comune.trieste@certgov.fvg.it',
      pecPrefettura: 'protocollo.prefts@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Trento',
      provinceCode: 'TN',
      region: 'Trentino-Alto Adige',
      pecPoliziaMunicipale: 'polizialocale@pec.comune.trento.it',
      pecProtocollo: 'comune@pec.comune.trento.it',
      pecPrefettura: 'protocollo.preftn@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Bolzano',
      provinceCode: 'BZ',
      region: 'Trentino-Alto Adige',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.bolzano.it',
      pecProtocollo: 'bz@legalmail.it',
      pecPrefettura: 'protocollo.prefbz@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Aosta',
      provinceCode: 'AO',
      region: "Valle d'Aosta",
      pecPoliziaMunicipale: 'pl_aosta@pec.it',
      pecProtocollo: 'protocollo@pec.comune.aosta.it',
      pecPrefettura: 'protocollo.prefao@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Perugia',
      provinceCode: 'PG',
      region: 'Umbria',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.perugia.it',
      pecProtocollo: 'comune.perugia@postacert.umbria.it',
      pecPrefettura: 'protocollo.prefpg@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Terni',
      provinceCode: 'TR',
      region: 'Umbria',
      pecPoliziaMunicipale: 'polizialocale.terni@postacert.umbria.it',
      pecProtocollo: 'comune.terni@postacert.umbria.it',
      pecPrefettura: 'protocollo.preftr@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Ancona',
      provinceCode: 'AN',
      region: 'Marche',
      pecPoliziaMunicipale: 'polizialocale.comuneancona@emarche.it',
      pecProtocollo: 'comune.ancona@emarche.it',
      pecPrefettura: 'protocollo.prefan@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: "L'Aquila",
      provinceCode: 'AQ',
      region: 'Abruzzo',
      pecPoliziaMunicipale: 'poliziamunicipale.comunelaquila@pec.it',
      pecProtocollo: 'protocollo.comunelaquila@pec.it',
      pecPrefettura: 'protocollo.prefaq@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Campobasso',
      provinceCode: 'CB',
      region: 'Molise',
      pecPoliziaMunicipale: 'polizialocale@pec.comune.campobasso.it',
      pecProtocollo: 'protocollo@pec.comune.campobasso.it',
      pecPrefettura: 'protocollo.prefcb@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Potenza',
      provinceCode: 'PZ',
      region: 'Basilicata',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.comune.potenza.it',
      pecProtocollo: 'protocollo@pec.comune.potenza.it',
      pecPrefettura: 'protocollo.prefpz@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Catanzaro',
      provinceCode: 'CZ',
      region: 'Calabria',
      pecPoliziaMunicipale: 'polizialocale@pec.comune.catanzaro.it',
      pecProtocollo: 'protocollo@pec.comune.catanzaro.it',
      pecPrefettura: 'protocollo.prefcz@pec.interno.it',
      isProvincialCapital: true,
    ),
    const Municipality(
      name: 'Reggio Calabria',
      provinceCode: 'RC',
      region: 'Calabria',
      pecPoliziaMunicipale: 'poliziamunicipale@pec.reggiocal.it',
      pecProtocollo: 'protocollo@pec.reggiocal.it',
      pecPrefettura: 'protocollo.prefrc@pec.interno.it',
      isProvincialCapital: true,
    ),
  ];
}

/// Rappresenta un comune italiano con i suoi contatti PEC
class Municipality {
  final String name;
  final String provinceCode;
  final String region;
  final String pecPoliziaMunicipale;
  final String pecProtocollo;
  final String pecPrefettura;
  final bool isProvincialCapital;

  const Municipality({
    required this.name,
    required this.provinceCode,
    required this.region,
    required this.pecPoliziaMunicipale,
    required this.pecProtocollo,
    required this.pecPrefettura,
    this.isProvincialCapital = false,
  });

  /// Nome completo con provincia
  String get fullName => '$name ($provinceCode)';

  /// Descrizione breve
  String get description => '$region - $provinceCode';
}
