import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('users');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daftar KTP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedOccupation;
  String? _selectedEducation;
  String? _selectedProvinceId;

  @override
  void dispose() {
    _nameController.dispose();
    _birthPlaceController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final user = {
        'name': _nameController.text,
        'birthPlace': _birthPlaceController.text,
        'province': _selectedProvince,
        'district': _selectedDistrict,
        'occupation': _selectedOccupation,
        'education': _selectedEducation,
      };
      final usersBox = Hive.box('users');
      usersBox.add(user);
      _nameController.clear();
      _birthPlaceController.clear();
      setState(() {});
    }
  }

  void _deleteUser(int index) {
    final usersBox = Hive.box('users');
    usersBox.deleteAt(index);
    setState(() {});
  }

  void _editUser(int index) {
    final usersBox = Hive.box('users');
    final user = usersBox.getAt(index) as Map<String, dynamic>;
    _nameController.text = user['name'];
    _birthPlaceController.text = user['birthPlace'];
    _selectedProvince = user['province'];
    _selectedDistrict = user['district'];
    _selectedOccupation = user['occupation'];
    _selectedEducation = user['education'];
    usersBox.deleteAt(index);
    setState(() {});
  }

  Future<List<Map<String, dynamic>>> fetchProvinces() async {
    final response = await rootBundle.loadString('provinces.json');
    final List<dynamic> data = jsonDecode(response);
    return data
        .map<Map<String, dynamic>>((item) => {
              'name': item['name'],
              'id': item['id'], // Assume your province JSON has an 'id' field
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchRegencies() async {
    final response = await rootBundle.loadString('regencies.json');
    final List<dynamic> data = jsonDecode(response);
    return data
        .map<Map<String, dynamic>>((item) => {
              'name': item['name'],
              'provinceId': item['province_id'],
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar KTP'),
      ),
      body: Column(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Nama harus diisi';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _birthPlaceController,
                  decoration:
                      const InputDecoration(labelText: 'Tempat Tanggal Lahir'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Tempat tanggal lahir harus diisi';
                    }
                    return null;
                  },
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchProvinces(),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                    if (snapshot.hasData) {
                      return DropdownButtonFormField<String>(
                        value: _selectedProvince,
                        onChanged: (value) {
                          setState(() {
                            _selectedProvince = value;
                            _selectedProvinceId = snapshot.data!.firstWhere(
                              (province) => province['name'] == value,
                            )['id'];
                          });
                        },
                        items: snapshot.data!.map<DropdownMenuItem<String>>(
                            (Map<String, dynamic> value) {
                          return DropdownMenuItem<String>(
                            value: value['name'],
                            child: Text(value['name']),
                          );
                        }).toList(),
                        decoration:
                            const InputDecoration(labelText: 'Provinsi'),
                        validator: (value) {
                          if (value == null) {
                            return 'Provinsi harus dipilih';
                          }
                          return null;
                        },
                      );
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    // By default, show a loading spinner.
                    return const CircularProgressIndicator();
                  },
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchRegencies(),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                    if (snapshot.hasData) {
                      final regencies = snapshot.data!
                          .where((regency) =>
                              regency['provinceId'] == _selectedProvinceId)
                          .map<String>((regency) => regency['name'])
                          .toList();
                      return DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        onChanged: (value) {
                          setState(() {
                            _selectedDistrict = value!;
                          });
                        },
                        items: regencies
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration:
                            const InputDecoration(labelText: 'Kabupaten'),
                        validator: (value) {
                          if (value == null) {
                            return 'Kabupaten harus dipilih';
                          }
                          return null;
                        },
                      );
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    // By default, show a loading spinner.
                    return const CircularProgressIndicator();
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedOccupation,
                  onChanged: (value) {
                    setState(() {
                      _selectedOccupation = value!;
                    });
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'Pekerjaan 1',
                      child: Text('Pekerjaan 1'),
                    ),
                    DropdownMenuItem(
                      value: 'Pelajar',
                      child: Text('Pelajar'),
                    ),
                    DropdownMenuItem(
                      value: 'Mahasiswa',
                      child: Text('Mahasiswa'),
                    ),
                    DropdownMenuItem(
                      value: 'Karyawan Swasta',
                      child: Text('Karyawan Swasta'),
                    ),
                    DropdownMenuItem(
                      value: 'CPNS',
                      child: Text('CPNS'),
                    ),
                    // Add other occupations here
                  ],
                  decoration: const InputDecoration(labelText: 'Pekerjaan'),
                  validator: (value) {
                    if (value == null) {
                      return 'Pekerjaan harus dipilih';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _selectedEducation,
                  onChanged: (value) {
                    setState(() {
                      _selectedEducation = value!;
                    });
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'Pendidikan 1',
                      child: Text('Pendidikan 1'),
                    ),
                    DropdownMenuItem(
                      value: 'SD',
                      child: Text('SD'),
                    ),
                    DropdownMenuItem(
                      value: 'SMP',
                      child: Text('SMP'),
                    ),
                    DropdownMenuItem(
                      value: 'SMA',
                      child: Text('SMA'),
                    ),
                    DropdownMenuItem(
                      value: 'S1',
                      child: Text('S1'),
                    ),
                    DropdownMenuItem(
                      value: 'S2',
                      child: Text('S2'),
                    ),
                    DropdownMenuItem(
                      value: 'S3',
                      child: Text('S3'),
                    ),
                  ],
                  decoration: const InputDecoration(labelText: 'Pendidikan'),
                  validator: (value) {
                    if (value == null) {
                      return 'Pendidikan harus dipilih';
                    }
                    return null;
                  },
                ),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box('users').listenable(),
              builder: (context, Box box, _) {
                return ListView.builder(
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final user = box.getAt(index) as Map<String, dynamic>;
                    return ListTile(
                      leading: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _editUser(index);
                        },
                      ),
                      title: Text(user['name']),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Hapus Data'),
                                content: const Text(
                                    'Apakah Anda yakin ingin menghapus data ini?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _deleteUser(index);
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
