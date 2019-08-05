/// An annotation that marks the constructor for generating a factory.
class Inject {
  const Inject();
}

const inject = Inject();

/// An annotation to specify the name of dependency in the constructor.
class Named {
  const Named(this.name) : assert(name != null);

  final String name;
}
