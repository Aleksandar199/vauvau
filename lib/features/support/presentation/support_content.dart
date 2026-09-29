import 'package:flutter/material.dart';

class SupportGuide {
  const SupportGuide({
    required this.icon,
    required this.color,
    required this.title,
    required this.points,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<String> points;
}

abstract final class SupportContent {
  static const List<SupportGuide> rules = [
    SupportGuide(
      icon: Icons.cleaning_services_outlined,
      color: Color(0xFF16A34A),
      title: '🧹 Počistite za psom',
      points: [
        'Uvek nosite kesice i bacite ih u kantu.',
        'Ne ostavljajte kese pored staze ili na travi.',
        'Čist park znači da psi ostaju dobrodošli.',
      ],
    ),
    SupportGuide(
      icon: Icons.link,
      color: Color(0xFF2563EB),
      title: '🦮 Povodac i bezbednost',
      points: [
        'Držite psa na povocu u prometnim zonama i na ulici.',
        'Puštajte ga samo u ograđenim delovima parka.',
        'Uvek imajte psa na vidiku i pod kontrolom.',
      ],
    ),
    SupportGuide(
      icon: Icons.park_outlined,
      color: Color(0xFFEA580C),
      title: '🌳 Ponašanje u parku',
      points: [
        'Pitajte vlasnika pre nego što psi priđu jedan drugom.',
        'Prilazite bočno, bez nagle igre i bez prisiljavanja.',
        'Ako se pas uznemiri, mirno ga odvedite na stranu.',
      ],
    ),
    SupportGuide(
      icon: Icons.forum_outlined,
      color: Color(0xFF7C3AED),
      title: '💬 Poruke, izgubljeni psi i udomljavanje',
      points: [
        'Budite ljubazni i jasni pri dogovoru šetnje: mesto, vreme, vakcine.',
        'Javite se za izgubljenog psa samo ako ste ga zaista videli.',
        'Označite oglas kao udomljen čim pas nađe dom.',
      ],
    ),
  ];

  static const List<SupportGuide> tips = [
    SupportGuide(
      icon: Icons.wb_sunny_outlined,
      color: Color(0xFFDC2626),
      title: '☀️ Toplotni talas',
      points: [
        'Šetajte rano ujutru i kasno uveče.',
        'Proverite asfalt dlanom — ako je vruć za vas, vruć je i za šape.',
        'Uvek nosite vodu i nikad ne ostavljajte psa u autu.',
        'Ubrzano dahtanje i slabost su znak pregrevanja — odmah hlad i voda.',
      ],
    ),
    SupportGuide(
      icon: Icons.medical_services_outlined,
      color: Color(0xFFDB2777),
      title: '🩹 Prva pomoć',
      points: [
        'Posekotinu isperite čistom vodom i blago pritisnite gazom.',
        'Pri sumnji na trovanje ne izazivajte povraćanje bez saveta veterinara.',
        'Imajte broj dežurne veterinarske stanice sačuvan u telefonu.',
      ],
    ),
    SupportGuide(
      icon: Icons.local_hospital_outlined,
      color: Color(0xFF0891B2),
      title: '🏥 Poseta veterinaru',
      points: [
        'Ponesite knjižicu vakcinacije i spisak lekova.',
        'Zapišite simptome i kada su počeli.',
        'Nagradite psa posle pregleda da bi sledeća poseta bila lakša.',
      ],
    ),
  ];
}
