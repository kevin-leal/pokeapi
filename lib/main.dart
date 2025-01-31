import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokédex',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const PokemonListScreen(),
    );
  }
}

class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PokemonListScreenState createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  final String apiUrl = 'https://pokeapi.co/api/v2/pokemon?limit=100';
  List<dynamic> pokemonList = [];

  // Mapa de colores para tipos de Pokémon
  Map<String, Color> pokemonTypesColors = {
    'normal': Colors.grey,
    'fire': Colors.red,
    'water': Colors.blue,
    'electric': Colors.yellow,
    'grass': Colors.green,
    'ice': Colors.cyan,
    'fighting': Colors.brown,
    'poison': Colors.purple,
    'ground': Colors.orange,
    'flying': Colors.lightBlue,
    'psychic': Colors.pink,
    'bug': Colors.lightGreen,
    'rock': Colors.brown,
    'ghost': Colors.deepPurple,
    'dragon': Colors.deepOrange,
    'dark': Colors.black,
    'steel': Colors.blueGrey,
    'fairy': Colors.pinkAccent,
  };

  @override
  void initState() {
    super.initState();
    fetchPokemon();
  }

  Future<void> fetchPokemon() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      setState(() {
        pokemonList = json.decode(response.body)['results'];
      });
    }
  }

  String getPokemonImage(String url) {
    final id = url.split('/')[url.split('/').length - 2];
    return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';
  }

  Future<Map<String, dynamic>> fetchPokemonDetails(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar detalles del Pokémon');
    }
  }

  Color getPokemonTypeColor(List<dynamic> types) {
    String type = types.isNotEmpty ? types[0]['type']['name'] : 'normal';
    return pokemonTypesColors[type] ?? Colors.grey;
  }

  void showPokemonDetails(String name, String url) async {
    final details = await fetchPokemonDetails(url);
    final stats = details['stats'];

    final int hp = stats[0]['base_stat'];
    final int attack = stats[1]['base_stat'];
    final int defense = stats[2]['base_stat'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(name.toUpperCase()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(getPokemonImage(url)),
              Text("Vida: $hp", style: TextStyle(fontSize: 16)),
              Text("Ataque: $attack", style: TextStyle(fontSize: 16)),
              Text("Defensa: $defense", style: TextStyle(fontSize: 16)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
      ),
      body: pokemonList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: pokemonList.length,
        itemBuilder: (context, index) {
          final pokemon = pokemonList[index];
          return FutureBuilder<Map<String, dynamic>>(
            future: fetchPokemonDetails(pokemon['url']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(
                  leading: CircularProgressIndicator(),
                  title: Text('Cargando...'),
                );
              }

              if (snapshot.hasError) {
                return ListTile(
                  title: Text('Error cargando detalles'),
                );
              }

              final details = snapshot.data!;
              final types = details['types'] ?? [];
              final typeColor = getPokemonTypeColor(types);

              return ListTile(
                leading: Image.network(getPokemonImage(pokemon['url'])),
                title: Text(pokemon['name'].toString().toUpperCase()),
                tileColor: typeColor.withOpacity(0.2),
                onTap: () =>
                    showPokemonDetails(pokemon['name'], pokemon['url']),
              );
            },
          );
        },
      ),
    );
  }
}
