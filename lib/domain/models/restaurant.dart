class Restaurant {
  final String id;
  final String name;
  final String? address;
  final String? coverImagePath;
  final List<MenuItem> menu;
  final DateTime createdAt;

  Restaurant({
    required this.id,
    required this.name,
    this.address,
    this.coverImagePath,
    required this.menu,
    required this.createdAt,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      coverImagePath: json['coverImagePath'] as String?,
      menu: (json['menu'] as List<dynamic>)
          .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'coverImagePath': coverImagePath,
      'menu': menu.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Restaurant copyWith({
    String? id,
    String? name,
    String? address,
    String? coverImagePath,
    List<MenuItem>? menu,
    DateTime? createdAt,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      menu: menu ?? this.menu,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MenuItem {
  final String id;
  final String name;
  final String category;
  final String? description;
  final String? imageUrl;

  MenuItem({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.imageUrl,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  MenuItem copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? imageUrl,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
