import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart'; // For PlatformException

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream theo dõi trạng thái user (signed in/out)
  Stream<User?> get userChanges => _auth.authStateChanges();

  /// Đăng nhập bằng email & password
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  /// Đăng ký tài khoản mới
  Future<UserCredential> register(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  /// Đăng nhập bằng Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Bắt đầu quá trình đăng nhập Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Nếu người dùng hủy bỏ
      if (googleUser == null) {
        print('⚠️ Người dùng đã hủy đăng nhập Google');
        return null;
      }

      // Lấy thông tin xác thực từ tài khoản Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // ✅ In ra để debug token
      print('🔐 AccessToken: ${googleAuth.accessToken}');
      print('🔐 IdToken: ${googleAuth.idToken}');

      if (googleAuth.idToken == null) {
        throw 'Không nhận được ID token từ Google. Có thể thiếu cấu hình SHA-1 hoặc OAuth2 client.';
      }

      // Tạo một credential Firebase từ token của Google
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Đăng nhập vào Firebase với credential
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleFirebaseAuthException(e);
    } on PlatformException catch (e) {
      print('❌ PlatformException: ${e.code} - ${e.message}');
      if (e.code == 'network_error') {
        throw 'Lỗi mạng. Vui lòng kiểm tra kết nối của bạn.';
      } else if (e.code == GoogleSignIn.kSignInFailedError || e.code == GoogleSignIn.kSignInCanceledError) {
        throw 'Đăng nhập Google thất bại hoặc đã bị hủy.';
      }
      throw 'Đã xảy ra lỗi khi đăng nhập bằng Google: ${e.message}';
    } catch (e) {
      print('❌ Lỗi không mong muốn: $e');
      throw 'Đã xảy ra lỗi không mong muốn: ${e.toString()}';
    }
  }

  /// Gửi email đặt lại mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return;
      }
      if (e.code == 'invalid-email') {
        throw 'Địa chỉ email không hợp lệ.';
      }
      throw 'Không thể gửi email đặt lại mật khẩu. Vui lòng thử lại.';
    }
  }

  /// Đăng xuất
  Future<void> signOut() async {
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  /// Xử lý lỗi FirebaseAuthException và trả về message dễ hiểu
  String _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Tài khoản không tồn tại.';
      case 'wrong-password':
        return 'Mật khẩu không đúng.';
      case 'email-already-in-use':
        return 'Email đã được sử dụng.';
      case 'invalid-email':
        return 'Định dạng email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu phải có ít nhất 6 ký tự.';
      case 'account-exists-with-different-credential':
        return 'Tài khoản đã tồn tại với phương thức đăng nhập khác.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';
      case 'operation-not-allowed':
        return 'Đăng nhập bằng email và mật khẩu chưa được kích hoạt.';
      default:
        return 'Lỗi xác thực: ${e.message}';
    }
  }
}
