import 'package:flutter_test/flutter_test.dart';
import 'package:impostor/data/models/category_model.dart';

void main() {
  group('CategoriesResponse.fromJson', () {
    test('parses valid JSON correctly', () {
      final json = {
        'categorias': [
          {
            'nombre': 'Animales',
            'palabras': [
              {
                'base': 'perro',
                'sinonimos': ['can', 'mascota'],
              },
            ],
          },
        ],
      };

      final result = CategoriesResponse.fromJson(json);

      expect(result.categorias.length, 1);
      expect(result.categorias[0].nombre, 'Animales');
      expect(result.categorias[0].palabras[0].base, 'perro');
      expect(result.categorias[0].palabras[0].sinonimos, ['can', 'mascota']);
    });

    test('handles empty categorias list', () {
      final json = {'categorias': <dynamic>[]};
      final result = CategoriesResponse.fromJson(json);
      expect(result.categorias, isEmpty);
    });

    test('handles word with no synonyms (defaults to empty list)', () {
      final json = {
        'categorias': [
          {
            'nombre': 'Test',
            'palabras': [
              {'base': 'gato'},
            ],
          },
        ],
      };

      final result = CategoriesResponse.fromJson(json);
      expect(result.categorias[0].palabras[0].sinonimos, isEmpty);
    });

    test('handles multiple categories', () {
      final json = {
        'categorias': [
          {
            'nombre': 'Cat1',
            'palabras': [
              {'base': 'a', 'sinonimos': <String>[]},
            ],
          },
          {
            'nombre': 'Cat2',
            'palabras': [
              {'base': 'b', 'sinonimos': <String>[]},
            ],
          },
        ],
      };

      final result = CategoriesResponse.fromJson(json);
      expect(result.categorias.length, 2);
    });
  });

  group('CategoryModel.fromJson', () {
    test('throws on missing required field "nombre"', () {
      expect(
        () => CategoryModel.fromJson({
          'palabras': <dynamic>[],
        }),
        throwsA(anything),
      );
    });
  });
}
