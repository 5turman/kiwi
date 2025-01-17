/// Signature for a builder which creates an object of type [T].
typedef T Factory<T>(Container container);

/// A simple object container.
class Container {
  final _namedProviders = Map<String, Map<Type, _Provider<Object>>>();

  /// Whether ignoring assertion errors in the following cases:
  /// * if you register the same type under the same name a second time.
  /// * if you try to resolve or unregister a type that was not
  /// previously registered.
  ///
  /// Defaults to false.
  bool silent = false;

  /// Registers an instance into the container.
  ///
  /// If [name] is set, the instance will be registered under this name.
  /// To retrieve the same instance, the same name should be provided
  /// to [Container.resolve].
  void registerInstance<T>(T instance, {String name}) {
    assert(instance != null);
    final provider = _Provider<T>.singleton((container) => instance);
    _setProvider(name, provider);
  }

  /// Registers a factory into the container.
  ///
  /// If [name] is set, the factory will be registered under this name.
  /// To retrieve the same factory, the same name should be provided
  /// to [Container.resolve].
  void registerFactory<T>(Factory<T> factory, {String name}) {
    _setProvider(name, _Provider<T>.factory(factory));
  }

  /// Registers a factory that will be called only only when
  /// accessing it for the first time, into the container.
  ///
  /// If [name] is set, the factory will be registered under this name.
  /// To retrieve the same factory, the same name should be provided
  /// to [Container.resolve].
  void registerSingleton<T>(Factory<T> factory, {String name}) {
    _setProvider(name, _Provider<T>.singleton(factory));
  }

  /// Removes the entry previously registered for the type [T].
  ///
  /// If [name] is set, removes the one registered for that name.
  void unregister<T>([String name]) {
    assert(silent || (_namedProviders[name]?.containsKey(T) ?? false),
        _assertRegisterMessage<T>('not', name));
    _namedProviders[name]?.remove(T);
  }

  /// Attempts to resolve the type [T].
  ///
  /// If [name] is set, the instance or builder registered with this
  /// name will be get.
  ///
  /// See also:
  ///
  ///  * [Container.registerFactory] for register a builder function.
  ///  * [Container.registerInstance] for register an instance.
  T resolve<T>([String name]) {
    Map<Type, _Provider<Object>> providers = _namedProviders[name];

    assert(silent || (providers?.containsKey(T) ?? false),
        _assertRegisterMessage<T>('not', name));
    if (providers == null) {
      return null;
    }

    return providers[T]?.get(this);
  }

  T call<T>([String name]) => resolve<T>(name);

  /// Removes all instances and builders from the container.
  ///
  /// After this, the container is empty.
  void clear() {
    _namedProviders.clear();
  }

  void _setProvider<T>(String name, _Provider<T> provider) {
    assert(
      silent ||
          (!_namedProviders.containsKey(name) ||
              !_namedProviders[name].containsKey(T)),
      _assertRegisterMessage<T>('already', name),
    );

    _namedProviders.putIfAbsent(name, () => Map<Type, _Provider<Object>>())[T] =
        provider;
  }

  String _assertRegisterMessage<T>(String word, String name) {
    return 'The type $T was $word registered${name == null ? '' : ' for the name $name'}';
  }
}

abstract class _Provider<T> {
  _Provider();

  T get(Container container);

  factory _Provider.factory(Factory<T> instanceBuilder) =>
      _FactoryProvider(instanceBuilder);

  factory _Provider.singleton(Factory<T> instanceBuilder) =>
      _SingletonProvider(instanceBuilder);
}

class _FactoryProvider<T> extends _Provider<T> {
  _FactoryProvider(this.instanceBuilder) : assert(instanceBuilder != null);

  final Factory<T> instanceBuilder;

  @override
  T get(Container container) => instanceBuilder(container);
}

class _SingletonProvider<T> extends _Provider<T> {
  _SingletonProvider(this.instanceBuilder) : assert(instanceBuilder != null);

  Factory<T> instanceBuilder;
  T instance;

  @override
  T get(Container container) {
    if (instance == null && instanceBuilder != null) {
      instance = instanceBuilder(container);
      instanceBuilder = null;
    }
    return instance;
  }
}
