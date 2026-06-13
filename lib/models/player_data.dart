class PlayerData {
  String nickname;
  String uid;

  PlayerData({
    this.nickname = '',
    this.uid = '',
  });

  factory PlayerData.fromJson(Map<String, dynamic> json) {
    return PlayerData(
      nickname: json['nickname'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'uid': uid,
      };
}
