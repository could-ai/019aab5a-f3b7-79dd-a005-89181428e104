import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const WoodCutterGameApp());
}

class WoodCutterGameApp extends StatelessWidget {
  const WoodCutterGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Idle Lumberjack Tycoon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFF8D6E63),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const GameScreen(),
      },
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // --- Game State ---
  double _wood = 0;
  double _coins = 0;
  int _axeLevel = 1;
  int _autoChopLevel = 0;
  
  // --- Configuration ---
  double get _clickPower => _axeLevel * 1.0;
  double get _autoChopPower => _autoChopLevel * 0.5;
  int get _upgradeCost => (_axeLevel * 50);
  int get _autoChopCost => ((_autoChopLevel + 1) * 100);
  
  // --- Animations ---
  late AnimationController _treeAnimController;
  late Animation<double> _treeScaleAnim;
  Timer? _autoChopTimer;

  @override
  void initState() {
    super.initState();
    
    // Tree hit animation
    _treeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _treeScaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _treeAnimController, curve: Curves.easeInOut),
    );

    // Auto Chop Loop
    _autoChopTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_autoChopLevel > 0) {
        _addWood(_autoChopPower);
      }
    });
  }

  @override
  void dispose() {
    _treeAnimController.dispose();
    _autoChopTimer?.cancel();
    super.dispose();
  }

  void _chopTree() {
    _treeAnimController.forward().then((_) => _treeAnimController.reverse());
    _addWood(_clickPower);
    _showFloatingText("+${_clickPower.toStringAsFixed(0)}", Colors.white);
  }

  void _addWood(double amount) {
    setState(() {
      _wood += amount;
    });
  }

  void _sellWood() {
    if (_wood < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تحتاج إلى 10 أخشاب على الأقل للبيع!")),
      );
      return;
    }
    
    setState(() {
      double woodToSell = _wood;
      double coinsEarned = woodToSell * 2; // 1 Wood = 2 Coins
      _wood = 0;
      _coins += coinsEarned;
      _showFloatingText("+${coinsEarned.toStringAsFixed(0)} عملة", Colors.amber);
    });
  }

  void _upgradeAxe() {
    if (_coins >= _upgradeCost) {
      setState(() {
        _coins -= _upgradeCost;
        _axeLevel++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم ترقية الفأس بنجاح!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("لا يوجد لديك عملات كافية!")),
      );
    }
  }

  void _upgradeAutoChop() {
    if (_coins >= _autoChopCost) {
      setState(() {
        _coins -= _autoChopCost;
        _autoChopLevel++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("لا يوجد لديك عملات كافية!")),
      );
    }
  }

  // Mock AdMob Function
  void _showAd() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("إعلان AdMob (تجريبي)"),
        content: const Text("تخيل أنك تشاهد إعلان فيديو الآن..."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _coins += 500; // Reward
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("مكافأة الإعلان: +500 عملة!")),
              );
            },
            child: const Text("إغلاق والحصول على المكافأة"),
          ),
        ],
      ),
    );
  }

  // Mock Lucky Wheel
  void _openLuckyWheel() {
    showDialog(
      context: context,
      builder: (context) => const LuckyWheelDialog(),
    ).then((value) {
      if (value != null && value is int) {
        setState(() {
          _coins += value;
        });
        _showFloatingText("+$value عملة!", Colors.purpleAccent);
      }
    });
  }

  // Helper for floating text effect (Simplified for this demo)
  void _showFloatingText(String text, Color color) {
    // In a full game, this would spawn a widget at tap position.
    // For this single-file demo, we rely on UI updates.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- Top Bar (Stats) ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.brown[900],
                boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatChip(Icons.forest, _wood.floor().toString(), Colors.green),
                  _buildStatChip(Icons.monetization_on, _coins.floor().toString(), Colors.amber),
                ],
              ),
            ),

            // --- Main Game Area (Tree) ---
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background Elements
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 100,
                      color: Colors.green[800],
                    ),
                  ),
                  
                  // The Tree
                  GestureDetector(
                    onTap: _chopTree,
                    child: ScaleTransition(
                      scale: _treeScaleAnim,
                      child: Container(
                        width: 200,
                        height: 300,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            // Using a Flutter Icon as a placeholder for the tree asset
                            // In a real app, use: image: AssetImage('assets/tree.png')
                            fit: BoxFit.contain,
                            image: NetworkImage('https://cdn-icons-png.flaticon.com/512/490/490091.png'), 
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Text(
                              "اضغط للقطع!",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.bold,
                                shadows: const [Shadow(blurRadius: 2, color: Colors.black)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Particles/Effects could go here
                ],
              ),
            ),

            // --- Controls & Upgrades ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        "بيع الخشب", 
                        Icons.sell, 
                        Colors.orange, 
                        _sellWood
                      ),
                      _buildActionButton(
                        "عجلة الحظ", 
                        Icons.casino, 
                        Colors.purple, 
                        _openLuckyWheel
                      ),
                      _buildActionButton(
                        "شاهد إعلان", 
                        Icons.ondemand_video, 
                        Colors.blue, 
                        _showAd
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    "المتجر والترقيات",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  
                  // Upgrade List
                  _buildUpgradeTile(
                    "تطوير الفأس (مستوى $_axeLevel)",
                    "قوة القطع: $_clickPower",
                    _upgradeCost,
                    Icons.handyman,
                    _upgradeAxe,
                  ),
                  _buildUpgradeTile(
                    "قاطع آلي (مستوى $_autoChopLevel)",
                    "قطع تلقائي: $_autoChopPower/ثانية",
                    _autoChopCost,
                    Icons.precision_manufacturing,
                    _upgradeAutoChop,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildUpgradeTile(String title, String subtitle, int cost, IconData icon, VoidCallback onTap) {
    bool canAfford = _coins >= cost;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.brown[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.brown),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(
          onPressed: canAfford ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canAfford ? Colors.green : Colors.grey,
            foregroundColor: Colors.white,
          ),
          child: Text("$cost 💰"),
        ),
      ),
    );
  }
}

// --- Lucky Wheel Widget ---
class LuckyWheelDialog extends StatefulWidget {
  const LuckyWheelDialog({super.key});

  @override
  State<LuckyWheelDialog> createState() => _LuckyWheelDialogState();
}

class _LuckyWheelDialogState extends State<LuckyWheelDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final Random _random = Random();
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCirc);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning) return;
    
    setState(() => _isSpinning = true);
    
    // Random rotation (5 to 10 full spins + random offset)
    double targetRotation = (5 + _random.nextDouble() * 5);
    
    _controller.reset();
    _controller.animateTo(targetRotation).then((_) {
      // Calculate reward based on random logic
      int reward = (_random.nextInt(5) + 1) * 100; // 100, 200, ... 500
      Navigator.pop(context, reward);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Center(child: Text("عجلة الحظ")),
      content: SizedBox(
        height: 250,
        width: 250,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: RotationTransition(
                turns: _animation,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [Colors.red, Colors.yellow, Colors.blue, Colors.green, Colors.red],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.star, size: 50, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.arrow_upward, size: 30, color: Colors.black),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: _isSpinning ? null : _spin,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Text(_isSpinning ? "جاري الدوران..." : "أدر العجلة!"),
        ),
      ],
    );
  }
}
