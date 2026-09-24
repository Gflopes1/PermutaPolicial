import 'package:web/web.dart' as web;

void setAdminGraphToken(String token) {
  web.window.localStorage.setItem('admin_token', token);
}
