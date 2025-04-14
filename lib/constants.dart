Function() constant<T>(T x) {
  return () {
    return x;
  };
}