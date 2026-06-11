
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await Hive.initFlutter();
  await Hive.openBox('criticalBox');

  runApp(const SmartHealthApp());
}



class SmartHealthApp extends StatelessWidget {
  const SmartHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Health Edge',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
      ),
      home: const LoginScreen(),
    );
  }
}

class UserProfile {
  final String uid;
  final String email;
  final String role;
  final String name;
  final String patientId;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
    required this.patientId,
  });

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'patient',
      name: data['name'] ?? 'Khushi',
      patientId: data['patientId'] ?? 'P101',
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController(text: 'khushi@test.com');
  final passwordController = TextEditingController(text: 'khushi#123');
  final nameController = TextEditingController(text: 'Khushi');
  final patientIdController = TextEditingController(text: 'P101');

  bool isLogin = true;
  String selectedRole = 'patient';
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    patientIdController.dispose();
    super.dispose();
  }

  Future<void> authenticate() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _showSnack('Email and password required');
      return;
    }

    if (!isLogin && nameController.text.trim().isEmpty) {
      _showSnack('Name required');
      return;
    }

    setState(() => loading = true);

    try {
      UserCredential cred;

      if (isLogin) {
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
          'email': emailController.text.trim(),
          'role': selectedRole,
          'name': nameController.text.trim(),
          'patientId':
              selectedRole == 'patient' ? patientIdController.text.trim() : '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .get();

      if (!doc.exists) {
        throw Exception('User profile not found in Firestore');
      }

      final profile = UserProfile.fromDoc(doc);

      if (!mounted) return;

      if (profile.role == 'doctor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorDashboard(profile: profile),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PatientDashboard(profile: profile),
          ),
        );
      }
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gradient = LinearGradient(
      colors: [Color(0xFF6C63FF), Color(0xFF3AA0FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 86,
                      width: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5F8F), Color(0xFFFF8C42)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Smart Health Edge',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2440),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLogin
                          ? 'Login to continue'
                          : 'Create patient or doctor account',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!isLogin) ...[
                      _prettyField(
                        controller: nameController,
                        label: 'Name',
                        icon: Icons.person_rounded,
                      ),
                      const SizedBox(height: 14),
                    ],
                    _prettyField(
                      controller: emailController,
                      label: 'Email',
                      icon: Icons.email_rounded,
                    ),
                    const SizedBox(height: 14),
                    _prettyField(
                      controller: passwordController,
                      label: 'Password',
                      icon: Icons.lock_rounded,
                      obscure: true,
                    ),
                    if (!isLogin) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F7FB),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE4E7F2)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedRole,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'patient',
                                child: Text('PATIENT'),
                              ),
                              DropdownMenuItem(
                                value: 'doctor',
                                child: Text('DOCTOR'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => selectedRole = value!);
                            },
                          ),
                        ),
                      ),
                      if (selectedRole == 'patient') ...[
                        const SizedBox(height: 14),
                        _prettyField(
                          controller: patientIdController,
                          label: 'Patient ID',
                          icon: Icons.badge_rounded,
                        ),
                      ],
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : authenticate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          loading ? 'Please wait...' : (isLogin ? 'Login' : 'Signup'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: loading
                          ? null
                          : () {
                              setState(() => isLogin = !isLogin);
                            },
                      child: Text(
                        isLogin ? 'Create new account' : 'Already have account',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _prettyField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF6F7FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE4E7F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE4E7F2)),
        ),
      ),
    );
  }
}

class PatientDashboard extends StatefulWidget {
  final UserProfile profile;
  const PatientDashboard({super.key, required this.profile});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  Interpreter? interpreter;
  bool modelLoaded = false;
  bool busy = true;
  final Box criticalBox = Hive.box('criticalBox');


  List<double> ecg = [];
  int heartRate = 0;
  int spo2 = 0;
  double temperature = 0;
  int respiratoryRate = 0;
  int stressLevel = 0;
  String ecgStatus = 'Loading';
  String prediction = 'Loading';
  String modelSource = 'TFLite';
  String lastUpdated = '--:--';

