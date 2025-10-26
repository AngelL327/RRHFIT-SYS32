import 'package:flutter/material.dart';

class FirstSeccion extends StatelessWidget {
  const FirstSeccion({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: Center(
        child: SizedBox(
          width: 1200,
          height: 100,
          child: SizedBox(
            width: 800,
            height: 100,
            child: Row(
              children: [
                // Buscar
                Expanded(
                  flex: 4,
                  child: TextField(
                    style: const TextStyle(color: Colors.black),
                    cursorColor: Colors.black,
                    decoration: InputDecoration(
                      labelText: 'Buscar',
                      labelStyle: const TextStyle(color: Colors.black87),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.black54,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 30.0,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.black),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                // Filtrar
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 5.0, left: 15.0),
                    child: DropdownButtonFormField<String>(
                      items: ["Nombre", "Apellido"]
                          .map(
                            (tipo) => DropdownMenuItem(
                              value: tipo,
                              child: Text(tipo),
                            ),
                          )
                          .toList(),
                      onChanged: (String? valor) => {},
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        labelText: "Filtrar",
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
