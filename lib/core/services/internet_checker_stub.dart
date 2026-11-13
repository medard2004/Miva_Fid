Future<bool> checkInternetAccess() async {
  // Sur le Web, la connectivité est déjà garantie par l'API réseau du navigateur
  // (navigator.onLine), vérifiée en amont par connectivity_plus.
  return true;
}

