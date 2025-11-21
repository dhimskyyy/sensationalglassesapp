import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color mint = Color(0xFF70CAB0);
  static const Color dark = Color(0xFF071836);

  bool _isPasswordHidden = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 58, 24, 36),
            color: mint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset('assets/logo.png', width: 22, height: 22),
                    const SizedBox(width: 10),
                    const Text(
                      'Sensational Glasses',
                      style: TextStyle(
                        color: Color(0xFF2A274B),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'Masuk ke Akun\nAnda',
                  style: TextStyle(
                    color: Color(0xFF2A274B),
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Belum Punya Akun?',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Get.toNamed('/register');
                      },
                      child: const Text(
                        'Daftar',
                        style: TextStyle(
                          color: Color(0xFF2A274B),
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),

                      const Text(
                        'Email',
                        style: TextStyle(color: Color(0xFF2A274B)),
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),
                      const Text(
                        'Password',
                        style: TextStyle(color: Color(0xFF2A274B)),
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        obscureText: _isPasswordHidden,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordHidden
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF2A274B),
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordHidden = !_isPasswordHidden;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Lupa Password ?',
                            style: TextStyle(color: Color(0xFF2A274B)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {}, // TODO: isi login email
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mint,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: const [
                          Expanded(
                            child: Divider(
                              thickness: 1,
                              color: Color(0xFFEEEEEE),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Atau masuk dengan',
                            style: TextStyle(color: Color(0xFF2A274B)),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Divider(
                              thickness: 1,
                              color: Color(0xFFEEEEEE),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Get.find<AuthController>().signInWithGoogle();
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Colors.grey.shade200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    "assets/google.png",
                                    width: 20,
                                    height: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Google',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Get.find<AuthController>().signInWithFacebook();
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Colors.grey.shade200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    "assets/facebook.png",
                                    width: 20,
                                    height: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Facebook',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 66),

                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            text: 'Dengan mendaftar, Anda menyetujui ',
                            style: TextStyle(color: dark, fontSize: 13),
                            children: [
                              TextSpan(
                                text: 'Persyaratan\n',
                                style: TextStyle(color: mint),
                              ),
                              TextSpan(
                                text: 'Layanan dan ',
                                style: TextStyle(color: dark),
                              ),
                              TextSpan(
                                text: 'Perjanjian Pemrosesan Data',
                                style: TextStyle(color: mint),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
