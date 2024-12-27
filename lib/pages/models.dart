class Kullanici {
  int kID;
  String kEmail;
  String kSifre;

  Kullanici({
    required this.kID,
    required this.kEmail,
    required this.kSifre,
  });
}

class Proje {
  int pID;
  String pAd;
  DateTime pBaslaTarih;
  DateTime pBitisTarih;
  int pGecikmeSure;
  Kullanici kullanici;

  Proje({
    required this.pID,
    required this.pAd,
    required this.pBaslaTarih,
    required this.pBitisTarih,
    this.pGecikmeSure = 0,
    required this.kullanici,
  });
}

class Gorev {
  int gID;
  DateTime gBaslaTarih;
  DateTime gBitisTarih;
  int gAdamGun;
  String gDurum;
  Calisanlar cID;
  Proje pID;

  Gorev({
    this.gID = 0,
    required this.gBaslaTarih,
    required this.gBitisTarih,
    this.gAdamGun = 1,
    required this.gDurum,
    required this.cID,
    required this.pID,
  });

}

class Calisanlar {
  int cID;
  String cAdSoyad;

  Calisanlar({
    required this.cID,
    required this.cAdSoyad,
  });

  factory Calisanlar.fromJson(Map<String, dynamic> json) {
    return Calisanlar(
      cID: json['cID'],
      cAdSoyad: json['cAdSoyad'],
    );
  }
}