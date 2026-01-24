import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:malay/data/theme_provider.dart';
import 'package:malay/views/pages/login/login_page.dart';
import 'package:malay/views/pages/profile/appearance_page.dart';
import 'package:malay/views/pages/profile/favorites_page.dart';
import 'package:provider/provider.dart';
import 'package:malay/views/widgets/theme_widget.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final bgUrl = context.watch<ThemeProvider>().currentBackgroundUrl;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline_rounded, color: Colors.black87),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 背景层
          UniversalBackgroundImage(imageUrl: bgUrl, fit: BoxFit.cover),
          // 叠加层：使背景变淡，让前台内容清晰
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.white.withValues(alpha: 0.85)),
          ),

          // 2. 内容层
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // --- 头像区域 ---
                  _buildProfileHeader(),
                  const SizedBox(height: 32),

                  // --- 统计双卡片区域 (酷币 & 装备) ---
                  Row(
                    children: [
                      Expanded(child: _buildCoinCard()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildEquipmentCard()),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // --- 设置列表区域 ---
                  _buildSettingsList(context),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. 头像与名称组件
  Widget _buildProfileHeader() {
    return Column(
      children: [
        // 头像
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.pink.shade50,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.transparent,
            backgroundImage: NetworkImage(
              'https://api.dicebear.com/9.x/notionists/png?seed=Alex',
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Litchy",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stars_rounded, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                "Not VIP Member >",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. 酷币卡片
  Widget _buildCoinCard() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Coins",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              const Text(
                "3,027",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'San Francisco',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. 装备卡片
  Widget _buildEquipmentCard() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Items",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text("1/8 >", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const Spacer(),
          // 装备小图标行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallIcon(Icons.book, Colors.purple),
              _buildSmallIcon(Icons.map, Colors.grey),
              _buildSmallIcon(Icons.workspace_premium, Colors.grey),
              _buildSmallIcon(Icons.shield, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  // 4. 设置列表
  Widget _buildSettingsList(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildListItem(
            icon: Icons.palette_outlined,
            color: Colors.teal,
            title: "Appearance", // 外观修改
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppearancePage()),
              );
            },
          ),
          _buildDivider(),
          _buildListItem(
            icon: Icons.tune,
            color: Colors.purpleAccent,
            title: "My Words", // 学习设置
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesPage()),
              );
            },
          ),
          _buildDivider(),
          _buildListItem(
            icon: Icons.language,
            color: Colors.blue,
            title: "Language", // 语言设置
            onTap: () {},
          ),
          SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                "LOG OUT",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 64,
      endIndent: 20,
      color: Colors.black12,
    );
  }

  // 通用卡片样式：纯白毛玻璃，圆角
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white, // 设置为纯白，不透明
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