  Timer? timer;
  bool lastWasCritical = false;
  DateTime? lastCriticalUploadTime;

  @override
void initState() {
  super.initState();
  _loadModelAndStart();
}


  @override
  void dispose() {
    timer?.cancel();
    interpreter?.close();
    super.dispose();
  }

  Future<void> _loadModelAndStart() async {
    await _loadModel();
    await _refreshReading();
    timer = Timer.periodic(const Duration(seconds: 6), (_) async {
      await _refreshReading();
    });
  }

  Future<void> _loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset('assets/model.tflite');
      modelLoaded = true;
    } catch (_) {
      modelLoaded = false;
      modelSource = 'Fallback';
    }
    if (mounted) setState(() {});
  }

  Future<void> _refreshReading() async {
    setState(() => busy = true);

    final generated = _generateSyntheticPacket();
    final syntheticEcg = generated['ecg'] as List<double>;
    final vitals = generated['vitals'] as Map<String, dynamic>;

    String pred;
    if (modelLoaded && interpreter != null) {
      try {
        pred = _runTflitePrediction(syntheticEcg);
      } catch (_) {
        pred = _fallbackPrediction(vitals['heartRate'] as int);
        modelSource = 'Fallback';
      }
    } else {
      pred = _fallbackPrediction(vitals['heartRate'] as int);
    }

    final status = _deriveEcgStatus(pred, vitals['heartRate'] as int);

   


    setState(() {
      ecg = syntheticEcg;
      heartRate = vitals['heartRate'] as int;
      spo2 = vitals['spo2'] as int;
      temperature = vitals['temperature'] as double;
      respiratoryRate = vitals['respiratoryRate'] as int;
      stressLevel = vitals['stress'] as int;
      prediction = pred;
      ecgStatus = status;
      lastUpdated = _formatNow();
      busy = false;
    });

    await _maybeUploadCriticalAlert();
    await _saveCriticalLocally();
    

  }

  Map<String, dynamic> _generateSyntheticPacket() {
    final rand = Random();
    final baseHr = 65 + rand.nextInt(45);
    final currentTemp = 97.2 + rand.nextDouble() * 3.2;
    final currentSpo2 = 93 + rand.nextInt(7);
    final currentResp = 12 + rand.nextInt(10);
    final stress = 20 + rand.nextInt(75);

    final points = <double>[];
    final peakCenter = 35 + rand.nextInt(60);

    for (int i = 0; i < 187; i++) {
      double v = 0.06 * sin(i / 6.0) + (rand.nextDouble() - 0.5) * 0.05;

      final dist = (i - peakCenter).abs();
      if (dist < 2) {
        v += 1.2;
      } else if (dist < 4) {
        v += 0.5;
      } else if ((i - (peakCenter - 12)).abs() < 3) {
        v += 0.12;
      } else if ((i - (peakCenter + 14)).abs() < 4) {
        v += 0.20;
      }

      points.add(v.clamp(-1.0, 1.5));
    }

    return {
      'ecg': points,
      'vitals': {
        'heartRate': baseHr,
        'spo2': currentSpo2,
        'temperature': double.parse(currentTemp.toStringAsFixed(1)),
        'respiratoryRate': currentResp,
        'stress': stress,
      },
    };
  }

  String _runTflitePrediction(List<double> input) {
    if (interpreter == null) return _fallbackPrediction(heartRate);

    final inputShape = interpreter!.getInputTensor(0).shape;
    dynamic inputTensor;

    if (inputShape.length == 2) {
      inputTensor = [input];
    } else if (inputShape.length == 3) {
      inputTensor = [
        input.map((e) => [e]).toList(),
      ];
    } else {
      throw Exception('Unsupported input shape: $inputShape');
    }

    final outputShape = interpreter!.getOutputTensor(0).shape;

    if (outputShape.length != 2 || outputShape[0] != 1) {
      throw Exception('Unsupported output shape: $outputShape');
    }

    final output = List.generate(
      outputShape[0],
      (_) => List.filled(outputShape[1], 0.0),
    );

    interpreter!.run(inputTensor, output);

    final scores = List<double>.from(output[0]);

    int maxIndex = 0;
    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > scores[maxIndex]) {
        maxIndex = i;
      }
    }

    if (maxIndex == 0) return 'Warning';
    if (maxIndex == 1) return 'Normal';
    return 'Critical';
  }

  String _fallbackPrediction(int hr) {
    if (hr > 100) return 'Critical';
    if (hr < 65) return 'Warning';
    return 'Normal';
  }

  String _deriveEcgStatus(String pred, int hr) {
    if (pred == 'Critical') return 'Irregular Rhythm';
    if (pred == 'Warning') return hr < 65 ? 'Low Variability' : 'Mild Deviation';
    return 'Stable';
  }

   Future<void> _saveCriticalLocally() async {
  if (prediction != 'Critical') return;

  final List criticalHistory =
      criticalBox.get('criticalHistory', defaultValue: <Map<String, dynamic>>[]);

  criticalHistory.insert(0, {
    'patientUid': widget.profile.uid,
    'patientName': widget.profile.name,
    'patientId': widget.profile.patientId,
    'heartRate': heartRate,
    'spo2': spo2,
    'temperature': temperature,
    'respiratoryRate': respiratoryRate,
    'stressLevel': stressLevel,
    'ecgStatus': ecgStatus,
    'prediction': prediction,
    'savedAt': DateTime.now().toIso8601String(),
  });

  criticalBox.put('criticalHistory', criticalHistory);
}


 Future<void> _maybeUploadCriticalAlert() async {
    final isCritical = prediction == 'Critical';

    if (!isCritical) {
      lastWasCritical = false;
      return;
    }

    final now = DateTime.now();
    final shouldUpload = !lastWasCritical ||
        lastCriticalUploadTime == null ||
        now.difference(lastCriticalUploadTime!).inSeconds > 25;

    if (!shouldUpload) return;

    await FirebaseFirestore.instance.collection('critical_alerts').add({
      'patientUid': widget.profile.uid,
      'patientName': widget.profile.name,
      'patientId': widget.profile.patientId,
      'heartRate': heartRate,
      'spo2': spo2,
      'temperature': temperature,
      'respiratoryRate': respiratoryRate,
      'stressLevel': stressLevel,
      'ecgStatus': ecgStatus,
      'prediction': prediction,
      'createdAt': FieldValue.serverTimestamp(),
    });

    lastWasCritical = true;
    lastCriticalUploadTime = now;
  }

  String _formatNow() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Color _predictionColor(String value) {
    if (value == 'Critical') return const Color(0xFFE74C3C);
    if (value == 'Warning') return const Color(0xFFF39C12);
    return const Color(0xFF2ECC71);
  }

  @override
  Widget build(BuildContext context) {
    final predColor = _predictionColor(prediction);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
        actions: [
          IconButton(
            onPressed: _refreshReading,
            icon: const Icon(Icons.refresh_rounded),
          )
        ],
      ),
      body: busy && ecg.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerCard(predColor),
                  const SizedBox(height: 18),
                  _waveCard(),
                  const SizedBox(height: 18),
                  const Text(
                    'Live Health Overview',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          title: 'Heart Rate',
                          value: '$heartRate BPM',
                          icon: Icons.favorite_rounded,
                          color: Colors.red,
                          subtitle: ecgStatus,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metricCard(
                          title: 'Prediction',
                          value: prediction,
                          icon: Icons.analytics_rounded,
                          color: predColor,
                          subtitle: 'Model output',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          title: 'SpO₂',
                          value: '$spo2%',
                          icon: Icons.air_rounded,
                          color: Colors.blue,
                          subtitle: 'Oxygen saturation',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metricCard(
                          title: 'Temp',
                          value: '${temperature.toStringAsFixed(1)} °F',
                          icon: Icons.thermostat_rounded,
                          color: Colors.orange,
                          subtitle: 'Body temperature',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          title: 'Resp. Rate',
                          value: '$respiratoryRate rpm',
                          icon: Icons.monitor_heart_outlined,
                          color: Colors.teal,
                          subtitle: 'Breaths per minute',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metricCard(
                          title: 'Stress',
                          value: '$stressLevel%',
                          icon: Icons.psychology_rounded,
                          color: Colors.purple,
                          subtitle: modelLoaded ? modelSource : 'Fallback active',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: predColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: predColor.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shield_rounded, color: predColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            prediction == 'Critical'
                                ? 'Critical condition detected. Cloud alert has been triggered for doctor view.'
                                : prediction == 'Warning'
                                    ? 'Observation needed. Patient should remain under monitoring.'
                                    : 'All major vitals are within acceptable range.',
                            style: const TextStyle(fontSize: 14),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _refreshReading,
                      icon: const Icon(Icons.bolt_rounded),
                      label: const Text('Generate New Reading'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),

                
                  const SizedBox(height: 18),
_criticalHistoryCard(),


                ],
              ),
            ),
    );
  }

  Widget _headerCard(Color predColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF3AA0FF)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${widget.profile.name} 👋',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Patient ID: ${widget.profile.patientId}',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Edge-Based Health Monitoring',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  prediction,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Updated $lastUpdated',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _waveCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ECG Signal Snapshot',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Source: ${modelLoaded ? 'TFLite model active' : 'Fallback mode'}',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: ECGPainter(ecg),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 16,
            offset: const Offset(0, 7),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.13),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF20263F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Colors.black45),
          )
        ],
      ),
    );
  }
  Widget _criticalHistoryCard() {
  final List criticalHistory =
      criticalBox.get('criticalHistory', defaultValue: []);

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Critical Alerts (Local)',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        if (criticalHistory.isEmpty)
          const Text("No critical alerts yet")
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: criticalHistory.length,
            itemBuilder: (context, index) {
              final item = criticalHistory[index];
              return Text(
                'HR ${item['heartRate']} • ${item['prediction']}',
              );
            },
          ),
      ],
    ),
  );
}

}

