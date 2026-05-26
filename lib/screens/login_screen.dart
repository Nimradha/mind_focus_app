import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'main_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers to "grab" the text the user types
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              const SizedBox(height: 60),

              const SizedBox(height: 30),
              // 2. Hero Image (Make sure path matches your assets)
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.asset('assets/images/logo.png', height: 200),
              ),

              const SizedBox(height: 30),
              // 3. Welcome Text
              Text(
                  "Boost your brain today!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  )),
              const Text("Train your memory and focus with daily challenges.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16)),

              const SizedBox(height: 30),
              // 4. Input Fields
              _buildTextField("Enter your Email", _emailController, false),
              const SizedBox(height: 15),
              _buildTextField("Enter your Password", _passwordController, true),

              const SizedBox(height: 30),
              // 5. Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleSignUp(), // Backend call
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Create Account", style: TextStyle(color: Colors.black54, fontSize: 18)),
                ),
              ),
              TextButton(
                  onPressed: () => _handleLogin(),
                  child: const Text("Login", style: TextStyle(color: Colors.green))
              ),

              const SizedBox(height: 20),
              const Text("Or continue with", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),

              // 6. Social Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialButton('assets/images/google.png', _handleGoogleSignIn),
                  const SizedBox(width: 20),
                  _socialButton('assets/images/fb1.png', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Facebook Sign-In is not configured yet.")),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper UI methods to keep code clean
  Widget _buildTextField(String hint, TextEditingController controller, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.blueGrey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _socialButton(String assetPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Image.asset(
              assetPath,
              height: 30),
        ),
      ),
    );
  }

  // --- PHASE 4: THE BACKEND ---
  void _handleSignUp() async{
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // 2. Simple Validation
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    try {
      // 3. The Firebase Call
      debugPrint("Attempting to register: $email");

      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // 4. If successful
      debugPrint("User registered: ${userCredential.user?.uid}");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text("Account Created Successfully!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWrapper()),
        );

      }

    } on FirebaseAuthException catch (e) {
      // 5. Handle specific Firebase errors
      String message = "An error occurred";
      if (e.code == 'weak-password') {
        message = "The password provided is too weak.";
      } else if (e.code == 'email-already-in-use') {
        message = "An account already exists for that email.";
      } else if (e.code == 'invalid-email') {
        message = "The email address is not valid.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(message)),
      );
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text("An unexpected error occurred: $e")),
        );
      }
    }
  }

  void _handleLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields to login")),
      );
      return;
    }

    try {
      debugPrint("Attempting login: $email");

      // DIFFERENT METHOD: Use signIn instead of createUser
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.greenAccent,
            content: Text(
                "Welcome Back!",
                 style: TextStyle(
                   color: Colors.black,
                 )

            )
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainWrapper()),
      );

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = "Login failed";
      // Specific login errors
      if (e.code == 'user-not-found') {
        message = "No account found for this email.";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect password.";
      } else if (e.code == 'invalid-credential') {
        message = "Invalid login details. Please try again.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.orange, content: Text(message)),
      );
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text("An unexpected error occurred: $e")),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      debugPrint("Attempting Google Sign-In...");
      
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        debugPrint("Google Sign-In canceled by user.");
        return; // User canceled sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (!mounted) return;

      debugPrint("Google login successful: ${userCredential.user?.uid}");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.greenAccent,
          content: Text(
            "Welcome Back!",
            style: TextStyle(color: Colors.black),
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainWrapper()),
      );
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange,
            content: Text("Google login failed: $e"),
          ),
        );
      }
    }
  }
}