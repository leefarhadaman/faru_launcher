class LauncherApp implements Comparable<LauncherApp> {
  const LauncherApp({
    required this.label,
    required this.packageName,
  });

  final String label;
  final String packageName;

  factory LauncherApp.fromMap(Map<Object?, Object?> map) {
    final rawPackage = map['packageName']?.toString().trim() ?? '';
    if (rawPackage.isEmpty) {
      throw const FormatException('LauncherApp requires a non-empty packageName');
    }
    final rawLabel = map['label']?.toString().trim() ?? '';
    return LauncherApp(
      label: rawLabel.isEmpty ? rawPackage : rawLabel,
      packageName: rawPackage,
    );
  }

  Map<String, String> toMap() => <String, String>{
        'label': label,
        'packageName': packageName,
      };

  @override
  int compareTo(LauncherApp other) {
    final labelComparison = label.toLowerCase().compareTo(other.label.toLowerCase());
    if (labelComparison != 0) {
      return labelComparison;
    }
    return packageName.toLowerCase().compareTo(other.packageName.toLowerCase());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LauncherApp &&
        other.label == label &&
        other.packageName == packageName;
  }

  @override
  int get hashCode => Object.hash(label, packageName);

  @override
  String toString() => 'LauncherApp(label: $label, packageName: $packageName)';
}
