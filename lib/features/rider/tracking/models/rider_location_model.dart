class RiderLocationUpdate {
  final String orderId;
  final double latitude;
  final double longitude;

  const RiderLocationUpdate({
    required this.orderId,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'coords': {
          'latitude': latitude,
          'longitude': longitude,
        },
      };
}
