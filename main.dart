import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(MyApp());
}

class MoodEntry {
  String humor;
  String anotacao;
  final String data;

  MoodEntry(this.humor, this.anotacao, this.data);

  Map<String, dynamic> toJson() => {
    'humor': humor,
    'anotacao': anotacao,
    'data': data,
  };

  static MoodEntry fromJson(Map<String, dynamic> json) =>
      MoodEntry(json['humor'], json['anotacao'], json['data']);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moodify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF121212),
        primaryColor: Colors.cyanAccent,
        appBarTheme: AppBarTheme(backgroundColor: Color(0xFF2C2C54)),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => LoginScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Scaffold(
        body: Center(
          child: Text(
            'Moodify',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final userController = TextEditingController();
  final passController = TextEditingController();

  Future<void> _login() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('user');
    final savedPass = prefs.getString('pass');

    if (savedUser == null || savedPass == null) {
      await prefs.setString('user', userController.text);
      await prefs.setString('pass', passController.text);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else if (savedUser == userController.text &&
        savedPass == passController.text) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Usuário ou senha incorretos')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Login Moodify',
              style: TextStyle(fontSize: 28, color: Colors.cyanAccent),
            ),
            TextField(
              controller: userController,
              decoration: InputDecoration(labelText: 'Usuário'),
            ),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Senha'),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: Text('Entrar')),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _humorSelecionado = '';
  final _controller = TextEditingController();

  final List<Map<String, dynamic>> _emocoes = [
    {
      'icone': Icons.sentiment_very_satisfied,
      'label': 'Feliz',
      'color': Colors.green,
    },
    {
      'icone': Icons.sentiment_neutral,
      'label': 'Neutro',
      'color': Colors.yellow,
    },
    {
      'icone': Icons.sentiment_very_dissatisfied,
      'label': 'Triste',
      'color': Colors.red,
    },
    {'icone': Icons.mood_bad, 'label': 'Raiva', 'color': Colors.deepOrange},
    {
      'icone': Icons.sentiment_dissatisfied,
      'label': 'Ansioso',
      'color': Colors.amber,
    },
    {'icone': Icons.mood, 'label': 'Animado', 'color': Colors.lightBlue},
    {'icone': Icons.bedtime, 'label': 'Cansado', 'color': Colors.purple},
  ];

  Future<void> _salvarAnotacao() async {
    if (_humorSelecionado.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> data = prefs.getStringList('mood_entries') ?? [];

    final novaEntrada = MoodEntry(
      _humorSelecionado,
      _controller.text,
      DateTime.now().toString().split(' ')[0],
    );

    data.add(jsonEncode(novaEntrada.toJson()));
    await prefs.setStringList('mood_entries', data);

    _controller.clear();
    _humorSelecionado = '';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Anotação salva!')));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Moodify')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Como você está se sentindo hoje?',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Wrap(
              spacing: 15,
              runSpacing: 15,
              alignment: WrapAlignment.center,
              children:
                  _emocoes.map((emo) {
                    final selecionado = _humorSelecionado == emo['label'];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _humorSelecionado = emo['label']);
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              selecionado
                                  ? emo['color'].withOpacity(0.15)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selecionado ? emo['color'] : Colors.white24,
                            width: 2,
                          ),
                          boxShadow:
                              selecionado
                                  ? [
                                    BoxShadow(
                                      color: emo['color'].withOpacity(0.8),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                      offset: Offset(0, 0),
                                    ),
                                  ]
                                  : [],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              emo['icone'],
                              size: 40,
                              color:
                                  selecionado ? emo['color'] : Colors.white54,
                            ),
                            SizedBox(height: 5),
                            Text(
                              emo['label'],
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    selecionado ? emo['color'] : Colors.white54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(),
                hintText: 'Escreva sua anotação aqui',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _salvarAnotacao, child: Text('Salvar')),
            ElevatedButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HistoricoScreen()),
                  ),
              child: Text('Ver Histórico'),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoricoScreen extends StatefulWidget {
  @override
  _HistoricoScreenState createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  List<MoodEntry> entries = [];

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> data = prefs.getStringList('mood_entries') ?? [];
    setState(() {
      entries = data.map((e) => MoodEntry.fromJson(jsonDecode(e))).toList();
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> data = entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('mood_entries', data);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _editarEntrada(int index) {
    final entry = entries[index];
    final anotacaoController = TextEditingController(text: entry.anotacao);
    String humorAtual = entry.humor;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Editar Anotação'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: humorAtual,
                items:
                    [
                          'Feliz',
                          'Neutro',
                          'Triste',
                          'Raiva',
                          'Ansioso',
                          'Animado',
                          'Cansado',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      humorAtual = val;
                    });
                  }
                },
              ),
              TextField(
                controller: anotacaoController,
                maxLines: 4,
                decoration: InputDecoration(hintText: 'Editar anotação'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  entries[index].humor = humorAtual;
                  entries[index].anotacao = anotacaoController.text;
                });
                _saveData();
                Navigator.pop(context);
              },
              child: Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _excluirEntrada(int index) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Excluir entrada?'),
            content: Text('Tem certeza que quer excluir essa anotação?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    entries.removeAt(index);
                  });
                  _saveData();
                  Navigator.pop(context);
                },
                child: Text('Excluir'),
              ),
            ],
          ),
    );
  }

  Map<String, int> _contarHumores() {
    final Map<String, int> counts = {};
    for (var e in entries) {
      counts[e.humor] = (counts[e.humor] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _contarHumores();

    return Scaffold(
      appBar: AppBar(title: Text('Histórico')),
      body: Column(
        children: [
          Expanded(
            child:
                entries.isEmpty
                    ? Center(child: Text('Nenhuma anotação salva'))
                    : ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (_, i) {
                        final e = entries[i];
                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(
                              '${e.humor} - ${e.data}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(e.anotacao),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: Colors.cyanAccent,
                                  ),
                                  onPressed: () => _editarEntrada(i),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _excluirEntrada(i),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
          SizedBox(
            height: 250,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      (counts.values.isEmpty)
                          ? 1
                          : (counts.values.reduce((a, b) => a > b ? a : b) + 1)
                              .toDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const moods = [
                            'Feliz',
                            'Neutro',
                            'Triste',
                            'Raiva',
                            'Ansioso',
                            'Animado',
                            'Cansado',
                          ];
                          if (value.toInt() < 0 ||
                              value.toInt() >= moods.length)
                            return Container();
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              moods[value.toInt()],
                              style: TextStyle(fontSize: 10),
                            ),
                          );
                        },
                        interval: 1,
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    final moods = [
                      'Feliz',
                      'Neutro',
                      'Triste',
                      'Raiva',
                      'Ansioso',
                      'Animado',
                      'Cansado',
                    ];
                    final mood = moods[index];
                    final count = counts[mood] ?? 0;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: Colors.cyanAccent,
                          width: 20,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
