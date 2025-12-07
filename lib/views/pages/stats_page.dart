import 'dart:ui';
import 'package:flutter/material.dart';

class StudyStats {
  final int todayWords;
  final int totalWords;
  final int todayMinutes;
  final int totalMinutes;
  final int streakDays;
  final List<bool> weekStreak; // true = signed in

  StudyStats({
    required this.todayWords,
    required this.totalWords,
    required this.todayMinutes,
    required this.totalMinutes,
    required this.streakDays,
    required this.weekStreak,
  });
}

final mockStats = StudyStats(
  todayWords: 5,
  totalWords: 42,
  todayMinutes: 8,
  totalMinutes: 36,
  streakDays: 2,
  weekStreak: [true, true, false, false, false, false, false], // Mon-Sun status
);

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Dashboard",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1543857778-c4a1a3e0b2eb?q=80&w=1000&auto=format&fit=crop',
            fit: BoxFit.cover,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.white.withValues(alpha: 0.6)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      "Currently Learning",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  _buildCurrentLearningCard(),

                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      "My Statistics", // My Statistics
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  _buildOverviewCard(),

                  const SizedBox(height: 16),

                  _buildCalendarCard(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildCurrentLearningCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.teal,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(2, 4),
                    ),
                  ],
                  image: const DecorationImage(
                    image: NetworkImage(
                      "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Claude_Monet_-_Woman_with_a_Parasol_-_Madame_Monet_and_Her_Son_-_National_Gallery_of_Art.jpg/1200px-Claude_Monet_-_Woman_with_a_Parasol_-_Madame_Monet_and_Her_Son_-_National_Gallery_of_Art.jpg",
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  alignment: Alignment.center,
                  color: Colors.black26,
                  child: const Text(
                    "Malay\nBasic",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Malay Basic",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_box_outlined,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Vocabulary Book",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Progress",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Text(
                "All Units >",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 5 / 100, // 5% progress
              backgroundColor: Colors.grey.shade200,
              color: Colors.orange,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Learned 5 items",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              Text(
                "Total 100 items",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Overview",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.menu_book,
                  iconColor: Colors.orange,
                  label: "Today's Words",
                  value: "${mockStats.todayWords}",
                  unit: "words",
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.trending_up,
                  iconColor: Colors.redAccent,
                  label: "Total Learned",
                  value: "${mockStats.totalWords}",
                  unit: "words",
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.access_time_filled,
                  iconColor: Colors.amber,
                  label: "Today's Time",
                  value: "${mockStats.todayMinutes}",
                  unit: "min",
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.history,
                  iconColor: Colors.red.shade300,
                  label: "Total Time",
                  value: "${mockStats.totalMinutes}",
                  unit: "min",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'San Francisco',
                ),
              ),
              const TextSpan(text: " "),
              TextSpan(
                text: unit,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarCard() {
    const weekDays = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Calendar",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text(
                    "Streak ${mockStats.streakDays} days ",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isToday = index == 2;
              final isChecked = index < 2;

              return Column(
                children: [
                  Text(
                    weekDays[index],
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isChecked
                          ? Colors.orange
                          : (isToday ? Colors.transparent : Colors.transparent),
                      shape: BoxShape.circle,
                      border: isChecked
                          ? null
                          : Border.all(color: Colors.grey.shade200),
                    ),
                    child: Center(
                      child: isChecked
                          ? const Text(
                              "1",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ) // 模拟日期号
                          : (isToday
                                ? const Text(
                                    "Now",
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  )
                                : Text(
                                    "${index + 2}",
                                    style: TextStyle(color: Colors.black54),
                                  )),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.9), // 接近纯白，但保留一点点透光
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