class DoctorDashboard extends StatelessWidget {
  final UserProfile profile;
  const DoctorDashboard({super.key, required this.profile});

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return 'Time pending';
    if (ts is! Timestamp) return 'Time unavailable';
    final dt = ts.toDate();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year}  $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF14B8A6), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Dr. ${profile.name}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Critical Patient Alerts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Only high-risk patients are shown here from cloud alerts.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('critical_alerts')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No critical patients right now',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.red.withOpacity(0.12),
                              child: const Icon(
                                Icons.warning_rounded,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['patientName'] ?? 'Unknown Patient',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Patient ID: ${data['patientId'] ?? '--'}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _chip('HR ${data['heartRate'] ?? '--'} BPM'),
                                      _chip('SpO₂ ${data['spo2'] ?? '--'}%'),
                                      _chip('Temp ${data['temperature'] ?? '--'} °F'),
                                      _chip('RR ${data['respiratoryRate'] ?? '--'}'),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'ECG: ${data['ecgStatus'] ?? '--'}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Prediction: ${data['prediction'] ?? 'Critical'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatTimestamp(data['createdAt']),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FB),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class ECGPainter extends CustomPainter {
  final List<double> points;
  ECGPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = const Color(0xFFF7F9FD)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(16),
      ),
      bgPaint,
    );

    final gridPaint = Paint()
      ..color = const Color(0xFFE8ECF7)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) return;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final normalized = points[i];
      final y = size.height / 2 - (normalized * 36);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final wavePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFF8B5CF6), Color(0xFF3B82F6)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant ECGPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}


