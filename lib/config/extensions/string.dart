extension StirngExtensions on String {
  String increment () {
    return (int.parse(this) + 1).toString();
  }
}