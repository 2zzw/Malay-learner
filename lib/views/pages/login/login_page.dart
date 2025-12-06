import 'package:flutter/material.dart';
import 'package:malay/views/pages/login/register_page.dart';
import '../../../service/Auth.dart';
import '../home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      // await _authService.signInWithEmail(
      //   _emailController.text,
      //   _passwordController.text,
      // );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Login Failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const RegisterPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1543857778-c4a1a3e0b2eb?q=80&w=1000&auto=format&fit=crop',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withValues(alpha: 0.3)),

          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),
                const Icon(
                  Icons.menu_book_rounded,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Malay Master",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const Text(
                  "Sehari selembar benang.",
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(flex: 2),

                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: Colors.teal,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.teal,
                        tabs: const [
                          Tab(text: "Email Login"),
                          Tab(text: "Phone Login"),
                        ],
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        height: 180,
                        child: TabBarView(
                          controller: _tabController,
                          children: [_buildEmailForm(), _buildPhoneForm()],
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "LOGIN",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Colors.grey),
                          ),
                          GestureDetector(
                            onTap: _navigateToRegister,
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        "By continuing, you agree to our Terms of Service\nand Privacy Policy.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.email_outlined),
            labelText: "Email",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline),
            labelText: "Password",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneForm() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text("+60", style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 验证码输入框 (模拟)
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.security),
            labelText: "SMS Code",
            suffixIcon: TextButton(
              onPressed: () {},
              child: const Text("Get Code"),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
        ),
      ],
    );
  }
}
