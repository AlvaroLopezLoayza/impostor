/// Base failure class — all typed failures extend this
sealed class Failure {
  final String message;
  const Failure(this.message);
}

/// Remote data source failure (network, HTTP error)
class RemoteFailure extends Failure {
  const RemoteFailure([super.message = 'No se pudo conectar al servidor.']);
}

/// Local cache failure (no cached data)
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'No hay datos en caché disponibles.']);
}

/// JSON parsing failure
class ParseFailure extends Failure {
  const ParseFailure([super.message = 'Los datos recibidos son inválidos.']);
}

/// Game logic failure
class GameFailure extends Failure {
  const GameFailure([super.message = 'Error interno del juego.']);
}
