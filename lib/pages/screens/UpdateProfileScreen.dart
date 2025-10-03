import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:Frutia/auth/auth_service.dart';
// No necesitamos importar ProfilePage si solo vamos a regresar a la pantalla anterior

class UpdateProfileScreen extends StatefulWidget {
  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();

  File? _image;
  String? _profileImageUrl; // URL de la imagen de perfil
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final profileData = await _authService.getProfile();
      setState(() {
        _nameController.text = profileData['name'] ?? '';
        _phoneController.text = profileData['phone'] ?? '';
        _postalCodeController.text = profileData['codigo_postal'] ?? '';
        _positionController.text = profileData['posicion'] ?? '';

        // Construir la URL completa de la imagen
        if (profileData['profile_image'] != null &&
            profileData['profile_image'].isNotEmpty) {
          _profileImageUrl =
              'https://proyect.aftconta.mx/storage/${profileData['profile_image']}';
        } else {
          _profileImageUrl = null; // Si no hay imagen, asignar null
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los datos del perfil: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

/*
  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final phone = _phoneController.text;
      final postalCode = _postalCodeController.text;
      final posicion = _positionController.text;

      final success = await _authService.updateProfile(
        name: name,
        phone: phone,
        postalCode: postalCode,
        posicion: posicion,
        profileImage: _image,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        // Regresar a la pantalla anterior (con BottomNavigationBar)
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el perfil')),
        );
      }
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          'Actualizar Perfil',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  child: ClipOval(
                    child: _image != null
                        ? Image.file(
                            _image!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : (_profileImageUrl != null &&
                                _profileImageUrl!.isNotEmpty)
                            ? Image.network(
                                _profileImageUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              )
                            : Icon(Icons.camera_alt,
                                size: 50, color: Colors.grey[700]),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: Colors.black), // Texto en negro
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: TextStyle(color: Colors.black), // Label en negro
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.black), // Borde en negro
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors
                            .black), // Borde en negro cuando está enfocado
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su nombre';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                style: TextStyle(color: Colors.black), // Texto en negro
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  labelStyle: TextStyle(color: Colors.black), // Label en negro
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.black), // Borde en negro
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors
                            .black), // Borde en negro cuando está enfocado
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su teléfono';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _postalCodeController,
                style: TextStyle(color: Colors.black), // Texto en negro
                decoration: InputDecoration(
                  labelText: 'Código Postal',
                  labelStyle: TextStyle(color: Colors.black), // Label en negro
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.black), // Borde en negro
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors
                            .black), // Borde en negro cuando está enfocado
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su código postal';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _positionController,
                style: TextStyle(color: Colors.black), // Texto en negro
                decoration: InputDecoration(
                  labelText: 'Posición',
                  labelStyle: TextStyle(color: Colors.black), // Label en negro
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.black), // Borde en negro
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors
                            .black), // Borde en negro cuando está enfocado
                  ),
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: ElevatedButton(
                  onPressed: () => {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.green, // Cambia esto al color que desees
                    foregroundColor: Colors.white, // Color del texto
                  ),
                  child: Text('Actualizar Perfil'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
