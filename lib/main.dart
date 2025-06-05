import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MoodEntry {
  final String humor;
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
      home: LoginScreen(),
    );
  }
}
class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );

    _opacityAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 50),  // Fade-in
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 50),  // Fade-out
    ]).animate(_controller);

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Center(
        child: FadeTransition(
          opacity: _opacityAnim,
          child: Text(
            'Moodfy',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
              fontFamily: 'Roboto', // ou outra fonte que usar
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
          context, MaterialPageRoute(builder: (_) => HomeScreen()));
    } else if (savedUser == userController.text &&
        savedPass == passController.text) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuário ou senha incorretos')));
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
            Text('Login Moodify',
                style: TextStyle(fontSize: 28, color: Colors.cyanAccent)),
            TextField(
                controller: userController,
                decoration: InputDecoration(labelText: 'Usuário')),
            TextField(
                controller: passController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Senha')),
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
      'color': Colors.green
    },
    {'icone': Icons.sentiment_neutral, 'label': 'Neutro', 'color': Colors.yellow},
    {
      'icone': Icons.sentiment_very_dissatisfied,
      'label': 'Triste',
      'color': Colors.red
    },
    {'icone': Icons.mood_bad, 'label': 'Raiva', 'color': Colors.deepOrange},
    {'icone': Icons.sentiment_dissatisfied, 'label': 'Ansioso', 'color': Colors.amber},
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

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Anotação salva!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Moodify')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Como você está se sentindo hoje?',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Wrap(
              spacing: 15,
              runSpacing: 15,
              alignment: WrapAlignment.center,
              children: _emocoes.map((emo) {
                final selecionado = _humorSelecionado == emo['label'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _humorSelecionado = emo['label']);
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selecionado
                          ? emo['color'].withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selecionado ? emo['color'] : Colors.white24,
                        width: 2,
                      ),
                      boxShadow: selecionado
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
                          color: selecionado ? emo['color'] : Colors.white54,
                        ),
                        SizedBox(height: 5),
                        Text(
                          emo['label'],
                          style: TextStyle(
                            fontSize: 12,
                            color: selecionado
                                ? emo['color']
                                : Colors.white54,
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
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => HistoricoScreen())),
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
    List<String> jsonData =
        entries.map((entry) => jsonEncode(entry.toJson())).toList();
    await prefs.setStringList('mood_entries', jsonData);
  }

  void _editarNota(int index) async {
    TextEditingController editController =
        TextEditingController(text: entries[index].anotacao);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editar anotação'),
        content: TextField(
          controller: editController,
          maxLines: 5,
          decoration: InputDecoration(
              hintText: 'Edite sua anotação', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
          TextButton(
              onPressed: () {
                setState(() {
                  entries[index].anotacao = editController.text;
                });
                _saveData();
                Navigator.pop(context);
              },
              child: Text('Salvar')),
        ],
      ),
    );
  }

  void _excluirNota(int index) {
    setState(() {
      entries.removeAt(index);
    });
    _saveData();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Histórico')),
      body: entries.isEmpty
          ? Center(child: Text('Sem anotações salvas'))
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, i) {
                return Card(
                  color: Colors.white10,
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(entries[i].anotacao),
                    subtitle:
                        Text('Data: ${entries[i].data} • Humor: ${entries[i].humor}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            onPressed: () => _editarNota(i),
                            icon: Icon(Icons.edit, color: Colors.cyanAccent)),
                        IconButton(
                            onPressed: () => _excluirNota(i),
                            icon: Icon(Icons.delete, color: Colors.redAccent)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
