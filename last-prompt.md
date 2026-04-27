you where working on this flutter app: [@sushare-flutter-prompt.md](file:///home/leonardo/Documenti/Personal_projects/Sushare/sushare-flutter-prompt.md) 

i need to implement this enhancement: update the onboarding to specify that the join to another table uses ble. check if bluetooth is enabled and granted to the app and present a warning telling that users cannot join or share tables otherwhise, but do not prevent the use of the app (it can be used as single user too)

---

replace the plugin "flutter_nearby_connections_plus" that not supports AGP 8 with the plugin "https://pub.dev/packages/bluetooth_low_energy" and adapt the app logic to use ble as p2p communication channel
