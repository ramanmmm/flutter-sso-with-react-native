import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  // Controllers for Username and Password
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Function to make API Call
  Future<void> makeApiCall(BuildContext context) async {
    final url = Uri.parse(
        "https://keycloak-dqs.mogiio.com/realms/sso-demo/protocol/openid-connect/token");

    try {
      final response = await http.post(
        url,
        body: {
          "username": usernameController.text, // Get username from TextField
          "password": passwordController.text, // Get password from TextField
          "client_id": "batman-portal",
          "client_secret": "Cfc8R9A8Ee2r3JPW313XDFfseuNBuqtK",
          "grant_type": "password",
        },
      );

      // Logging the response body
      debugPrint("Response Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // Parse JSON
        final jsonData = jsonDecode(response.body);

        // Log the parsed JSON
        debugPrint("Parsed JSON Data: $jsonData");

        // Store JSON in Shared Preferences
        await saveTokenToSharedPreferences(jsonData);

        // Display Success Message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Successful!')),
        );
      } else {
        // Display Error Message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint("Error during API call: $e");

      // Show a failure message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred during login.')),
      );
    }
  }

  // Function to Save Data to Shared Preferences
  // Function to Save the Access Token to Shared Preferences
  Future<void> saveTokenToSharedPreferences(Map<String, dynamic> jsonData) async {
    final prefs = await SharedPreferences.getInstance();


    // Extract the access token from the response
    final accessToken = jsonData['access_token'];
    final refreshToken = jsonData['refresh_token'];
    // Log the token being stored
    debugPrint("Storing Access Token: $refreshToken");

    debugPrint("my refresh Token is : $refreshToken");
    // Save the token in SharedPreferences
    await prefs.setString('refresh_token', refreshToken);
  }

  // Function to Retrieve Data from Shared Preferences
  Future<Map<String, dynamic>?> getFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Get the JSON string
    final jsonString = prefs.getString('api_response');

    if (jsonString != null) {
      // Log the retrieved JSON string
      debugPrint("Retrieved JSON String: $jsonString");

      // Convert the string back to a JSON object
      return jsonDecode(jsonString);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Username TextField
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Password TextField
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Login Button
            ElevatedButton(
              onPressed: () {
                makeApiCall(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Login',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}