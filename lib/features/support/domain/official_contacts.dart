class OfficialContactLink {
  const OfficialContactLink({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.uri,
  });

  final String id;
  final String title;
  final String subtitle;
  final Uri uri;
}

abstract final class OfficialContacts {
  static const String emailAddress = 'vauvau.app@gmail.com';
  static const String instagramHandle = '@vauvau.app';
  static const String facebookName = 'Vau Vau';

  static final Uri emailUri = Uri(
    scheme: 'mailto',
    path: emailAddress,
  );
  static final Uri instagramUri = Uri.parse('https://instagram.com/vauvau.app');
  static final Uri facebookUri = Uri.parse('https://facebook.com/VauVau');

  static final List<OfficialContactLink> all = [
    OfficialContactLink(
      id: 'email',
      title: '✉️ Email us',
      subtitle: emailAddress,
      uri: emailUri,
    ),
    OfficialContactLink(
      id: 'instagram',
      title: '📸 Instagram',
      subtitle: instagramHandle,
      uri: instagramUri,
    ),
    OfficialContactLink(
      id: 'facebook',
      title: '📘 Facebook',
      subtitle: facebookName,
      uri: facebookUri,
    ),
  ];
}
