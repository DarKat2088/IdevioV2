import 'dart:convert';
import 'package:http/http.dart' as http;

class AiRenderService {
  final String baseUrl = "https://idevio-backend.onrender.com";

  Future<String> generateIdea(String category) async {
  final response = await http.post(
    Uri.parse("$baseUrl/generate"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"category": category}),
  );

  print("STATUS: ${response.statusCode}");
  print("BODY: ${response.body}");

  if (response.statusCode != 200) {
    throw Exception("Error ${response.statusCode}: ${response.body}");
  }

  final data = jsonDecode(response.body);

  if (data["error"] != null) {
    throw Exception(data["error"]);
  }

  final idea = data["idea"]?.toString().trim();

  if (idea == null || idea.isEmpty) {
    throw Exception("AI вернул пустой ответ");
  }
  return idea;
}
}