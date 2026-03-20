import 'package:google_sign_in/google_sign_in.dart';

void main() {
  GoogleSignIn gs = GoogleSignIn.instance;
  gs.clientId = 'abc';
  print(gs);
}
